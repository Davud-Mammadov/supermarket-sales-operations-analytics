"""Load the workbooks into SQLite and reconcile all seven final tables."""
from collections import Counter
from pathlib import Path
import sqlite3
import xml.etree.ElementTree as ET
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent
TEXT = {"StoreName", "City", "StoreType", "ProductName", "Category",
        "Segment", "CustomerName", "MonthName", "Weekday"}
REAL = {"BasePrice", "UnitPrice", "UnitCost", "DiscountPct", "AvgQueueMinutes"}


def quote(name):
    return '"' + name.replace('"', '""') + '"'


def load_book(db, filename, prefix):
    with ZipFile(ROOT / "data" / filename) as book:
        strings = ["".join(x.itertext()) for x in ET.fromstring(book.read("xl/sharedStrings.xml"))]
        sheets = ET.fromstring(book.read("xl/workbook.xml")).find("{*}sheets")

        def value(cell):
            kind = cell.get("t")
            content = cell.findtext("{*}v")
            if kind == "s":
                return strings[int(content)]
            if kind == "inlineStr":
                return "".join(cell.find("{*}is").itertext())
            return content

        for i, sheet in enumerate(sheets, 1):
            name = sheet.get("name")
            with book.open(f"xl/worksheets/sheet{i}.xml") as stream:
                rows = (e for _, e in ET.iterparse(stream) if e.tag.endswith("}row"))
                headers = [value(cell) for cell in next(rows)]
                table = quote(prefix + name)
                db.execute(f"CREATE TABLE {table} (" + ", ".join(quote(h) + " TEXT" for h in headers) + ")")

                def records():
                    for row in rows:
                        values = tuple(value(cell) for cell in row)
                        if len(values) != len(headers):
                            raise ValueError(f"{name} row {row.get('r')} has missing cells")
                        yield values
                        row.clear()

                db.executemany(f"INSERT INTO {table} VALUES ({','.join('?' for _ in headers)})", records())
                yield name, headers


def clean_reference(row, headers):
    return tuple(v if h in TEXT or v is None else float(v) if h in REAL else int(v)
                 for h, v in zip(headers, row))


def main():
    with sqlite3.connect(":memory:") as db:
        tables = dict(load_book(db, "Supermarket_Sales_RAW.xlsx", "stg_"))
        for name in ("01_profile.sql", "02_publish.sql", "03_validate.sql"):
            for query in (ROOT / "sql" / name).read_text(encoding="utf-8").split(";"):
                if query.strip():
                    cursor = db.execute(query)
                    if cursor.description:
                        print(cursor.fetchall())

        for table, headers in load_book(db, "Supermarket_Sales_Clean.xlsx", "reference_"):
            assert tables[table] == headers
            expected = Counter(clean_reference(row, headers) for row in db.execute("SELECT * FROM " + quote("reference_" + table)))
            actual = Counter(db.execute("SELECT * FROM " + quote(table)))
            if expected != actual:
                raise RuntimeError(f"{table} failed reconciliation")
            print(f"{table}: {sum(actual.values()):,} rows match")

        for query in (ROOT / "sql" / "04_analysis.sql").read_text(encoding="utf-8").split(";"):
            if query.strip():
                cursor = db.execute(query)
                if cursor.description is None:
                    continue
                print([field[0] for field in cursor.description])
                for row in cursor:
                    print(row)


if __name__ == "__main__":
    main()

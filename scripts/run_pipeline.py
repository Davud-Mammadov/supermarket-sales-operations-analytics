"""Load the workbooks into SQL Server and reconcile all seven final tables."""
from collections import Counter
from itertools import islice
import os
from pathlib import Path
import xml.etree.ElementTree as ET
from zipfile import ZipFile

import pyodbc

ROOT = Path(__file__).resolve().parents[1]
TEXT = {"StoreName", "City", "StoreType", "ProductName", "Category",
        "Segment", "CustomerName", "MonthName", "Weekday"}
REAL = {"BasePrice", "UnitPrice", "UnitCost", "DiscountPct", "AvgQueueMinutes"}


def quote(name):
    return "[" + name.replace("]", "]]") + "]"


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
                table = "dbo." + quote(prefix + name)
                columns = ", ".join(quote(h) + " nvarchar(255)" for h in headers)
                db.execute(f"CREATE TABLE {table} ({columns})")

                def records():
                    for row in rows:
                        values = tuple(value(cell) for cell in row)
                        if len(values) != len(headers):
                            raise ValueError(f"{name} row {row.get('r')} has missing cells")
                        yield values
                        row.clear()

                cursor = db.cursor()
                cursor.fast_executemany = True
                statement = f"INSERT INTO {table} VALUES ({','.join('?' for _ in headers)})"
                source = records()
                while batch := list(islice(source, 1000)):
                    cursor.executemany(statement, batch)
                cursor.close()
                yield name, headers


def clean_reference(row, headers):
    return tuple(v if h in TEXT or v is None else float(v) if h in REAL else int(v)
                 for h, v in zip(headers, row))


def run_sql(db, filename):
    cursor = db.execute((ROOT / "sql" / filename).read_text(encoding="utf-8"))
    while True:
        if cursor.description:
            print([column[0] for column in cursor.description])
            for row in cursor:
                print(tuple(row))
        if not cursor.nextset():
            break
    cursor.close()


def main():
    connection_string = os.environ.get("SUPERMARKET_SQLSERVER")
    if not connection_string:
        raise SystemExit("Set SUPERMARKET_SQLSERVER to an ODBC connection string for an empty project database.")

    with pyodbc.connect(connection_string) as db:
        db.execute("SET XACT_ABORT ON; SET NOCOUNT ON;")
        tables = dict(load_book(db, "Supermarket_Sales_RAW.xlsx", "stg_"))
        for name in ("01_profile.sql", "02_publish.sql", "03_validate.sql"):
            run_sql(db, name)

        for table, headers in load_book(db, "Supermarket_Sales_Clean.xlsx", "reference_"):
            assert tables[table] == headers
            expected = Counter(clean_reference(row, headers) for row in db.execute("SELECT * FROM dbo." + quote("reference_" + table)))
            actual = Counter(tuple(row) for row in db.execute("SELECT * FROM dbo." + quote(table)))
            if expected != actual:
                raise RuntimeError(f"{table} failed reconciliation")
            print(f"{table}: {sum(actual.values()):,} rows match")

        run_sql(db, "04_analysis.sql")


if __name__ == "__main__":
    main()

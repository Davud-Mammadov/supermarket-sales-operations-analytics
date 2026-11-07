"""Create a RAW copy while preserving workbook layout and unchanged sheets."""
from pathlib import Path
import re
from xml.sax.saxutils import escape
import xml.etree.ElementTree as ET
from zipfile import ZIP_DEFLATED, ZipFile

DATA = Path(__file__).resolve().parent / "data"

with ZipFile(DATA / "Supermarket_Sales_Clean.xlsx") as source:
    strings = ["".join(x.itertext()) for x in ET.fromstring(source.read("xl/sharedStrings.xml"))]

    def as_text(xml, column, row, transform, shared=False):
        pattern = rf'<c r="{column}{row}"[^>]*><v>([^<]+)</v></c>'

        def replace(match):
            value = strings[int(match[1])] if shared else match[1]
            value = escape(transform(value))
            return f'<c r="{column}{row}" t="inlineStr"><is><t xml:space="preserve">{value}</t></is></c>'

        result, count = re.subn(pattern, replace, xml)
        assert count == 1, (column, row)
        return result

    product_path = "xl/worksheets/sheet3.xml"
    products = source.read(product_path).decode()
    duplicate = re.search(r'<row r="2".*?</row>', products)[0]
    duplicate = re.sub(r'r="([A-E]?)2"', r'r="\g<1>17"', duplicate)
    products = products.replace("</sheetData>", duplicate + "</sheetData>", 1)
    products = products.replace('ref="A1:E16"', 'ref="A1:E17"', 1)
    for row in (3, 6, 9, 12):
        products = as_text(products, "B", row, lambda value: "  " + value + " ", shared=True)

    sales_path = "xl/worksheets/sheet5.xml"
    sales = source.read(sales_path).decode()
    for row in range(1000, 244234, 7000):
        sales = as_text(sales, "G", row, lambda value: " " + value + " ")
        sales = as_text(sales, "J", row, lambda value: value.replace(".", ","))

    modified = {product_path: products, sales_path: sales}
    with ZipFile(DATA / "Supermarket_Sales_RAW.xlsx", "w", ZIP_DEFLATED) as output:
        for name in source.namelist():
            output.writestr(name, modified[name] if name in modified else source.read(name))

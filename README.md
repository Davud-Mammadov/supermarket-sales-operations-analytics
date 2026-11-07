# Supermarket Sales & Operations Analytics

![Excel](https://img.shields.io/badge/Data-Excel-217346) ![Microsoft SQL Server](https://img.shields.io/badge/Database-Microsoft_SQL_Server-BA2027) ![Power BI](https://img.shields.io/badge/Reporting-Power_BI-F2C811)

[Data pipeline](#data-preparation-and-sql) · [SQL walkthrough](#sql-walkthrough) · [Findings](#what-the-data-shows) · [Power BI screenshots](#power-bi-report) · [Reproduce the analysis](#reproduce-the-analysis)

This project brings sales, customer behavior, inventory and store operations into one Power BI report. It helps answer which products earn the most profit, how results change by month, and when queue times warrant a closer look at staffing.

[Download the Power BI report](power-bi/Supermarket_Sales_Analysis.pbix) · [Clean workbook](data/Supermarket_Sales_Clean.xlsx) · [RAW workbook](data/Supermarket_Sales_RAW.xlsx)

## Data preparation and SQL

[![Data pipeline from RAW Excel through SQL Server staging, cleaning and reconciliation to SQL analysis. Clean Excel also feeds Power BI.](screenshots/data-pipeline-overview.svg)](screenshots/data-pipeline-overview.svg)

The RAW workbook is derived from the supplied clean workbook. We used it to build and verify an end-to-end cleaning workflow. The input contains sales lines, inventory records and hourly operations observations, supported by date, store, product and customer dimensions.

## SQL walkthrough

![Three stages of the SQL Server workflow: staging as text, cleaning and typing, and reconciliation against Clean Excel](screenshots/sql-workflow.svg)

| Table group | Grain | Final rows |
| --- | --- | ---: |
| Date, store, product, customer | One row per dimension key | 1,096 / 8 / 15 / 2,500 |
| Sales | One line within an order | 244,233 |
| Inventory | Stock observation by date, store and product | 4,320 |
| Operations | Hourly observation by date and store | 43,800 |

1. **Load into staging.** We imported all seven sheets into SQL Server `dbo.stg_*` tables as Unicode text. That preserved spaces, decimal commas and duplicate rows for profiling before converting the data.
2. **Profile and clean.** [Profiling SQL](sql/01_profile.sql) finds the repeated product key and the fields with formatting defects. [Publishing SQL](sql/02_publish.sql) trims labels, normalizes decimal commas, casts quantities and costs, and removes the exact product replay. It preserves individual sales lines because an order can contain several lines. Unique dimension indexes prevent a duplicated lookup from multiplying sales in joins.
3. **Validate and reconcile.** [Validation SQL](sql/03_validate.sql) checks for missing dimension keys and invalid sales, stock or operations values. We also compared the final records, including repeated rows, with the supplied clean workbook.
4. **Analyze.** [Analytical SQL](sql/04_analysis.sql) computes net sales, cost, profit and margin, compares profit across consecutive calendar months, ranks products by gross profit, and compares staffing and queues by hour.

🔍 The profiling query finds product keys that appear more than once.

```sql
SELECT ProductID, COUNT(*) AS occurrences
FROM dbo.stg_DimProduct
GROUP BY ProductID
HAVING COUNT(*) > 1;
```

This returned product key `1` twice. The publish step collapses identical normalized product rows, then a unique index rejects any remaining duplicate key. If rows share a key but disagree on product attributes, that index surfaces the conflict. The sales table keeps its line grain throughout the load.

| Check | What it protects |
| --- | --- |
| Dimension keys exist for sales, inventory and operations | Missing lookup rows cannot silently disappear from analytical joins. |
| Quantities, prices, discounts, stock and queue values pass range checks | Invalid inputs cannot silently reach the verified output. |
| Full rows and multiplicities match the clean workbook | A lost row or a changed value is detected even when a simple count still matches. |

Profiling found one duplicate product row, four padded product names, 35 padded quantities and 35 costs stored with a decimal comma. The reconciliation matched all seven tables against the clean workbook.

## What the data shows

These benchmarks come from the full dataset after staging and validation in Microsoft SQL Server. Clear the report filters before comparing totals.

| KPI | Full dataset |
| --- | ---: |
| Sales lines | 244,233 |
| Distinct orders | 97,529 |
| Net sales | 8,849,924.28 |
| Product cost | 7,996,112.74 |
| Gross profit | 853,811.54 |
| Gross margin | 9.65% |

| Rank | Product | Gross profit |
| ---: | --- | ---: |
| 1 | Sobsan Detergent | 109,463.10 |
| 2 | Ferrero Rocher | 90,721.77 |
| 3 | Pasha Coffee Gold | 87,308.30 |
| 4 | Sunflower Oil | 85,954.24 |
| 5 | Organic Honey | 79,168.15 |

Sobsan Detergent generated **418.93K in net sales** at a **26.13% gross margin**, leading the assortment in gross profit. Its margin was 16.48 percentage points above the overall margin.

| Hour | Average queue (min) | Average staff |
| --- | ---: | ---: |
| 17:00 | 5.68 | 5.51 |
| 18:00 | 35.28 | 3.00 |
| 19:00 | 35.02 | 3.01 |
| 20:00 | 35.45 | 2.98 |
| 21:00 | 5.71 | 5.51 |

The evening queue increase coincides with lower staffing. The 18:00–20:00 window is a starting point for comparing staffing and customer traffic by store and day before changing schedules.

Net sales equal quantity × transaction unit price × (1 − discount percentage ÷ 100). Gross profit subtracts quantity × unit cost from net sales. Gross margin divides gross profit by net sales.

## Power BI report

Open the PBIX in Power BI Desktop and explore the saved data. To refresh in a different environment, inspect the Power Query source steps and update the workbook connection to your local copy.

### Executive Summary

The unfiltered view shows approximately **8.85M in sales, 853.81K in profit and a 9.65% margin**.

![Executive Summary without a month selected](screenshots/executive.png)

Selecting **September** changes the trend to a single-month comparison and updates the KPI cards. The report shows **740.38K in sales**, **72.16K in profit** and a **1.68% decline in profit** versus the prior month comparison.

![Executive Summary with September selected](screenshots/executive-september.png)

### Product Analysis

The scatter plot compares sales and profit by product. Sobsan Detergent appears as the top product by profit in the report.

![Product Analysis](screenshots/products.png)

### Customer Analysis

Compare spending segments, discount bands, basket sizes and shopping hours.

![Customer Analysis](screenshots/customers.png)

### Inventory & Operations Analysis

Compare product stock with sales and review queues alongside staffing by hour. The visible evening queue increase identifies a period to investigate.

![Inventory and Operations Analysis](screenshots/operations.png)

### Product tooltip and drill-through

Hover over a product point to see its key metrics. Drill through from the point to see sales, profit and units sold by month.

![Product tooltip for Sobsan Detergent](screenshots/tooltip.png)

![Product drill-through for Sobsan Detergent](screenshots/drill-through.png)

## Reproduce the analysis

The screenshots and results above are ready to review on GitHub. If you want to verify the SQL results yourself, use a fresh Microsoft SQL Server database and SQL Server Management Studio (SSMS).

1. Start with the [RAW Excel workbook](data/Supermarket_Sales_RAW.xlsx). On a copy, format the date columns in `DimDate`, `FactInventory` and `FactOperations` as numbers with zero decimal places before exporting. The T-SQL expects Excel date serials in those columns. Export each sheet to its own UTF-8 CSV, retaining headers, quoting and the original text values.
2. In SSMS, use the flat-file import wizard to load the seven CSVs into the `dbo` schema. Prefix each original sheet name with `stg_`, for example `dbo.stg_FactSales`. Set each staging column to `nvarchar(255)` to preserve formatting differences before profiling.
3. Run [01 · Profile](sql/01_profile.sql), [02 · Publish](sql/02_publish.sql), [03 · Validate](sql/03_validate.sql) and [04 · Analyze](sql/04_analysis.sql) in order in that database. Compare the resulting row counts and KPIs with the benchmarks above. Use the [clean Excel workbook](data/Supermarket_Sales_Clean.xlsx) as the reconciliation reference.
4. To explore Power BI, open the [PBIX](power-bi/Supermarket_Sales_Analysis.pbix) with its saved data. For a refresh, update the Power Query workbook source to your local copy of the clean Excel file.

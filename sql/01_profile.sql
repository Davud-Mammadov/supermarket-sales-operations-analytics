SELECT ProductID, COUNT(*) AS occurrences
FROM dbo.stg_DimProduct
GROUP BY ProductID
HAVING COUNT(*) > 1;

SELECT SUM(CASE WHEN DATALENGTH(ProductName) <> DATALENGTH(TRIM(ProductName))
                THEN 1 ELSE 0 END) AS padded_names
FROM dbo.stg_DimProduct;

SELECT SUM(CASE WHEN DATALENGTH(Quantity) <> DATALENGTH(TRIM(Quantity))
                THEN 1 ELSE 0 END) AS padded_quantities,
       SUM(CASE WHEN CHARINDEX(',', UnitCost) > 0 THEN 1 ELSE 0 END) AS comma_decimal_costs
FROM dbo.stg_FactSales;

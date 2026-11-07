SELECT ProductID, COUNT(*) AS occurrences
FROM stg_DimProduct GROUP BY ProductID HAVING COUNT(*) > 1;

SELECT SUM(ProductName <> TRIM(ProductName)) AS padded_names FROM stg_DimProduct;

SELECT SUM(Quantity <> TRIM(Quantity)) AS padded_quantities,
       SUM(INSTR(UnitCost, ',') > 0) AS comma_decimal_costs
FROM stg_FactSales;

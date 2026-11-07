SELECT CAST(DateKey AS INTEGER) AS DateKey,
       CAST(Date AS INTEGER) AS Date,
       CAST(Year AS INTEGER) AS Year,
       CAST(Quarter AS INTEGER) AS Quarter,
       CAST(MonthNo AS INTEGER) AS MonthNo,
       TRIM(MonthName) AS MonthName,
       CAST(Day AS INTEGER) AS Day,
       TRIM(Weekday) AS Weekday,
       CAST(IsWeekend AS INTEGER) AS IsWeekend
INTO dbo.DimDate
FROM dbo.stg_DimDate;

SELECT CAST(StoreID AS INTEGER) AS StoreID,
       TRIM(StoreName) AS StoreName,
       TRIM(City) AS City,
       TRIM(StoreType) AS StoreType
INTO dbo.DimStore
FROM dbo.stg_DimStore;

SELECT DISTINCT CAST(ProductID AS INTEGER) AS ProductID,
       TRIM(ProductName) AS ProductName,
       TRIM(Category) AS Category,
       TRIM(Segment) AS Segment,
       CAST(REPLACE(TRIM(BasePrice), ',', '.') AS FLOAT(53)) AS BasePrice
INTO dbo.DimProduct
FROM dbo.stg_DimProduct;

SELECT CAST(CustomerID AS INTEGER) AS CustomerID,
       TRIM(CustomerName) AS CustomerName,
       TRIM(Segment) AS Segment,
       CAST(RegistrationYear AS INTEGER) AS RegistrationYear
INTO dbo.DimCustomer
FROM dbo.stg_DimCustomer;

SELECT CAST(OrderID AS INTEGER) AS OrderID,
       CAST(DateKey AS INTEGER) AS DateKey,
       CAST(StoreID AS INTEGER) AS StoreID,
       CAST(CustomerID AS INTEGER) AS CustomerID,
       CAST(ProductID AS INTEGER) AS ProductID,
       CAST(OrderHour AS INTEGER) AS OrderHour,
       CAST(Quantity AS INTEGER) AS Quantity,
       CAST(REPLACE(TRIM(UnitPrice), ',', '.') AS FLOAT(53)) AS UnitPrice,
       CAST(REPLACE(TRIM(DiscountPct), ',', '.') AS FLOAT(53)) AS DiscountPct,
       CAST(REPLACE(TRIM(UnitCost), ',', '.') AS FLOAT(53)) AS UnitCost
INTO dbo.FactSales
FROM dbo.stg_FactSales;

SELECT CAST(InventoryDate AS INTEGER) AS InventoryDate,
       CAST(StoreID AS INTEGER) AS StoreID,
       CAST(ProductID AS INTEGER) AS ProductID,
       CAST(StockQty AS INTEGER) AS StockQty
INTO dbo.FactInventory
FROM dbo.stg_FactInventory;

SELECT CAST(Date AS INTEGER) AS Date,
       CAST(StoreID AS INTEGER) AS StoreID,
       CAST(Hour AS INTEGER) AS Hour,
       CAST(CustomersServed AS INTEGER) AS CustomersServed,
       CAST(StaffCount AS INTEGER) AS StaffCount,
       CAST(REPLACE(TRIM(AvgQueueMinutes), ',', '.') AS FLOAT(53)) AS AvgQueueMinutes
INTO dbo.FactOperations
FROM dbo.stg_FactOperations;

CREATE UNIQUE INDEX product_key ON dbo.DimProduct(ProductID);
CREATE UNIQUE INDEX date_key ON dbo.DimDate(DateKey);
CREATE UNIQUE INDEX store_key ON dbo.DimStore(StoreID);
CREATE UNIQUE INDEX customer_key ON dbo.DimCustomer(CustomerID);

CREATE TABLE DimDate AS
SELECT CAST(DateKey AS INTEGER) AS DateKey,
       CAST(Date AS INTEGER) AS Date,
       CAST(Year AS INTEGER) AS Year,
       CAST(Quarter AS INTEGER) AS Quarter,
       CAST(MonthNo AS INTEGER) AS MonthNo,
       TRIM(MonthName) AS MonthName,
       CAST(Day AS INTEGER) AS Day,
       TRIM(Weekday) AS Weekday,
       CAST(IsWeekend AS INTEGER) AS IsWeekend
FROM stg_DimDate;

CREATE TABLE DimStore AS
SELECT CAST(StoreID AS INTEGER) AS StoreID,
       TRIM(StoreName) AS StoreName,
       TRIM(City) AS City,
       TRIM(StoreType) AS StoreType
FROM stg_DimStore;

CREATE TABLE DimProduct AS
SELECT DISTINCT CAST(ProductID AS INTEGER) AS ProductID,
       TRIM(ProductName) AS ProductName,
       TRIM(Category) AS Category,
       TRIM(Segment) AS Segment,
       CAST(REPLACE(TRIM(BasePrice), ',', '.') AS REAL) AS BasePrice
FROM stg_DimProduct;

CREATE TABLE DimCustomer AS
SELECT CAST(CustomerID AS INTEGER) AS CustomerID,
       TRIM(CustomerName) AS CustomerName,
       TRIM(Segment) AS Segment,
       CAST(RegistrationYear AS INTEGER) AS RegistrationYear
FROM stg_DimCustomer;

CREATE TABLE FactSales AS
SELECT CAST(OrderID AS INTEGER) AS OrderID,
       CAST(DateKey AS INTEGER) AS DateKey,
       CAST(StoreID AS INTEGER) AS StoreID,
       CAST(CustomerID AS INTEGER) AS CustomerID,
       CAST(ProductID AS INTEGER) AS ProductID,
       CAST(OrderHour AS INTEGER) AS OrderHour,
       CAST(Quantity AS INTEGER) AS Quantity,
       CAST(REPLACE(TRIM(UnitPrice), ',', '.') AS REAL) AS UnitPrice,
       CAST(REPLACE(TRIM(DiscountPct), ',', '.') AS REAL) AS DiscountPct,
       CAST(REPLACE(TRIM(UnitCost), ',', '.') AS REAL) AS UnitCost
FROM stg_FactSales;

CREATE TABLE FactInventory AS
SELECT CAST(InventoryDate AS INTEGER) AS InventoryDate,
       CAST(StoreID AS INTEGER) AS StoreID,
       CAST(ProductID AS INTEGER) AS ProductID,
       CAST(StockQty AS INTEGER) AS StockQty
FROM stg_FactInventory;

CREATE TABLE FactOperations AS
SELECT CAST(Date AS INTEGER) AS Date,
       CAST(StoreID AS INTEGER) AS StoreID,
       CAST(Hour AS INTEGER) AS Hour,
       CAST(CustomersServed AS INTEGER) AS CustomersServed,
       CAST(StaffCount AS INTEGER) AS StaffCount,
       CAST(REPLACE(TRIM(AvgQueueMinutes), ',', '.') AS REAL) AS AvgQueueMinutes
FROM stg_FactOperations;

CREATE UNIQUE INDEX product_key ON DimProduct(ProductID);
CREATE UNIQUE INDEX date_key ON DimDate(DateKey);
CREATE UNIQUE INDEX store_key ON DimStore(StoreID);
CREATE UNIQUE INDEX customer_key ON DimCustomer(CustomerID);

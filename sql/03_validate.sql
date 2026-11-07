IF EXISTS (
    SELECT 1 FROM dbo.FactSales s
    LEFT JOIN dbo.DimProduct p ON p.ProductID = s.ProductID
    LEFT JOIN dbo.DimDate d ON d.DateKey = s.DateKey
    LEFT JOIN dbo.DimStore st ON st.StoreID = s.StoreID
    LEFT JOIN dbo.DimCustomer c ON c.CustomerID = s.CustomerID
    WHERE p.ProductID IS NULL OR d.DateKey IS NULL OR st.StoreID IS NULL
       OR c.CustomerID IS NULL OR s.Quantity <= 0 OR s.UnitPrice < 0
       OR s.UnitCost < 0 OR s.DiscountPct NOT BETWEEN 0 AND 100
)
    THROW 50001, 'Sales validation failed.', 1;

IF EXISTS (
    SELECT 1 FROM dbo.FactInventory i
    LEFT JOIN dbo.DimProduct p ON p.ProductID = i.ProductID
    LEFT JOIN dbo.DimStore st ON st.StoreID = i.StoreID
    WHERE p.ProductID IS NULL OR st.StoreID IS NULL OR i.StockQty < 0
)
    THROW 50002, 'Inventory validation failed.', 1;

IF EXISTS (
    SELECT 1 FROM dbo.FactOperations o
    LEFT JOIN dbo.DimStore st ON st.StoreID = o.StoreID
    WHERE st.StoreID IS NULL OR o.StaffCount < 0 OR o.AvgQueueMinutes < 0
)
    THROW 50003, 'Operations validation failed.', 1;

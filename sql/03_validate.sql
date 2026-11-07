CREATE TEMP TABLE validation_gate (violations INTEGER CHECK (violations = 0));

INSERT INTO validation_gate
SELECT COUNT(*)
FROM FactSales s
LEFT JOIN DimProduct p USING (ProductID)
LEFT JOIN DimDate d USING (DateKey)
LEFT JOIN DimStore st USING (StoreID)
LEFT JOIN DimCustomer c USING (CustomerID)
WHERE p.ProductID IS NULL OR d.DateKey IS NULL OR st.StoreID IS NULL
   OR c.CustomerID IS NULL OR s.Quantity <= 0 OR s.UnitPrice < 0 OR s.UnitCost < 0
   OR s.DiscountPct NOT BETWEEN 0 AND 100;

INSERT INTO validation_gate
SELECT COUNT(*) FROM FactInventory i
LEFT JOIN DimProduct p USING (ProductID)
LEFT JOIN DimStore st USING (StoreID)
WHERE p.ProductID IS NULL OR st.StoreID IS NULL OR i.StockQty < 0;

INSERT INTO validation_gate
SELECT COUNT(*) FROM FactOperations o LEFT JOIN DimStore st USING (StoreID)
WHERE st.StoreID IS NULL OR o.StaffCount < 0 OR o.AvgQueueMinutes < 0;

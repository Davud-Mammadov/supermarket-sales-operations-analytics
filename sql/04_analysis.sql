SELECT *, Quantity * UnitPrice * (1 - DiscountPct / 100.0) AS net_sales,
          Quantity * UnitCost AS cost
INTO #sales_metrics
FROM dbo.FactSales;

SELECT COUNT(*) AS lines, COUNT(DISTINCT OrderID) AS orders,
       ROUND(SUM(net_sales), 2) AS sales, ROUND(SUM(cost), 2) AS cost,
       ROUND(SUM(net_sales - cost), 2) AS profit,
       ROUND(100 * SUM(net_sales - cost) / NULLIF(SUM(net_sales), 0), 2) AS margin_pct
FROM #sales_metrics;

WITH month_totals AS (
    SELECT d.Year, d.MonthNo, SUM(net_sales - cost) AS profit
    FROM #sales_metrics s JOIN dbo.DimDate d ON d.DateKey = s.DateKey
    GROUP BY d.Year, d.MonthNo
), comparison AS (
    SELECT *, LAG(profit) OVER (ORDER BY Year, MonthNo) AS prior_profit
    FROM month_totals
)
SELECT Year, MonthNo, ROUND(profit, 2) AS profit,
       ROUND(100 * (profit - prior_profit) / NULLIF(prior_profit, 0), 2) AS mom_pct
FROM comparison ORDER BY Year, MonthNo;

SELECT TOP (5) p.ProductName, ROUND(SUM(s.net_sales - s.cost), 2) AS profit
FROM #sales_metrics s JOIN dbo.DimProduct p ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName ORDER BY profit DESC;

SELECT Hour, ROUND(AVG(AvgQueueMinutes), 2) AS avg_queue_minutes,
       ROUND(AVG(CAST(StaffCount AS decimal(12, 2))), 2) AS avg_staff
FROM dbo.FactOperations GROUP BY Hour ORDER BY avg_queue_minutes DESC;

DROP TABLE #sales_metrics;

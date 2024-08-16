Use RetailDB
-- KPI overview of 2022 vs 2023 Customers including Overall and New Customers

SELECT
    YearPeriod,
    -- Overall Customers KPIs
    SUM(TotalSales) AS TotalSalesOverall,
    SUM(TotalQuantity) AS TotalQuantityOverall,
    SUM(Visits) AS TotalVisitsOverall,
    FORMAT(ROUND(SUM(TotalSales) / NULLIF(SUM(Visits), 0), 2), 'N2') AS AOVOverall,
    FORMAT(ROUND(SUM(TotalQuantity) / NULLIF(SUM(Visits), 0), 2), 'N2') AS QPVOverall,
    FORMAT(ROUND(SUM(Visits) * 1.0 / COUNT(DISTINCT CustomerId), 2), 'N2') AS VPCOverall,
    FORMAT(SUM(TotalSales) / NULLIF(SUM(TotalQuantity), 0), 'N2') AS AUROverall,
    SUM(CASE WHEN IsMultiChannelCustomer = 1 THEN 1 ELSE 0 END) AS MultiChannelCustomersOverall,

    -- New Customers KPIs
    SUM(CASE WHEN NewCustomer = 1 THEN TotalSales ELSE 0 END) AS TotalSalesNew,
    SUM(CASE WHEN NewCustomer = 1 THEN TotalQuantity ELSE 0 END) AS TotalQuantityNew,
    SUM(CASE WHEN NewCustomer = 1 THEN Visits ELSE 0 END) AS TotalVisitsNew,
    FORMAT(ROUND(SUM(CASE WHEN NewCustomer = 1 THEN TotalSales ELSE 0 END) / NULLIF(SUM(CASE WHEN NewCustomer = 1 THEN Visits ELSE 0 END), 0), 2), 'N2') AS AOVNew,
    FORMAT(ROUND(SUM(CASE WHEN NewCustomer = 1 THEN TotalQuantity ELSE 0 END) / NULLIF(SUM(CASE WHEN NewCustomer = 1 THEN Visits ELSE 0 END), 0), 2), 'N2') AS QPVNew,
    FORMAT(ROUND(SUM(CASE WHEN NewCustomer = 1 THEN Visits ELSE 0 END) * 1.0 / COUNT(DISTINCT CASE WHEN NewCustomer = 1 THEN CustomerId ELSE NULL END), 2), 'N2') AS VPCNew,
    FORMAT(SUM(CASE WHEN NewCustomer = 1 THEN TotalSales ELSE 0 END) / NULLIF(SUM(CASE WHEN NewCustomer = 1 THEN TotalQuantity ELSE 0 END), 0), 'N2') AS AURNew,
    SUM(CASE WHEN NewCustomer = 1 AND IsMultiChannelCustomer = 1 THEN 1 ELSE 0 END) AS MultiChannelCustomersNew
FROM
    FinalSalesKPI
GROUP BY
    YearPeriod
ORDER BY
    YearPeriod;
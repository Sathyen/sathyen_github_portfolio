Use RetailDB;
WITH ProfileKPI AS (
    -- Aggregate data by Profile for 2022
    SELECT
        fs.Profile,
        '2022' AS YearPeriod,
        SUM(fs.TotalSales) AS TotalSales,
        SUM(fs.TotalQuantity) AS TotalQuantity,
        COUNT(DISTINCT fs.CustomerId) AS TotalCustomers,
        COUNT(DISTINCT CASE WHEN fs.NewCustomer = 1 THEN fs.CustomerId END) AS NewCustomers,
        SUM(fs.Visits) AS TotalVisits,
        SUM(CASE WHEN fs.IsMultiChannelCustomer = 1 THEN 1 ELSE 0 END) AS MultiChannelCustomers
    FROM
        FinalSalesKPI fs
    WHERE
        fs.YearPeriod = '2022'
    GROUP BY
        fs.Profile

    UNION ALL

    -- Aggregate data by Profile for 2023
    SELECT
        fs.Profile,
        '2023' AS YearPeriod,
        SUM(fs.TotalSales) AS TotalSales,
        SUM(fs.TotalQuantity) AS TotalQuantity,
        COUNT(DISTINCT fs.CustomerId) AS TotalCustomers,
        COUNT(DISTINCT CASE WHEN fs.NewCustomer = 1 THEN fs.CustomerId END) AS NewCustomers,
        SUM(fs.Visits) AS TotalVisits,
        SUM(CASE WHEN fs.IsMultiChannelCustomer = 1 THEN 1 ELSE 0 END) AS MultiChannelCustomers
    FROM
        FinalSalesKPI fs
    WHERE
        fs.YearPeriod = '2023'
    GROUP BY
        fs.Profile
),

ProfileGrowth AS (
    SELECT
        p1.Profile,
        p1.TotalSales AS Sales2022,
        p2.TotalSales AS Sales2023,
        ROUND(((p2.TotalSales - p1.TotalSales) / NULLIF(p1.TotalSales, 0)) * 100, 2) AS SalesGrowthPercentage,

		p1.TotalQuantity AS Quantity2022,
        p2.TotalQuantity AS Quantity2023,
        ROUND(((CAST(p2.TotalQuantity AS DECIMAL(10, 2)) - CAST(p1.TotalQuantity AS DECIMAL(10, 2))) / NULLIF(CAST(p1.TotalQuantity AS DECIMAL(10, 2)), 0)) * 100, 2) AS QuantityGrowthPercentage,

        p1.TotalVisits AS Visits2022,
        p2.TotalVisits AS Visits2023,
        ROUND(((CAST(p2.TotalVisits AS DECIMAL(10, 2)) - CAST(p1.TotalVisits AS DECIMAL(10, 2))) / NULLIF(CAST(p1.TotalVisits AS DECIMAL(10, 2)), 0)) * 100, 2) AS VisitsGrowthPercentage,

        p1.TotalCustomers AS Customers2022,
        p2.TotalCustomers AS Customers2023,
        ROUND(((CAST(p2.TotalCustomers AS DECIMAL(10, 2)) - CAST(p1.TotalCustomers AS DECIMAL(10, 2))) / NULLIF(CAST(p1.TotalCustomers AS DECIMAL(10, 2)), 0)) * 100, 2) AS CustomersGrowthPercentage,

        p1.NewCustomers AS NewCustomers2022,
        p2.NewCustomers AS NewCustomers2023,
		ROUND(((CAST(p2.NewCustomers AS DECIMAL(10, 2)) - CAST(p1.NewCustomers AS DECIMAL(10, 2))) / NULLIF(CAST(p1.NewCustomers AS DECIMAL(10, 2)), 0)) * 100, 2) AS NewCustomersGrowthPercentage,

        p1.MultiChannelCustomers AS MultiChannelCustomers2022,
        p2.MultiChannelCustomers AS MultiChannelCustomers2023,
        ROUND(((CAST(p2.MultiChannelCustomers AS DECIMAL(10, 2)) - CAST(p1.MultiChannelCustomers AS DECIMAL(10, 2))) / NULLIF(CAST(p1.MultiChannelCustomers AS DECIMAL(10, 2)), 0)) * 100, 2) AS MultiChannelCustomersGrowthPercentage
    FROM
        ProfileKPI p1
    JOIN
        ProfileKPI p2 ON p1.Profile = p2.Profile AND p1.YearPeriod = '2022' AND p2.YearPeriod = '2023'
)

SELECT
    *,
    -- Highlight best and worst performing profiles based on different KPIs
    CASE 
        WHEN SalesGrowthPercentage = MAX(SalesGrowthPercentage) OVER () THEN 'Best Sales Growth'
        WHEN SalesGrowthPercentage = MIN(SalesGrowthPercentage) OVER () THEN 'Worst Sales Growth'
        WHEN QuantityGrowthPercentage = MAX(QuantityGrowthPercentage) OVER () THEN 'Best Quantity Growth'
        WHEN QuantityGrowthPercentage = MIN(QuantityGrowthPercentage) OVER () THEN 'Worst Quantity Growth'
        WHEN VisitsGrowthPercentage = MAX(VisitsGrowthPercentage) OVER () THEN 'Best Visits Growth'
        WHEN VisitsGrowthPercentage = MIN(VisitsGrowthPercentage) OVER () THEN 'Worst Visits Growth'
        WHEN CustomersGrowthPercentage = MAX(CustomersGrowthPercentage) OVER () THEN 'Best Customer Growth'
        WHEN CustomersGrowthPercentage = MIN(CustomersGrowthPercentage) OVER () THEN 'Worst Customer Growth'
        WHEN NewCustomersGrowthPercentage = MAX(NewCustomersGrowthPercentage) OVER () THEN 'Best New Customer Growth'
        WHEN NewCustomersGrowthPercentage = MIN(NewCustomersGrowthPercentage) OVER () THEN 'Worst New Customer Growth'
        WHEN MultiChannelCustomersGrowthPercentage = MAX(MultiChannelCustomersGrowthPercentage) OVER () THEN 'Best Multi-Channel Customer Growth'
        WHEN MultiChannelCustomersGrowthPercentage = MIN(MultiChannelCustomersGrowthPercentage) OVER () THEN 'Worst Multi-Channel Customer Growth'
        ELSE 'Average'
    END AS PerformanceIndicator
FROM
    ProfileGrowth
ORDER BY
    SalesGrowthPercentage DESC, QuantityGrowthPercentage DESC, VisitsGrowthPercentage DESC;
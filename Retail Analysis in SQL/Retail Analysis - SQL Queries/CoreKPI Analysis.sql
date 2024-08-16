Use RetailDB;
WITH SalesGrowth AS (
    SELECT
		SUM(CASE WHEN YearPeriod = '2023' THEN TotalSales ELSE 0 END) AS Sales2023,
        SUM(CASE WHEN YearPeriod = '2022' THEN TotalSales ELSE 0 END) AS Sales2022,
        SUM(CASE WHEN YearPeriod = '2023' THEN TotalQuantity ELSE 0 END) AS Quantity2023,
        SUM(CASE WHEN YearPeriod = '2022' THEN TotalQuantity ELSE 0 END) AS Quantity2022,
        SUM(CASE WHEN YearPeriod = '2023' THEN Visits ELSE 0 END) AS Visits2023,
        SUM(CASE WHEN YearPeriod = '2022' THEN Visits ELSE 0 END) AS Visits2022,
        StoreId,
        -- Calculate growth percentage for each KPI
        (SUM(CASE WHEN YearPeriod = '2023' THEN TotalSales ELSE 0 END) - 
         SUM(CASE WHEN YearPeriod = '2022' THEN TotalSales ELSE 0 END)) / 
         NULLIF(SUM(CASE WHEN YearPeriod = '2022' THEN TotalSales ELSE 0 END), 0) * 100 AS SalesGrowthPercentage,
        
        ROUND(((SUM(CASE WHEN YearPeriod = '2023' THEN TotalQuantity ELSE 0 END) - 
                SUM(CASE WHEN YearPeriod = '2022' THEN TotalQuantity ELSE 0 END)) /
                NULLIF(CAST(SUM(CASE WHEN YearPeriod = '2022' THEN TotalQuantity ELSE 0 END) AS DECIMAL(10, 2)), 0)) * 100, 2) AS QuantityGrowthPercentage,
        
        ROUND(((SUM(CASE WHEN YearPeriod = '2023' THEN Visits ELSE 0 END) - 
                SUM(CASE WHEN YearPeriod = '2022' THEN Visits ELSE 0 END)) /
                NULLIF(CAST(SUM(CASE WHEN YearPeriod = '2022' THEN Visits ELSE 0 END) AS DECIMAL(10, 2)), 0)) * 100, 2) AS VisitsGrowthPercentage
    FROM
        FinalSalesKPI
    GROUP BY
        StoreId
),

RankedStores AS (
    SELECT
        StoreId,
		SalesGrowthPercentage,
        QuantityGrowthPercentage,
        VisitsGrowthPercentage,
        ROW_NUMBER() OVER (ORDER BY SalesGrowthPercentage DESC) AS SalesRank,
        ROW_NUMBER() OVER (ORDER BY SalesGrowthPercentage ASC) AS SalesRankNegative,
        ROW_NUMBER() OVER (ORDER BY QuantityGrowthPercentage DESC) AS QuantityRank,
        ROW_NUMBER() OVER (ORDER BY QuantityGrowthPercentage ASC) AS QuantityRankNegative,
        ROW_NUMBER() OVER (ORDER BY VisitsGrowthPercentage DESC) AS VisitsRank,
        ROW_NUMBER() OVER (ORDER BY VisitsGrowthPercentage ASC) AS VisitsRankNegative
    FROM
        SalesGrowth
)

-- Select Top 2 and Bottom 2 stores based on Sales Growth
SELECT 
    StoreId, 
    SalesGrowthPercentage AS GrowthPercentage, 
    'Sales' AS CoreKPI, 
    CASE WHEN SalesRank <= 2 THEN 'Top' ELSE 'Bottom' END AS RankType
FROM 
    RankedStores
WHERE 
    SalesRank <= 2 OR SalesRankNegative <= 2

UNION ALL

-- Select Top 2 and Bottom 2 stores based on Quantity Growth
SELECT 
    StoreId, 
    QuantityGrowthPercentage AS GrowthPercentage, 
    'Quantity' AS CoreKPI, 
    CASE WHEN QuantityRank <= 2 THEN 'Top' ELSE 'Bottom' END AS RankType
FROM 
    RankedStores
WHERE 
    QuantityRank <= 2 OR QuantityRankNegative <= 2

UNION ALL

-- Select Top 2 and Bottom 2 stores based on Visits Growth
SELECT 
    StoreId, 
    VisitsGrowthPercentage AS GrowthPercentage, 
    'Visits' AS CoreKPI, 
    CASE WHEN VisitsRank <= 2 THEN 'Top' ELSE 'Bottom' END AS RankType
FROM 
    RankedStores
WHERE 
    VisitsRank <= 2 OR VisitsRankNegative <= 2
ORDER BY 
    RankType, CoreKPI, GrowthPercentage DESC;
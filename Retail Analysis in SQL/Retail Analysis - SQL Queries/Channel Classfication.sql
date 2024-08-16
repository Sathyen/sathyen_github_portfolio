Use RetailDB;
WITH ChannelClassification AS (
    SELECT 
        CustomerId,
        CASE
            WHEN COUNT(DISTINCT PurchaseChannel) = 1 AND MAX(PurchaseChannel) = 'Online' THEN 'Online Only'
            WHEN COUNT(DISTINCT PurchaseChannel) = 1 AND MAX(PurchaseChannel) = 'InStore' THEN 'InStore Only'
            ELSE 'Multichannel'
        END AS ChannelType
    FROM 
        FilteredSales
    WHERE
        DateId BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        CustomerId
),

CustomerKPIs AS (
    SELECT
        --fs.CustomerId,
		cc.ChannelType,
        SUM(fs.Sales) AS TotalSales,
        SUM(fs.Quantity) AS TotalQuantity,
        COUNT(fs.DateId) AS Visits,
        COUNT(DISTINCT fs.CustomerId) AS Customers,
        FORMAT(ROUND(CAST(SUM(fs.Sales) AS DECIMAL(10, 2)) / CAST(COUNT(fs.DateId) AS DECIMAL(10, 2)), 2), 'N2') as AOV,  -- Average Order Value
        FORMAT(ROUND(CAST(SUM(fs.Quantity) AS DECIMAL(10, 2)) / CAST(COUNT(fs.DateId) AS DECIMAL(10, 2)), 2), 'N2') as QPV,  -- Quantity per Visit
        FORMAT(ROUND(CAST(COUNT(fs.DateId) AS DECIMAL(10, 2)) / CAST(COUNT(DISTINCT fs.CustomerId) AS DECIMAL(10, 2)), 2), 'N2') AS VPC, -- Visits per Customer
        FORMAT(ROUND(CAST(SUM(fs.Sales) AS DECIMAL(10, 2)) / NULLIF(SUM(fs.Quantity), 0), 2), 'N2') AS AUR -- Average Unit Retail
    FROM
        FilteredSales fs
    JOIN
        ChannelClassification cc ON fs.CustomerId = cc.CustomerId
    WHERE
        fs.DateId BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY
        cc.ChannelType
)

SELECT
	ChannelType,
    TotalSales,
    TotalQuantity,
    Visits,
    Customers,
    AOV,
    QPV,
    VPC,
    AUR
FROM
    CustomerKPIs
--WHERE
--	Customerid = 'CUST101549'
ORDER BY
    ChannelType;
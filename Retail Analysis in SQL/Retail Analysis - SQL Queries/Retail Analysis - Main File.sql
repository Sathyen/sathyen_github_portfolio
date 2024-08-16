Use RetailDB;

--Commenting this section as the necessary Database and the tables as well as functions have been created
/*
--Create all the 3 tables by handling the special cases (Including handling the Text string 'NULL')

CREATE TABLE Customer (
    CustomerId VARCHAR(20) Primary Key,
    Profile VARCHAR(50),
    Mailable CHAR(1),
    CustLatitude DECIMAL(10, 6),
    CustLongitude DECIMAL(10, 6),
    FirstTransactionDate DATE NULL
);

-- Create a Temporary table for handling the text string 'NULL'

CREATE TABLE Customer_staging (
    CustomerId VARCHAR(20),
    Profile VARCHAR(50),
    Mailable CHAR(1),
    CustLatitude VARCHAR(20),
    CustLongitude VARCHAR(20),
    FirstTransactionDate VARCHAR(20)
);

BULK INSERT Customer_staging
FROM 'F:\Acadia assignment\Customer.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    CODEPAGE = '65001'  -- UTF-8 encoded file
);


SELECT *
FROM Customer_staging
WHERE ISDATE(FirstTransactionDate) = 0;

INSERT INTO Customer (CustomerId, Profile, Mailable, CustLatitude, CustLongitude, FirstTransactionDate)
SELECT
    CustomerId,
    Profile,
    Mailable,
    TRY_CAST(CustLatitude AS DECIMAL(10, 6)),
    TRY_CAST(CustLongitude AS DECIMAL(10, 6)),
    CASE 
        WHEN FirstTransactionDate = 'NULL' THEN NULL
        ELSE TRY_CAST(FirstTransactionDate AS DATETIME) 
    END AS FirstTransactionDate
FROM customer_staging;


-- select * from customer

drop table customer_staging  --drop the Temporary table Customer Staging

-- Create Table Stores

CREATE TABLE Stores (
    StoreId VARCHAR(20) PRIMARY KEY,
    StoreLatitude DECIMAL(9, 6),
    StoreLongitude DECIMAL(9, 6)
);

BULK INSERT Stores
FROM 'F:\Acadia assignment\Stores.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2    
);

-- Create Table Sales

CREATE TABLE Sales (
    StoreId VARCHAR(20),
    PurchaseChannel VARCHAR(50),
    CustomerId VARCHAR(20),
    DateId DATE,
	Sales DECIMAL(10, 2),
    Quantity Int,
	FOREIGN KEY (CustomerId) REFERENCES customer(CustomerId),
	FOREIGN KEY (StoreId) REFERENCES Stores(StoreId)
);

BULK INSERT Sales
FROM 'F:\Acadia assignment\Sales.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2    
);


-- Function to calculate distance between two latitude/longitude points based on Haversine Formula

CREATE FUNCTION dbo.CalculateDistance (
    @lat1 FLOAT, 
    @lon1 FLOAT, 
    @lat2 FLOAT, 
    @lon2 FLOAT
) 
RETURNS FLOAT
AS
BEGIN
    RETURN (3959 * acos(cos(radians(@lat1)) * cos(radians(@lat2)) * cos(radians(@lon2) - radians(@lon1)) + sin(radians(@lat1)) * sin(radians(@lat2))))
END;

-- Code to create the final table for analyzing the KPIs. Remove the comment symbol to enable the code.

WITH DaysServed2022 AS (
    SELECT 
        StoreId,
        COUNT(DISTINCT DateId) AS Days2022
    FROM 
        Sales
    WHERE 
        DateId BETWEEN '2022-12-01' AND '2022-12-31'
    GROUP BY 
        StoreId
),
DaysServed2023 AS (
    SELECT 
        StoreId,
        COUNT(DISTINCT DateId) AS Days2023
    FROM 
        Sales
    WHERE 
        DateId BETWEEN '2023-12-01' AND '2023-12-31'
    GROUP BY 
        StoreId
),
StoresWithEqualDays AS (
    SELECT 
        d2022.StoreId
    FROM 
        DaysServed2022 d2022
    JOIN 
        DaysServed2023 d2023 ON d2022.StoreId = d2023.StoreId
    WHERE 
        d2022.Days2022 = d2023.Days2023
)

--FilteredSales AS (
SELECT 
    s.*, c.Profile, c.FirstTransactionDate
INTO 
    FilteredSales
FROM 
    Sales s
JOIN 
    StoresWithEqualDays eq ON s.StoreId = eq.StoreId
JOIN 
    Customer c ON s.CustomerId = c.CustomerId
JOIN 
    Stores st ON s.StoreId = st.StoreId
WHERE 
    c.Profile IS NOT NULL  --filtering the Customers for the Analysis for which we have a Profile available
    AND dbo.CalculateDistance(c.CustLatitude, c.CustLongitude, st.StoreLatitude, st.StoreLongitude) <= 50 --filtering only the Customers residing within 50 miles of the store they shopped in


SELECT FSK.* INTO
FinalSalesKPI
FROM
(
-- Query to calculate Identified KPIs and New Customer KPIs for 2022
SELECT
    fs.StoreId,
    fs.CustomerId,
	fs.Profile,
	'2022' AS YearPeriod,
    SUM(fs.Sales) AS TotalSales,
    SUM(fs.Quantity) AS TotalQuantity,
    COUNT(DISTINCT fs.DateId) AS Visits,
	CASE WHEN fs.FirstTransactionDate BETWEEN '2022-12-01' AND '2022-12-31' THEN 1 ELSE 0 END AS NewCustomer,
    FORMAT(ROUND(CAST(SUM(fs.Sales) AS DECIMAL(10, 2)) / CAST(COUNT(DISTINCT fs.DateId) AS DECIMAL(10, 2)), 2), 'N2') as AOV,  -- Average Order Value
	FORMAT(ROUND(CAST(SUM(fs.Quantity) AS DECIMAL(10, 2)) / CAST(COUNT(DISTINCT fs.DateId) AS DECIMAL(10, 2)), 2), 'N2') as QPV,  -- Quantity per Visit
    FORMAT(COUNT(DISTINCT fs.DateId) * 1.0 / COUNT(DISTINCT fs.CustomerId), 'N2') AS VPC, -- Visits per Customer
    FORMAT(SUM(fs.Sales) / NULLIF(SUM(fs.Quantity), 0), 'N2') AS AUR, -- Average Unit Retail

    -- Identifying MultiChannel Customers
    CASE 
        WHEN COUNT(DISTINCT fs.PurchaseChannel) > 1 THEN 1
        ELSE 0 
    END AS IsMultiChannelCustomer -- MultiChannel Customer Flag
FROM
    FilteredSales fs
WHERE
	fs.DateId BETWEEN '2022-12-01' AND '2022-12-31'
GROUP BY
    fs.StoreId, fs.CustomerId, fs.Profile, fs.FirstTransactionDate

UNION ALL

-- Query to calculate Identified KPIs and New Customer KPIs for 2023

SELECT
    fs.StoreId,
    fs.CustomerId,
	fs.Profile,
	'2023' AS YearPeriod,
    SUM(fs.Sales) AS TotalSales,
    SUM(fs.Quantity) AS TotalQuantity,
    COUNT(DISTINCT fs.DateId) AS Visits,
	CASE WHEN fs.FirstTransactionDate BETWEEN '2023-12-01' AND '2023-12-31' THEN 1 ELSE 0 END AS NewCustomer,
    FORMAT(ROUND(CAST(SUM(fs.Sales) AS DECIMAL(10, 2)) / CAST(COUNT(DISTINCT fs.DateId) AS DECIMAL(10, 2)), 2), 'N2') as AOV,  -- Average Order Value
	FORMAT(ROUND(CAST(SUM(fs.Quantity) AS DECIMAL(10, 2)) / CAST(COUNT(DISTINCT fs.DateId) AS DECIMAL(10, 2)), 2), 'N2') as QPV,  -- Quantity per Visit
    FORMAT(COUNT(DISTINCT fs.DateId) * 1.0 / COUNT(DISTINCT fs.CustomerId), 'N2') AS VPC, -- Visits per Customer
    FORMAT(SUM(fs.Sales) / NULLIF(SUM(fs.Quantity), 0), 'N2') AS AUR, -- Average Unit Retail

    -- Identifying MultiChannel Customers
    CASE 
        WHEN COUNT(DISTINCT fs.PurchaseChannel) > 1 THEN 1
        ELSE 0 
    END AS IsMultiChannelCustomer -- MultiChannel Customer Flag
FROM
    FilteredSales fs
WHERE
	fs.DateId BETWEEN '2023-12-01' AND '2023-12-31'
GROUP BY
    fs.StoreId, fs.CustomerId, fs.Profile, fs.FirstTransactionDate
) FSK

--Remove the comment symbol to enable the code
*/









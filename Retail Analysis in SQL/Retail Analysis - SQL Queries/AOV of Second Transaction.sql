Use RetailDB;
WITH CustomerPurchases AS (
    SELECT 
        CustomerId,
        DateId,
        Sales,
        ROW_NUMBER() OVER (PARTITION BY CustomerId ORDER BY DateId) AS PurchaseNumber
    FROM 
        FilteredSales
    WHERE 
        DateId BETWEEN '2023-01-01' AND '2023-12-31'
),
SecondTransactions AS (
    SELECT 
        CustomerId,
        Sales AS SecondTransactionSales
    FROM 
        CustomerPurchases
    WHERE 
        PurchaseNumber = 2
)
SELECT 
    COUNT(*) AS NumberOfSecondPurchases,
    SUM(SecondTransactionSales) AS TotalSalesFromSecondTransactions,
    AVG(SecondTransactionSales) AS AverageOrderValueForSecondTransaction
FROM 
    SecondTransactions;
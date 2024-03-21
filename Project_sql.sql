drop database Projectdb;
Create database Projectdb;
Use Projectdb;
-- drop table customerinfo;
-- select * from customerinfo;
-- ALTER TABLE customerinfo
-- RENAME COLUMN ï»¿CustomerId TO Customerid;

-- Objective Questions:
-- 1.	What is the distribution of account balances across different regions?
SELECT 
  region,
  sum(account_balances) AS account_balances
FROM (
  SELECT 
    g.GeographyLocation AS region,
    Round(SUM(b.balance),0) AS account_balances
  FROM 
    geography g
    JOIN customerinfo c ON g.geographyid = c.geographyid
    JOIN bank_churn b ON c.customerid = b.customerid
  GROUP BY g.GeographyLocation, b.customerid
) AS subquery
GROUP BY region;

SELECT 
    g.GeographyLocation ,
    Round(Avg(b.balance),0) AS Account_balances
  FROM 
    geography g
    JOIN customerinfo c ON g.geographyid = c.geographyid
    JOIN bank_churn b ON c.customerid = b.customerid
  GROUP BY g.GeographyLocation;

-- 2.Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. 

SELECT Customerid, Surname, Round(EstimatedSalary,0)
FROM customerinfo
WHERE MONTH(Bank_DOJ) >= 10
order by EstimatedSalary desc
LIMIT 5;


-- 127.0.0.1
-- 3.	Calculate the average number of products used by customers who have a credit card. (SQL)
SELECT AVG(NumOfProducts) AS AvgProducts
FROM bank_churn
WHERE HasCrCard = 1;

-- 4.	Determine the churn rate by gender for the most recent year in the dataset.

SELECT 
    g.GenderCategory,
    COUNT(DISTINCT CASE 
        WHEN YEAR(c.Bank_DOJ) = (SELECT MAX(YEAR(Bank_DOJ)) FROM customerinfo) - 1 THEN c.CustomerID
        WHEN YEAR(c.Bank_DOJ) = (SELECT MAX(YEAR(Bank_DOJ)) FROM customerinfo) AND b.Exited = 1 THEN c.CustomerID
    END) /
    COUNT(DISTINCT CASE WHEN YEAR(c.Bank_DOJ) = (SELECT MAX(YEAR(Bank_DOJ)) FROM customerinfo) THEN c.CustomerID END) * 100
    as ChurnRate
FROM customerinfo c
JOIN gender g ON c.GenderID = g.GenderID
join bank_churn b on c.customerid=b.customerid
WHERE YEAR(c.Bank_DOJ) = (SELECT MAX(YEAR(Bank_DOJ)) FROM customerinfo)
GROUP BY g.GenderCategory;


-- 5.	Compare the average credit score of customers who have exited and those who remain. (SQL)
SELECT 
exited,
  Round(AVG(CreditScore),0)  AS avg_credit_score
FROM
  bank_churn
group by exited;

-- 6.	Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)
SELECT g.GenderCategory, Round(AVG(c.EstimatedSalary),0) AS AvgSalary, Count(ac.ActiveCategory = 'Active Member') AS ActiveAccounts
FROM customerinfo c
JOIN bank_churn b ON c.CustomerId = b.CustomerId
JOIN ActiveCustomer ac ON b.IsActiveMember = ac.ActiveId
JOIN Gender g ON c.GenderID = g.GenderID
GROUP BY g.GenderCategory;

-- 7.	Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)
SELECT
  CASE
    WHEN CreditScore BETWEEN 300 AND 499 THEN '300-499'
    WHEN CreditScore BETWEEN 500 AND 699 THEN '500-699'
    WHEN CreditScore BETWEEN 700 AND 799 THEN '700-799'
    WHEN CreditScore BETWEEN 800 AND 899 THEN '800-899'
    ELSE '900+'
  END AS CreditScoreBucket,
  AVG(Exited) as ExitRate
FROM bank_churn
GROUP BY CreditScoreBucket
ORDER BY ExitRate DESC
limit 1;

-- 8.	Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)
SELECT g.GeographyLocation, COUNT(ac.ActiveID) as NumActiveCustomers
FROM customerinfo c
JOIN geography g ON c.GeographyID = g.GeographyID
join bank_churn b on c.CustomerID=b.CustomerID
LEFT JOIN activecustomer ac ON b.IsActiveMember = ac.ActiveID
WHERE b.Tenure > 5
GROUP BY g.GeographyLocation
ORDER BY NumActiveCustomers DESC
LIMIT 1;

-- 9.	What is the impact of having a credit card on customer churn, based on the available data?
SELECT 
    b.HasCrCard,
    COUNT(DISTINCT CASE WHEN b.Exited = 1 THEN c.CustomerID END) /
    COUNT(DISTINCT c.CustomerID) * 100 as ChurnRate
FROM customerinfo c join bank_churn b on c.customerid=b.customerid
GROUP BY HasCrCard;


-- 10.	For customers who have exited, what is the most common number of products they have used?
Select NumofProducts from (
SELECT NumOfProducts, COUNT(*) as Frequency
FROM bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY Frequency DESC
limit 1) as m;

-- 11.	Examine the trend of customer exits over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.
SELECT YEAR(Bank_DOJ) as JoinYear, MONTH(Bank_DOJ) as JoinMonth, COUNT(*) as NewCustomers
FROM customerinfo
GROUP BY YEAR(Bank_DOJ), MONTH(Bank_DOJ)
ORDER BY JoinYear, JoinMonth;

-- 12.	Analyze the relationship between the number of products and the account balance for customers who have exited.
SELECT NumOfProducts, Round(sum(Balance),0) as account_Balance
FROM bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts;

-- 13.	Identify any potential outliers in terms of spend among customers who have remained with the bank.
SELECT
    c.CustomerID,
    (c.EstimatedSalary - b.Balance) AS Amount_spend,
    ABS((c.EstimatedSalary - b.Balance) - AVG(c.EstimatedSalary - b.Balance) OVER ()) / STDDEV(c.EstimatedSalary - b.Balance) OVER () AS Z_Score
FROM
    bank_churn b
JOIN
    customerinfo c ON c.CustomerID = b.CustomerID
WHERE
    b.Exited = 0
ORDER BY
    Z_Score DESC
LIMIT 10;

-- 14.	Can you create a dashboard incorporating the visuals mentioned above and additionally derive more KPIs if possible?
SELECT
    MAX(c.EstimatedSalary - b.Balance) AS Max_Amount_Spend
FROM
    bank_churn b
JOIN
    customerinfo c ON b.CustomerID = c.CustomerID
WHERE
    b.Exited = 0;

-- 15.	Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. Also, rank the gender according to the average value. (SQL)
SELECT
    g.GenderCategory,
    go.GeographyLocation,
    ROUND(AVG(c.EstimatedSalary), 0) AS AvgIncome,
    RANK() OVER ( ORDER BY AVG(c.EstimatedSalary) DESC) AS RankByIncome
FROM
    customerinfo c
JOIN
    gender g ON c.GenderID = g.GenderID
JOIN
    geography go ON c.GeographyID = go.GeographyID
GROUP BY
    go.GeographyLocation, g.GenderCategory;

-- 16.	Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).
SELECT
  CASE
    WHEN Age BETWEEN 18 AND 30 THEN '18-30'
    WHEN Age BETWEEN 31 AND 50 THEN '31-50'
    WHEN Age >= 51 THEN '50+'
    ELSE 'Unknown'
  END AS AgeBracket,
  AVG(Tenure) AS AvgTenure
FROM
  bank_churn b join customerinfo c on b.customerid=c.customerid
WHERE
  Exited = 1  
GROUP BY
  AgeBracket
  order by AgeBracket;

-- 17.	Is there any direct correlation between the salary and the balance of the customers? And is it different for people who have exited or not?
SELECT
  Exited,
  SUM(c.EstimatedSalary * b.Balance) / SQRT(SUM(c.EstimatedSalary * c.EstimatedSalary) * SUM(b.Balance * b.Balance)) AS SalaryBalanceCorrelation
FROM Customerinfo c 
JOIN Bank_churn b ON c.Customerid = b.Customerid
GROUP BY b.Exited;

-- 18.	Is there any correlation between the salary and the Credit score of customers?
SELECT
  (COUNT(*) * SUM(c.EstimatedSalary * b.CreditScore) - SUM(c.EstimatedSalary) * SUM(b.CreditScore)) / 
  SQRT((COUNT(*) * SUM(c.EstimatedSalary * c.EstimatedSalary) - POW(SUM(c.EstimatedSalary), 2)) * 
       (COUNT(*) * SUM(b.CreditScore * b.CreditScore) - POW(SUM(b.CreditScore), 2))) 
  AS SalaryCreditScoreCorrelation
FROM Customerinfo c 
JOIN Bank_churn b ON c.Customerid = b.Customerid;

-- 19.	Rank each bucket of credit score as per the number of customers who have churned the bank.
SELECT
    CreditScoreBucket,
    COUNT(CustomerID) AS ChurnedCustomers,
    RANK() OVER (ORDER BY COUNT(CustomerID) DESC) AS RankByChurn
FROM (
    SELECT
        CASE
            WHEN CreditScore BETWEEN 300 AND 499 THEN '300-499'
            WHEN CreditScore BETWEEN 500 AND 699 THEN '500-699'
            WHEN CreditScore BETWEEN 700 AND 799 THEN '700-799'
            WHEN CreditScore BETWEEN 800 AND 899 THEN '800-899'
            ELSE '900+'
        END AS CreditScoreBucket,
        CustomerID
    FROM bank_churn
    WHERE Exited = 1
) AS ChurnedCustomersByBucket
GROUP BY CreditScoreBucket
ORDER BY RankByChurn;

-- 20.	According to the age buckets find the number of customers who have a credit card. Also, retrieve those buckets that have a lesser than average number of credit cards per bucket.
  WITH AgeBuckets AS (
  SELECT
    CASE
      WHEN Age BETWEEN 18 AND 30 THEN '18-30'
      WHEN Age BETWEEN 31 AND 50 THEN '31-50'
      WHEN Age >= 51 THEN '50+'
      ELSE 'Unknown'
    END AS AgeBucket,
    COUNT(DISTINCT CASE WHEN b.HasCrCard = 1 THEN c.CustomerID END) AS Count_CreditCardCustomers
  FROM
    bank_churn b
  JOIN
    customerinfo c ON b.CustomerID = c.CustomerID
  GROUP BY
    AgeBucket
)
SELECT
  AgeBucket,
  Count_CreditCardCustomers
FROM
  AgeBuckets
WHERE
  Count_CreditCardCustomers < (SELECT AVG(Count_CreditCardCustomers) FROM AgeBuckets)
ORDER BY
  AgeBucket;

-- 21.	Rank the Locations as per the number of people who have churned the bank and the average balance of the learners.
WITH LocationStats AS (
    SELECT
        g.GeographyLocation,
        COUNT(DISTINCT c.CustomerID) AS ChurnedCustomers,
        AVG(b.Balance) AS AvgBalance
    FROM
        bank_churn b
    JOIN
        customerinfo c ON b.CustomerID = c.CustomerID
    JOIN
        geography g ON c.GeographyID = g.GeographyID
    WHERE
        b.Exited = 1
    GROUP BY
        g.GeographyLocation
)
SELECT
    GeographyLocation,
    ChurnedCustomers,
    Round(AvgBalance,0)as Avg_Balance,
    RANK() OVER (ORDER BY ChurnedCustomers DESC, AvgBalance DESC) AS RankByChurnAndBalance
FROM
    LocationStats
ORDER BY
    RankByChurnAndBalance;

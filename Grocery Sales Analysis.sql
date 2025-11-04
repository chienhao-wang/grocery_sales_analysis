-- Section 1: Data Quality Check and Data Cleaning
-- 1.1 Check any missing value in the fact table - sales

SELECT
	SUM(CASE WHEN SalesID IS NULL THEN 1 END) AS null_sales_id,
	SUM(CASE WHEN SalesPersonID IS NULL THEN 1 END) AS null_salesperson_id,
	SUM(CASE WHEN CustomerID IS NULL THEN 1 END) AS null_customer_id,
	SUM(CASE WHEN Quantity IS NULL THEN 1 END) AS null_quantity,
	SUM(CASE WHEN Discount IS NULL THEN 1 END) AS null_discount,
	SUM(CASE WHEN SalesDate IS NULL THEN 1 END) AS null_sales_date,
	SUM(CASE WHEN TransactionNumber IS NULL THEN 1 END) AS null_trans_number
FROM sales;

/*
In the sales table, there are 67,526 rows with missing SalesDate values, while all other columns in these rows remain complete.

To maintain the accuracy of time-based analyses and product performance insights, I decided to remove these records, 
as missing date information could lead to misleading trends or incorrect aggregation results in subsequent analysis.
*/

-- Section 2: Overall Performance

CREATE OR REPLACE VIEW vw_sales_product AS
SELECT
	s.SalesID,
	p.ProductID,
	p.ProductName,
	p.Price,
	p.categoryID,
	c.CustomerID,
	s.Quantity,
	s.Discount,
	ROUND((p.Price * s.Quantity) * (1 - s.Discount), 4) AS Total_price,
	s.SalesDate,
	s.TransactionNumber
FROM sales s
LEFT JOIN products p
ON s.ProductID = p.ProductID
LEFT JOIN customers c
ON s.CustomerID = c.CustomerID;

SELECT
	COUNT(DISTINCT SalesID) AS number_of_sales,
	ROUND((SUM(Total_price)/1000000),4) AS "total_revenue (million)",
	SUM(Quantity) AS number_of_product_sold,
	COUNT(DISTINCT CustomerID) AS number_of_customers
FROM vw_sales_product;

-- Section 3: Grocery Sales Performance Analysis

-- 3.1 Sales by Month
WITH month_rev AS (
SELECT 
	MONTH(SalesDate) AS MONTH,
	COUNT(SalesID) AS number_of_monthly_sales,
	ROUND(SUM(Total_price), 4) AS monthly_sales
FROM vw_sales_product
GROUP BY MONTH
HAVING MONTH IS NOT NULL
ORDER BY MONTH
)

SELECT
  MONTH,
  ROUND(monthly_sales / 1000000, 4) AS monthly_sales_million,
  ROUND((monthly_sales - LAG(monthly_sales) OVER (ORDER BY MONTH)) / (LAG(monthly_sales) OVER (ORDER BY MONTH)) * 100,2) AS mom_growth_pct
FROM month_rev
ORDER BY MONTH;

-- 3.2 Sales by Day of Week
SELECT
  DAYNAME(SalesDate) AS weekday,
  COUNT(SalesID) AS number_of_sales,
  ROUND((SUM(Total_price) / 1000000) ,4) AS "total_sales (million)",
  ROUND(AVG(Total_price), 4) AS average_sales
FROM vw_sales_product
WHERE SalesDate IS NOT NULL
GROUP BY weekday
ORDER BY FIELD(weekday, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- 3.3 Top 10 Sales by Products
SELECT
	ProductID,
	ProductName,
	ROUND((SUM(Total_price) / 1000000), 4) AS "total_sales (million)"
FROM vw_sales_product
GROUP BY ProductID
ORDER BY ROUND((SUM(Total_price) / 1000000), 4) DESC
LIMIT 10;

-- 3.4 Sales by Prodcut Category
SELECT
	c.CategoryID,
	c.CategoryName,
	COUNT(SalesID) AS number_of_sales,
	ROUND((SUM(Total_price) / 1000000), 4) AS "total_sales (million)",
    ROUND(
        SUM(Total_price) * 100.0 / SUM(SUM(Total_price)) OVER (),
        2
    ) AS "sales_percentage",
	RANK () OVER (ORDER BY SUM(Total_price) DESC) AS rank_by_category
FROM vw_sales_product sp
LEFT JOIN categories c
ON sp.CategoryID = c.CategoryID
GROUP BY c.CategoryID
ORDER BY SUM(Total_price) DESC;

-- 3.5 Top 10 Sales by Cities
CREATE OR REPLACE VIEW vw_sales_customers AS
SELECT
	s.SalesID,
	c.CustomerID,
	p.ProductID,
	city.CityID,
	city.CityName,
	country.CountryID,
	country.CountryName,
	c.FirstName,
	c.MiddleInitial,
	c.LastName,
	(p.Price * s.Quantity) * (1 - s.Discount) AS Total_price
FROM sales s
LEFT JOIN customers c 
ON s.CustomerID = c.CustomerID
LEFT JOIN products p
ON s.ProductID = p.ProductID
LEFT JOIN cities city
ON c.CityID = city.CityID
LEFT JOIN countries country
ON city.CountryID = country.CountryID;
	
SELECT
	CountryID,
	CityID,
	CityName,
	COUNT(SalesID) AS number_of_sales,
	ROUND((SUM(Total_price) / 1000000), 4) AS "total_sales (million)",
	RANK () OVER (ORDER BY SUM(Total_price) DESC) AS rank_by_city
FROM vw_sales_customers
GROUP BY CityID
ORDER BY SUM(Total_price) DESC
LIMIT 10;

-- 3.6 Top 10 Sales by Customers
SELECT
	CustomerID,
	CONCAT(FirstName, " ", LastName) AS full_name,
	COUNT(SalesID) AS number_of_sales,
	ROUND((SUM(Total_price) / 1000), 4) AS "total_sales (thousands)",
	RANK () OVER (ORDER BY SUM(Total_price) DESC) AS rank_by_customer
FROM vw_sales_customers
GROUP BY CustomerID
ORDER BY SUM(Total_price) DESC
LIMIT 10;

-- 3.7 Discount vs. Revenue
SELECT
  ROUND(Discount, 4) AS discount_rate,
  SUM(Quantity) AS total_units,
  ROUND((SUM(Total_price) / 1000000), 4) AS "total_sales (million)",
  ROUND(SUM(Total_price) / SUM(Quantity), 4) AS sales_by_per_unit
FROM vw_sales_product
GROUP BY discount_rate
ORDER BY discount_rate;

-- 3.8 Top 10 Sales by Sales Person
WITH sales_salesperson AS (
	SELECT 
		s.SalesID,
		s.SalesPersonID,
		s.SalesDate,
		e.FirstName, 
		e.MiddleInitial,
		e.LastName,
		e.HireDate,
		ROUND((p.Price * s.Quantity) * (1 - s.Discount), 4) AS Total_price
	FROM sales s
	LEFT JOIN employees e
	ON s.SalesPersonID = e.EmployeeID
	LEFT JOIN products p
	ON s.ProductID = p.ProductID
)

SELECT
	SalesPersonID,
	CONCAT(FirstName, " ", LastName) AS full_name,
	MAX(YEAR(SalesDate)) - YEAR(HireDate) AS "tenure (years)",
	COUNT(SalesID) AS number_of_sales,
	ROUND((SUM(Total_price) / 1000000), 4) AS "total_sales (million)",
	RANK() OVER (ORDER BY SUM(Total_price) DESC) AS rank_by_salesperson
FROM sales_salesperson
GROUP BY SalesPersonID, full_name, HireDate
ORDER BY SUM(Total_price) DESC
LIMIT 10;

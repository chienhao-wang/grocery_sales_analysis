# 🛒 Grocery Sales Database & Analytics  

A **SQL-based end-to-end data analysis project** exploring the operational and sales performance of a grocery retail business **between January 2018 and May 2018**.  
This project covers database schema design, data cleaning, and analytical queries to derive key business insights from structured sales data.

![Status](https://img.shields.io/badge/Status-Project_Completed-success)
![SQL](https://img.shields.io/badge/SQL-Data_Extraction-4479A1?style=flat&logo=postgresql&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-Dashboarding-E97627?style=flat&logo=tableau&logoColor=white)

---

## ⫶☰ Table of Contents

- [Project Overview](#%EF%B8%8F-project-overview)
- [Entity Relationship Diagram (ERD)](#-entity-relationship-diagram-erd)
- [Database Design Summary](#%EF%B8%8F-database-design-summary)
- [Data Quality & Cleaning](#-data-quality--cleaning)
- [Dashboard](#-dashboard)
- [Business Analysis & Key Insights](#-data-quality--cleaning)
- [Conclusion](#-conclusion)

---

## 🗂️ Project Overview  

This project demonstrates the complete **data lifecycle** within a grocery retail database — from data modeling and ETL setup to performance analytics and insights.  

- **Database Creation & ETL:** Defined normalised schema and imported CSV datasets.  
- **Data Cleaning:** Identified and removed missing or invalid records.  
- **Sales Analysis:** Conducted multi-dimensional performance analysis by product, region, time, and personnel.  
- **Visualisation Ready:** Prepared clean and structured views for BI tools and reporting.

---

## 🧩 Entity Relationship Diagram (ERD)

Below is the entity relationship diagram illustrating the database schema:  

<p align="center">
  <img src="grocery_sales_ER diagram.png" alt="ER Diagram" width="600">
</p>

**Key Entities:**  
- **`sales`** – Central fact table containing transactional data.  
- **`products`, `categories`** – Define product hierarchy and attributes.  
- **`customers`, `cities`, `countries`** – Capture customer demographics and geography.  
- **`employees`** – Records of sales personnel.  

---

## ⚙️ Database Design Summary  

Implemented using **MySQL**, the schema includes strong referential integrity via **foreign keys**:  

| Table          | Description                            | Primary Key (PK) | Foreign Key (FK)                                  |
|----------------|----------------------------------------|------------------|---------------------------------------------------|
| **categories** | Product category information           | CategoryID       |                                                   |
| **countries**  | Country-level data                     | CountryID        |                                                   |
| **cities**     | City data linked to countries          | CityID           | CountryID                                         |
| **customers**  | Customer profiles linked to cities     | CustomerID       | CityID                                            |
| **employees**  | Employee and sales representative info | EmployeeID       | CityID                                            |
| **products**   | Product details including category     | ProductID        | CategoryID                                        |
| **sales**      | Transaction data with discounts        | SalesID          | ProductID, CustomerID, SalesPersonID (EmployeeID) |

---

## 🧼 Data Quality & Cleaning  

- Found missing values in `SalesDate` (67,526 records).  
- These null timestamps were **removed** to ensure accurate time-series and trend analysis.  
- Other dimensions (`CustomerID`, `ProductID`, `SalesPersonID`) were **complete** and valid.  

---

## 📈 Dashboard

<p align="center">
  <img src="Grocery%20Sales%20Dashboard.png" alt="Grocery Sales Dashboard" width="600">
</p>

[View Tableau Dashboard](https://public.tableau.com/app/profile/chien.hao.wang/viz/GrocerySalesDashboard_17609754421160/Dashboard1)

---

## 📊 Business Analysis & Key Insights  

### **1. Overall Performance**  
- **Total Sales Transactions:** `6,758,125`  
- **Total Revenue:** `4,332.44 million dollars`  
- **Products Sold:** `87,882,708`  
- **Active Customers:** `98,759`  

<details>
<summary> 🛢 View SQL Script for this analysis</summary>  

```sql
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
```
</details>

---

### **2. Monthly Sales Trends**  
- Clear **seasonality** observed across months, with highest sales in `March` and lowest in `May`.  
- **Month-over-Month growth** peaked at `11.68%`.

| Month    | Total Sales (million) | MoM Growth (%) | 
|----------|----------------------:|---------------:|
| January  | 1030.73               |                |
| February | 929.21                | -9.85          |
| March    | 1032.20               | 11.08          |
| April    | 997.27                | -3.38          |
| May      | 299.83                | -69.93         | 

<details>
<summary> 🛢 View SQL Script for this analysis</summary>  

```sql
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
```
</details>

---

### **3. Sales by Day of Week**  
- `Wednesday` records the highest sales volume; however, the variation across weekdays and weekends is minimal, indicating a **relatively stable sales pattern** throughout the week.

| Weekday    | Number of Sales | Total Sales (million) | Average Sales  |
|------------|----------------:|----------------------:|---------------:|
| Monday     | 984,736         | 631.66                | 641.45         |
| Tuesday    | 985,360         | 631.06                | 640.44         |
| Wednesday  | 985,465         | 631.89                | 641.21         |
| Thursday   | 933,423         | 597.96                | 640.61         |
| Friday     | 934,577         | 599.33                | 641.28         |
| Saturday   | 933,233         | 598.50                | 641.32         |
| Sunday     | 933,805         | 598.85                | 641.30         |

<details>
<summary> 🛢 View SQL Script for this analysis</summary>  

```sql
SELECT
  DAYNAME(SalesDate) AS weekday,
  COUNT(SalesID) AS number_of_sales,
  ROUND((SUM(Total_price) / 1000000) ,4) AS "total_sales (million)",
  ROUND(AVG(Total_price), 4) AS average_sales
FROM vw_sales_product
WHERE SalesDate IS NOT NULL
GROUP BY weekday
ORDER BY FIELD(weekday, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');
```
</details>

---

### **4. Top Performing Products & Categories**  
- **Top 10 Products:**

| Product Name               | Total Sales (million) |
|----------------------------|----------------------:|
| Bread - Calabrese Baguette | 18.8688               |
| Shrimp - 31/40             | 18.7219               |
| Puree - Passion Fruit      | 18.7035               |
| Tia Maria                  | 18.6851               |
| Zucchini - Yellow          | 18.5517               |
| Vanilla Beans              | 18.5304               |
| Beef - Inside Round        | 18.3335               |
| Grenadine                  | 18.3312               |
| Lettuce - Treviso          | 18.3219               |
| Pop Shoppe Cream Soda      | 18.2414               |

- **Top Categories:** `Confections` dominating with `12.85%` of total revenue.  

| Rank | Category Name | Number of Sales | Total Sales (million) | Sales Percentage (%) |
|------:|----------------|----------------:|----------------------:|---------------------:|
| 1 | Confections | 851,979 | 556.9307 | 12.85 |
| 2 | Meat | 747,762 | 492.8888 | 11.38 |
| 3 | Poultry | 704,145 | 440.0256 | 10.16 |
| 4 | Cereals | 617,771 | 427.3934 | 9.86 |
| 5 | Snails | 553,612 | 372.0849 | 8.59 |
| 6 | Produce | 642,897 | 368.2436 | 8.50 |
| 7 | Beverages | 569,175 | 366.5150 | 8.46 |
| 8 | Dairy | 523,869 | 354.3582 | 8.18 |
| 9 | Seafood | 537,576 | 330.5280 | 7.63 |
| 10 | Grain | 417,853 | 323.8791 | 7.48 |
| 11 | Shell fish | 537,486 | 299.5983 | 6.92 |


<details>
<summary> 🛢 View SQL Script for this analysis</summary>  

```sql
-- Top 10 Sales by Products
SELECT
	ProductID,
	ProductName,
	ROUND((SUM(Total_price) / 1000000), 4) AS "total_sales (million)"
FROM vw_sales_product
GROUP BY ProductID
ORDER BY ROUND((SUM(Total_price) / 1000000), 4) DESC
LIMIT 10;

-- Sales by Prodcut Category
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
```
</details>

---

### **5. Regional Sales Performance**  
- **Top 10 Cities:** `Tucson` contributing the majority of sales.  

| Rank | Country        | City Name   | Number of Sales | Total Sales (million) |
|------:|----------------|-------------|----------------:|----------------------:|
| 1 | United States | Tucson       | 75,674 | 48.8392 |
| 2 | United States | Jackson      | 72,532 | 48.4161 |
| 3 | United States | Sacramento   | 74,564 | 48.1912 |
| 4 | United States | Fort Wayne   | 75,130 | 47.6901 |
| 5 | United States | Indianapolis | 74,533 | 47.3790 |
| 6 | United States | Columbus     | 74,902 | 47.3393 |
| 7 | United States | Charlotte    | 74,127 | 47.1202 |
| 8 | United States | San Antonio  | 71,588 | 47.1172 |
| 9 | United States | Phoenix      | 73,894 | 46.8314 |
| 10 | United States | Yonkers      | 73,603 | 46.7514 |

<details>
<summary> 🛢 View SQL Script for this analysis</summary>  

```sql
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
```
</details>

---

### **6. Customer Value Segmentation**  
- The top 10 customers contribute only **a small share of total sales**, suggesting the absence of a dominant loyal customer group to target for promotional strategies.  

| Rank | Customer Name     | Number of Sales | Total Sales (thousands) |
|------:|-------------------|----------------:|------------------------:|
| 1 | Wayne Chan       | 103 | 130.3242 |
| 2 | Olivia Dean       | 97  | 123.0049 |
| 3 | Ronda Wallace     | 94  | 121.9226 |
| 4 | Ericka O'Connor   | 96  | 121.8840 |
| 5 | Paula Lin         | 96  | 120.8498 |
| 6 | Benny Wilson      | 93  | 119.8538 |
| 7 | Tamiko Newman     | 87  | 119.4186 |
| 8 | Kerri Bautista    | 89  | 119.1803 |
| 9 | Jami York         | 92  | 118.6877 |
| 10 | Roberto Durham   | 91  | 118.6246 |

<details>
<summary> 🛢 View SQL Script for this analysis</summary>  

```sql
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
```
</details>

---

### **7. Discount Impact on Revenue**  
- No discount rates produce to **optimal sales**.  
- Excessive discounts (`> 20%`) show diminishing returns.  

| Discount Rate | Total Sold Units | Total Sales (million) | Sales per Unit |
|---------------:|-------------:|----------------------:|---------------:|
| 0.0 | 70,302,232 | 3,573.2763 | 50.8274 |
| 0.1 | 8,817,780  | 403.0475   | 45.7085 |
| 0.2 | 8,762,696  | 356.1219   | 40.6407 |

<details>
<summary> 🛢 View SQL Script for this analysis</summary>  

```sql
SELECT
  ROUND(Discount, 4) AS discount_rate,
  SUM(Quantity) AS total_units,
  ROUND((SUM(Total_price) / 1000000), 4) AS "total_sales (million)",
  ROUND(SUM(Total_price) / SUM(Quantity), 4) AS sales_by_per_unit
FROM vw_sales_product
GROUP BY discount_rate
ORDER BY discount_rate;
```
</details>

---

### **8. Salesperson Performance**  
- **Top Performer:** `Devon Brewer` with total sales of `190.04 million`.  
- There is no clear correlation between **tenure (HireDate)** and total revenue contribution.  

| Rank | Salesperson Name | Tenure (years) | Number of Sales | Total Sales (million) |
|------:|------------------|----------------:|----------------:|----------------------:|
| 1 | Devon Brewer     | 2 | 294,983 | 190.0427 |
| 2 | Shelby Riddle    | 5 | 293,562 | 189.4131 |
| 3 | Katina Marks     | 7 | 293,530 | 189.3129 |
| 4 | Desiree Stuart   | 4 | 293,711 | 189.2226 |
| 5 | Darnell Nielsen  | 4 | 294,744 | 189.1136 |
| 6 | Wendi Buckley    | 2 | 294,035 | 189.0622 |
| 7 | Julie Dyer       | 4 | 294,449 | 188.8626 |
| 8 | Chadwick Cook    | 2 | 293,967 | 188.7950 |
| 9 | Holly Collins    | 5 | 293,973 | 188.7848 |
| 10 | Tonia Mc Millan | 3 | 293,224 | 188.7811 |

<details>
<summary> 🛢 View SQL Script for this analysis</summary>  

```sql
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
```
</details>

---

## 🧠 Conclusion  

The analysis indicates a **stable and well-performing grocery business**, supported by consistent demand and a balanced customer base.  
While overall performance is strong, the data reveals clear opportunities to enhance efficiency and profitability across product, regional, and seasonal dimensions.  

- **Stable Sales Base:** Over `£4.3B` in total revenue and `6.7M` transactions confirm a solid and resilient market position.  
- **Seasonal Variations:** March shows peak sales while May experiences a decline — suggesting potential for targeted seasonal recovery campaigns.  
- **Category Drivers:** Confections, Meat, and Poultry contribute nearly one-third of total sales, forming the core of business profitability.  
- **Regional Strength:** U.S. cities such as Tucson and Sacramento outperform others, representing high-value markets for focused investment.  
- **Customer Distribution:** Sales are evenly spread across customers, reducing dependency but limiting loyalty-based growth.  
- **Discount Sensitivity:** Revenue drops beyond moderate discount levels, indicating that controlled promotions yield better margins.  
- **Salesforce Consistency:** Top salespeople perform within a close range, reflecting a stable and experienced commercial team.  

Overall, the company demonstrates **strong fundamentals** and can further enhance performance through **seasonal planning**, **category prioritisation**, and **data-informed marketing strategies**.

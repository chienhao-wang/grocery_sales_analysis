CREATE DATABASE grocery_sales;

USE grocery_sales;

-- Create categories table and directly import csv file
CREATE TABLE categories (
  CategoryID INT NOT NULL,
  CategoryName TEXT,
  PRIMARY KEY (CategoryID),
  UNIQUE KEY CategoryID_UNIQUE (CategoryID)
);

-- Create cities table and import csv file
CREATE TABLE cities (
  CityID INT NOT NULL,
  CityName TEXT,
  Zipcode DOUBLE,
  CountryID INT,
  PRIMARY KEY (CityID),
  UNIQUE KEY CityID_UNIQUE (CityID),
  FOREIGN KEY (CountryID) REFERENCES countries (CountryID)
) ;

-- Create countries table and directly import csv file
CREATE TABLE countries (
  CountryID INT NOT NULL,
  CountryName TEXT,
  CountryCode TEXT,
  PRIMARY KEY (CountryID),
  UNIQUE KEY CountryID_UNIQUE (CountryID)
);

-- Create customers table and using local_infile to import csv file because its large size
CREATE TABLE customers (
  CustomerID INT NOT NULL,
  FirstName TEXT,
  MiddleInitial TEXT,
  LastName TEXT,
  CityID INT,
  Address TEXT,
  PRIMARY KEY (CustomerID),
  UNIQUE KEY CustomerID_UNIQUE (CustomerID),
  FOREIGN KEY (CityID) REFERENCES cities (CityID)
);

-- Create employees table and directly import csv file
CREATE TABLE employees (
  EmployeeID INT NOT NULL,
  FirstName TEXT,
  MiddleInitial TEXT,
  LastName TEXT,
  BirthDate DATETIME ,
  Gender TEXT,
  CityID INT ,
  HireDate DATETIME,
  PRIMARY KEY (EmployeeID),
  UNIQUE KEY EmployeeID_UNIQUE (EmployeeID),
  FOREIGN KEY (CityID) REFERENCES cities (CityID)
);

-- Create products table and directly import csv file
CREATE TABLE products (
  ProductID INT NOT NULL,
  ProductName TEXT,
  Price DOUBLE,
  CategoryID INT,
  Class TEXT,
  ModifyDate DATETIME,
  Resistant TEXT,
  IsAllergic TEXT,
  VitalityDays DOUBLE,
  PRIMARY KEY (ProductID),
  UNIQUE KEY ProductID_UNIQUE (ProductID),
  FOREIGN KEY (CategoryID) REFERENCES categories (CategoryID)
);

-- Create sales table and using local_infile to import csv file because its large size
CREATE TABLE sales (
  SalesID INT NOT NULL,
  SalesPersonID INT,
  CustomerID INT,
  ProductID INT,
  Quantity INT,
  Discount DOUBLE,
  SalesDate TEXT,
  TransactionNumber TEXT,
  PRIMARY KEY (SalesID),
  UNIQUE KEY SalesID_UNIQUE (SalesID),
  FOREIGN KEY (SalesPersonID) REFERENCES employees (EmployeeID),
  FOREIGN KEY (CustomerID) REFERENCES customers (CustomerID),
  FOREIGN KEY (ProductID) REFERENCES products (ProductID)
);

-- Because some SalesDate columns contain empty value, I convert empty values into null
UPDATE sales
SET SalesDate = NULL
WHERE SalesDate = '';

-- Finally, the data type of the SalesDate column should be DATETIME
ALTER TABLE sales
MODIFY COLUMN SalesDate DATETIME;

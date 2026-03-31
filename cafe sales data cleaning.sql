SELECT * FROM dirty_cafe_sales;

-- create table to work on with keeping the raw data : 

CREATE TABLE cleaning_sales
LIKE dirty_cafe_sales;

INSERT cleaning_sales 
SELECT * FROM dirty_cafe_sales;

-- now we start check for duplicates and remove it :

WITH duplicates_check AS (
SELECT * ,
ROW_NUMBER () OVER ( PARTITION BY 
`Transaction ID`,
Item,
Quantity,
`Price Per Unit`,
`Total Spent`,
`Payment Method`,
Location,
`Transaction Date`
) AS row_num
FROM cleaning_sales)

SELECT * FROM duplicates_check 
WHERE row_num > 1;
-- no duplicates found 

-- standardizing the data : 
-- set any error or blanks to null 
SELECT DISTINCT Item FROM cleaning_sales;
UPDATE cleaning_sales
SET Item = NULL 
WHERE Item = 'UNKNOWN'
OR Item = ''
OR Item = 'ERROR';

SELECT DISTINCT `Total Spent` FROM cleaning_sales;
UPDATE cleaning_sales
SET `Total Spent` = NULL 
WHERE `Total Spent` = 'UNKNOWN'
OR `Total Spent` = ''
OR `Total Spent` = 'ERROR';

SELECT DISTINCT `Payment Method` FROM cleaning_sales;
UPDATE cleaning_sales
SET `Payment Method` = NULL 
WHERE `Payment Method` = 'UNKNOWN'
OR `Payment Method` = ''
OR `Payment Method` = 'ERROR';

SELECT DISTINCT Location FROM cleaning_sales;
UPDATE cleaning_sales
SET Location = NULL 
WHERE Location = 'UNKNOWN'
OR Location = ''
OR Location = 'ERROR';

SELECT DISTINCT `Transaction Date` FROM cleaning_sales;
UPDATE cleaning_sales
SET `Transaction Date` = NULL 
WHERE `Transaction Date` = 'UNKNOWN'
OR `Transaction Date` = ''
OR `Transaction Date` = 'ERROR';

-- fix data type of columns

ALTER TABLE cleaning_sales
MODIFY COLUMN Quantity DOUBLE;

ALTER TABLE cleaning_sales
MODIFY COLUMN `Total Spent` DOUBLE;

ALTER TABLE cleaning_sales
MODIFY COLUMN `Transaction Date` DATE;

-- check calculations for total spent 
SELECT Quantity, `Price Per Unit` , `Total Spent`
FROM cleaning_sales
WHERE `Total Spent` != `Price Per Unit` * Quantity
OR `Total Spent` IS NULL
;

UPDATE cleaning_sales
SET `Total Spent` = `Price Per Unit` * Quantity
WHERE `Total Spent` != `Price Per Unit` * Quantity
OR `Total Spent` IS NULL;
-- fixed the calculation 

-- remove useless data and add them to another table:

CREATE TABLE cleaning_sales_missing
LIKE cleaning_sales;

INSERT cleaning_sales_missing
SELECT * 
FROM cleaning_sales
WHERE Item IS NULL 
OR Location IS NULL 
OR `Transaction Date` IS NULL 
;

DELETE 
FROM cleaning_sales
WHERE Item IS NULL 
OR Location IS NULL 
OR `Transaction Date` IS NULL 
;

SELECT * FROM cleaning_sales;
-- now we have a table of 4697 rows of useful data :)

-- Exploratory Data Analysis
-- Total sales 
SELECT SUM(`Total Spent`) AS total_sales
FROM cleaning_sales;

-- Most Sold Items
SELECT Item, SUM(Quantity) AS total_quantity
FROM cleaning_sales
GROUP BY Item
ORDER BY total_quantity DESC;

-- Sales by Location
SELECT Location, SUM(`Total Spent`) AS total_sales
FROM cleaning_sales
GROUP BY Location
ORDER BY total_sales DESC;

-- Best Payment Method
SELECT `Payment Method`, COUNT(*) AS usage_count
FROM cleaning_sales
GROUP BY `Payment Method`
ORDER BY usage_count DESC;

-- Monthly Sales
SELECT 
MONTH(`Transaction Date`) AS month,
SUM(`Total Spent`) AS monthly_sales
FROM cleaning_sales
GROUP BY MONTH(`Transaction Date`)
ORDER BY month;

-- Daily Sales
SELECT `Transaction Date`, SUM(`Total Spent`) AS 'Daily Sales'
FROM cleaning_sales
GROUP BY `Transaction Date`
ORDER BY `Transaction Date`;

-- Average Order Value
SELECT AVG(`Total Spent`) AS avg_order_value
FROM cleaning_sales;
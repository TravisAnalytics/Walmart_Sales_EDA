-- Testing & Extra Cleaning
CREATE DATABASE walmart_db;
CREATE TABLE walmart_sales;
SELECT *
FROM walmart_sales;

ALTER TABLE walmart_sales
RENAME COLUMN Branch TO branch;

-- Walmart Project Queries - MySQL

SELECT * FROM walmart;

-- DROP TABLE walmart;

-- DROP TABLE walmart;

-- Count total records
SELECT COUNT(*) FROM walmart;

-- Count payment methods and number of transactions by payment method
SELECT  
	payment_method,
    COUNT(*)
FROM walmart_sales
GROUP BY payment_method
ORDER BY COUNT(*) DESC;

-- Count distinct branches
SELECT 
	COUNT(DISTINCT branch)
    branch
FROM walmart_sales;

-- Find the minimum quantity sold
SELECT
	MAX(quantity),
    MIN(quantity)
FROM walmart_sales;

-- Business Problem Q1: Find different payment methods, number of transactions, and quantity sold by payment method
SELECT
	payment_method,
    COUNT(*),
    SUM(quantity)
FROM walmart_sales
GROUP BY payment_method;

-- Project Question #2: Identify the highest-rated category in each branch
-- Display the branch, category, and avg rating
WITH category_avg AS (
    SELECT branch, category, AVG(rating) AS avg_rating
    FROM walmart_sales
    GROUP BY branch, category
),
ranked AS (
    SELECT 
        branch, 
        category, 
        avg_rating, 
        RANK() OVER (PARTITION BY branch ORDER BY avg_rating DESC) AS branch_rank
    FROM category_avg
)
SELECT *
FROM ranked
WHERE branch_rank = 1;

-- Q3: Identify the busiest day for each branch based on the number of transactions
WITH day_trans AS (
SELECT 
    branch,
    DATE_FORMAT(STR_TO_DATE(`date`, '%d/%m/%Y'), '%W') AS day_name,
    COUNT(*) AS transactions
FROM walmart_sales
GROUP BY branch, day_name
ORDER BY branch, transactions
), ranked AS (
SELECT 
	branch,
    day_name,
    transactions,
    RANK() OVER(PARTITION BY branch ORDER BY transactions DESC) AS rank_num
FROM day_trans
)
SELECT *
FROM ranked
WHERE rank_num = 1;

-- Q4: Calculate the total quantity of items sold per payment method
SELECT
	payment_method,
    SUM(quantity)
FROM walmart_sales
GROUP BY payment_method;

-- Q5: Determine the average, minimum, and maximum rating of categories for each city
SELECT
	city,
    category,
    ROUND(AVG(rating),1) AS average,
    MAX(rating) AS max,
    MIN(rating) AS min
FROM walmart_sales
GROUP BY city, category
ORDER BY city DESC;


-- Q6: Calculate the total profit for each category
SELECT
	category,
    ROUND(SUM(total),2) AS revenue,
    ROUND(SUM(total * profit_margin),2) AS profit
FROM walmart_sales
GROUP BY category
ORDER BY profit;

-- Q7: Determine the most common payment method for each branch
WITH branch_payment AS 
(
SELECT 
	branch,
    payment_method,
    COUNT(*) AS num_used
FROM walmart_sales
GROUP BY branch, payment_method
),
ranked_order AS (
SELECT
	branch,
    payment_method,
    num_used,
    RANK() OVER(PARTITION BY branch ORDER BY num_used DESC) AS rank_num
FROM branch_payment
)
SELECT * 
FROM ranked_order
WHERE rank_num = 1;

-- Q8: Categorize sales into Morning, Afternoon, and Evening shifts
WITH shift_time AS (
SELECT
	branch,
	CASE
		WHEN EXTRACT(HOUR FROM time) < 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
	END AS shift,
    CASE
		WHEN EXTRACT(HOUR FROM time) < 12 THEN 1
        WHEN EXTRACT(HOUR FROM time) BETWEEN 12 AND 17 THEN 2
        ELSE 3
	END AS shift_num,
    COUNT(*) AS invoices
FROM walmart_sales
GROUP BY branch, shift, shift_num
)
SELECT 
	branch,
	shift,
    shift_num,
	invoices
FROM shift_time
ORDER BY branch, shift_num;

-- Q9: Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023)
WITH 2022_rev AS (
SELECT 
	branch,
    SUM(total) as revenue
FROM walmart_sales
WHERE EXTRACT(YEAR FROM str_to_date(`date`, '%d/%m/%Y')) = 2022
GROUP BY branch
), 2023_rev AS (
SELECT 
	branch,
    SUM(total) as revenue
FROM walmart_sales
WHERE EXTRACT(YEAR FROM str_to_date(`date`, '%d/%m/%Y')) = 2023
GROUP BY branch
)
SELECT 
	ly.branch,
    ly.revenue as last_year,
    cy.revenue as current_year,
    ROUND(((ly.revenue - cy.revenue)/ly.revenue * 100),2) AS revenue_decrease_ratio
FROM 2022_rev AS ly
JOIN 
2023_rev AS cy
ON ly.branch = cy.branch
WHERE ly.revenue > cy.revenue
LIMIT 5; 

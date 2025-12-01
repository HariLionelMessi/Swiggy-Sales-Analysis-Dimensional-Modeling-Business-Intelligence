--Data exploration and cleaning
SELECT * FROM swiggy_data

--Data Cleaning
-- FINDING HOW MANY NULL VALUES exist
SELECT 
SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) as state_null,
SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) as city_null,
SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) as order_date_null,
SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) as state_null,
SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) as Restaurant_Name_null,
SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) as location_null,
SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) as category_null,
SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) as dish_name_null,
SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) as price_null,
SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) as rating_null,
SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) as rating_count_null
FROM swiggy_data

-- INSIGHT: No null values found


--Blank/Empty String Check

SELECT * FROM swiggy_data
WHERE State = '' OR City = '' OR Order_Date = ''
OR Restaurant_Name = '' OR Location = '' OR
Category = '' OR Dish_Name = '' 

-- Insight: No Blank value in dimension table


--Duplicate Detection

SELECT 
State, City, Order_Date, Restaurant_Name, Location, Category, Dish_Name, 
Price_INR, Rating, Rating_Count, COUNT(*) as repeat_count
FROM swiggy_data
GROUP BY State, City, Order_Date, Restaurant_Name, 
Location, Category, Dish_Name, Price_INR, Rating, Rating_Count
HAVING COUNT(*) > 1

-- Found 29 duplicate rows. 


-- DELETE DUPLICATION
WITH del_cte AS (
SELECT *, 
ROW_NUMBER() OVER 
(PARTITION BY State, City, Order_Date, Restaurant_Name, Location, Category, Dish_Name, 
Price_INR, Rating, Rating_Count ORDER BY (SELECT NULL)) AS rn
FROM swiggy_data)

DELETE FROM del_cte WHERE rn > 1

--(29 rows affected)


-- STAR SCHEMA EXTRACTION
-- NORMALIZATION OF THE DATA TO REDUCE REDUDANCY AND MAINTAIN CONSISTENCY
-----------------------DIMENSION TABLE-------------------------------------
-- DATE TABLE

CREATE TABLE dim_date (
	date_id INT IDENTITY(1,1) PRIMARY KEY,
	FULL_DATE DATE,
	YEAR INT,
	MONTH INT, 
	MONTH_NAME VARCHAR(100),
	QUARTER INT,
	DAY INT,
	WEEK INT
)

-- LOCATION TABLE
CREATE TABLE dim_location (
	location_id INT IDENTITY(1,1) PRIMARY KEY,
	State VARCHAR(100),
	City VARCHAR(100),
	Location VARCHAR(250)
);

-- RESTAURANT TABLE
CREATE TABLE dim_restaurant (
	restaurant_id INT IDENTITY(1,1) PRIMARY KEY, 
	Restaurant_Name VARCHAR(250)
)

-- CATEGORY TABLE
CREATE TABLE dim_category (
	category_id INT IDENTITY(1,1) PRIMARY KEY,
	Category VARCHAR(200)
)

-- DISH TABLE
CREATE TABLE dim_dish (
	dish_id INT IDENTITY(1,1) PRIMARY KEY,
	Dish_Name VARCHAR(200)
)


-----------------------FACT TABLE-------------------------------------
-- FACT TABLE CREATION
CREATE TABLE fact_swiggy_orders (
	Order_id INT IDENTITY(1,1) PRIMARY KEY,

	date_id INT,
	Price_INR decimal(10,2),
	Rating DECIMAL(4,2),
	Rating_Count INT,

	location_id INT,
	restaurant_id INT, 
	category_id INT,
	dish_id INT,

	FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
	FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
	FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
	FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
	FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
)





-- inserting data in fact and dimension tables


INSERT INTO dim_date (FULL_DATE, YEAR, MONTH, MONTH_NAME, QUARTER, DAY, WEEK)
SELECT DISTINCT 
	Order_Date,
	YEAR(Order_Date),
	MONTH(Order_Date),
	DATENAME(MONTH, Order_Date),
	DATEPART(QUARTER, Order_Date),
	DAY(order_date),
	DATEPART(WEEK, Order_Date)
FROM swiggy_data
WHERE Order_Date IS NOT NULL

--location table 
INSERT INTO dim_location (State, City, Location)
SELECT DISTINCT 
State,
City,
Location
FROM swiggy_data

INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT
	Restaurant_Name
FROM swiggy_data

INSERT INTO dim_category(Category)
SELECT DISTINCT
	Category
FROM swiggy_data

INSERT INTO dim_dish(Dish_Name)
SELECT DISTINCT
	Dish_Name
FROM swiggy_data

---- FACT TABLE INSERT COMMAND—
INSERT INTO fact_swiggy_orders (
	date_id,
	Price_INR ,
	Rating ,
	Rating_Count,
	location_id ,
	restaurant_id , 
	category_id ,
	dish_id 
)
SELECT 
dd.date_id,
s.Price_INR, 
s.Rating, 
s.Rating_Count,

dl.location_id,
dr.restaurant_id,
dc.category_id,
dsh.dish_id
FROM 
swiggy_data s

JOIN dim_date dd
	on dd.FULL_DATE = s.Order_Date

JOIN dim_location dl
	on dl.State = s.State
	AND dl.City = s.City
	AND dl.Location = s.Location

JOIN dim_restaurant dr
	on dr.Restaurant_Name = s.Restaurant_Name

JOIN dim_category dc
	on dc.Category = s.Category

JOIN dim_dish dsh
	ON dsh.Dish_Name = s.Dish_Name



--Business analysis
SELECT * FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l ON l.location_id = f.location_id
JOIN dim_restaurant r ON r.restaurant_id = f.restaurant_id
JOIN dim_category c ON f.category_id = c.category_id
JOIN dim_dish di ON f.dish_id = di.dish_id


/*
Basic KPIs
	Total Orders
	Total Revenue (INR Million)
	Average Dish Price
	Average Rating
*/
-- TOTAL Orders
SELECT COUNT(Order_id) as total_orders FROM fact_swiggy_orders 

--Total Revenue (INR Million)
SELECT CAST(CAST(SUM(Price_INR)/1000000 AS decimal(6,2)) AS varchar(100)) + ' INR Million' as total_revenue FROM fact_swiggy_orders 

-- Average Dish Price
SELECT dsh.Dish_Name, CAST(CAST(AVG(f.Price_INR) AS decimal(8,2)) AS varchar(100)) + ' INR' AS avg_dish_price FROM fact_swiggy_orders f
JOIN dim_dish dsh ON f.dish_id = dsh.dish_id
GROUP BY dsh.Dish_Name

-- Average Ratings
SELECT AVG(Rating) as avg_ratings FROM fact_swiggy_orders




-- Business Analysis

-- Monthly Order Trend Analysis
SELECT 
d.YEAR,
d.MONTH, 
d.MONTH_NAME, 
COUNT(f.Order_id) as total_orders,
CAST(CAST(SUM(f.Price_INR)/1000000 AS decimal(6,2)) AS varchar(100)) + ' INR Million' as total_revenue
FROM fact_swiggy_orders f
JOIN dim_date d
ON f.date_id = d.date_id
GROUP BY d.YEAR, d.MONTH, d.MONTH_NAME 
order by CAST(SUM(f.Price_INR)/1000000 AS decimal(6,2)) DESC


-- Quarterly Order Trend Analysis
SELECT 
d.YEAR,
d.QUARTER, 
COUNT(f.Order_id) as total_orders,
CAST(CAST(SUM(f.Price_INR)/1000000 AS decimal(6,2)) AS varchar(100)) + ' INR Million' as total_revenue
FROM fact_swiggy_orders f
JOIN dim_date d
ON f.date_id = d.date_id
GROUP BY d.YEAR, d.QUARTER
order by CAST(SUM(f.Price_INR)/1000000 AS decimal(6,2)) DESC

-- YEAR Order Trend Analysis
SELECT 
d.YEAR,
COUNT(f.Order_id) as total_orders,
CAST(CAST(SUM(f.Price_INR)/1000000 AS decimal(6,2)) AS varchar(100)) + ' INR Million' as total_revenue
FROM fact_swiggy_orders f
JOIN dim_date d
ON f.date_id = d.date_id
GROUP BY d.YEAR
order by CAST(SUM(f.Price_INR)/1000000 AS decimal(6,2)) DESC

-- DAY OF WEEK Order Trend Analysis
SELECT 
d.YEAR,
DATENAME(WEEKDAY, d.FULL_DATE) as weekday,
COUNT(f.Order_id) as total_orders,
CAST(CAST(SUM(f.Price_INR)/1000000 AS decimal(6,2)) AS varchar(100)) + ' INR Million' as total_revenue
FROM fact_swiggy_orders f
JOIN dim_date d
ON f.date_id = d.date_id
GROUP BY d.YEAR, DATENAME(WEEKDAY, d.FULL_DATE)
order by CAST(SUM(f.Price_INR)/1000000 AS decimal(6,2)) DESC

-- 	Top 10 cities by order volume
SELECT TOP 10 l.City, COUNT(f.Order_id) as total_order_volume FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.City
ORDER BY  COUNT(f.Order_id) DESC

-- 	Bottom 10 cities by order volume
SELECT TOP 10 l.City, COUNT(f.Order_id) as total_order_volume FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.City
ORDER BY  COUNT(f.Order_id)

--	Revenue contribution by states AND its percentage contribution
WITH total_revenue_cte AS (
SELECT SUM(price_INR) total_revenue FROM fact_swiggy_orders
),
state_wise_sales AS (
SELECT l.State, SUM(Price_INR) as total_sales_state_wise  FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.State)

SELECT *, 
CAST(100.0 * total_sales_state_wise/total_revenue AS decimal (4,2)) as contri_pct
FROM state_wise_sales s
CROSS JOIN total_revenue_cte t
ORDER BY 100.0 * total_sales_state_wise/total_revenue DESC



-- TOP 10 restaurants by orders
SELECT TOP 10 r.Restaurant_Name, COUNT(*) AS total_orders FROM fact_swiggy_orders f
JOIN dim_restaurant r
ON f.restaurant_id = r.restaurant_id
GROUP BY r.Restaurant_Name
ORDER BY count(*) DESC

--	Find top 3 most ordered dishes in each state
WITH state_wish_dish_sales AS (
SELECT 
l.State, dsh.Dish_Name, COUNT(order_id) as total_orders
FROM fact_swiggy_orders f
JOIN dim_location l
ON f.location_id = l.location_id
JOIN dim_dish dsh ON f.dish_id = f.dish_id
GROUP BY l.State, dsh.Dish_Name)

SELECT * FROM (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY State ORDER BY total_orders DESC) as rnk
FROM state_wish_dish_sales) data
WHERE rnk <=3;


--	Cuisine performance → Orders + Avg Rating
SELECT 
c.Category,
COUNT(*) AS total_orders,
CAST(AVG(f.Rating) AS decimal(5,2)) as avg_ratings
FROM fact_swiggy_orders f
JOIN dim_category c
ON f.category_id = c.category_id
GROUP BY c.Category
ORDER BY COUNT(*) DESC, AVG(f.Rating) DESC
/*
Customer Spending Insights
Buckets of customer spend:
	Under 100
	100–199
	200–299
	300–499
	500+
With total order distribution across these ranges.
*/
SELECT 
CASE
	WHEN Price_INR < 100 THEN 'Under - 100'
	WHEN Price_INR  BETWEEN 100 AND 199 THEN '100-199'
	WHEN Price_INR BETWEEN 200 AND 299 THEN '200-299'
	WHEN Price_INR BETWEEN 300 AND 499 THEN '300–499'
	ELSE '500+'	
END AS customer_bucket_spending,
COUNT(*) AS total_orders
FROM fact_swiggy_orders 
GROUP BY (
CASE
	WHEN Price_INR < 100 THEN 'Under - 100'
	WHEN Price_INR  BETWEEN 100 AND 199 THEN '100-199'
	WHEN Price_INR BETWEEN 200 AND 299 THEN '200-299'
	WHEN Price_INR BETWEEN 300 AND 499 THEN '300–499'
	ELSE '500+'	
END
)

--Rating Count Distribution
SELECT 
    rating,
    COUNT(*) AS rating_count
FROM fact_swiggy_orders
GROUP BY rating
ORDER BY rating;


--Cuisine(Category) Performance (Orders + Avg Rating)
SELECT 
    c.category,
    COUNT(*) AS total_orders,
    AVG(CONVERT(FLOAT, f.rating)) AS avg_rating
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.category
ORDER BY total_orders DESC;

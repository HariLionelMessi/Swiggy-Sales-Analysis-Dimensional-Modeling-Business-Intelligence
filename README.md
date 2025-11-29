# Swiggy Sales Analysis: Dimensional Modeling & Business Intelligence

Overview

This project focuses on performing a comprehensive data cleaning, dimensional modeling, and business analysis of a food delivery dataset (Swiggy Sales). The goal was to transform a large, single-table raw data source, containing 1.97 lakh records, into a clean, optimized Star Schema to enable efficient and insightful business intelligence (BI) reporting.

Technology Stack

    Database: SQL (T-SQL/Generic SQL used for the queries)

    Techniques: Data Cleaning, Dimensional Modeling (Star Schema), Common Table Expressions (CTE), Window Functions.

    Source Data: Single raw table (swiggy_data).

Project Stages and Methodology

1. Data Cleaning & Validation

The initial stage focused on ensuring data quality in the raw table.

    Null & Blank Check: Verified the absence of NULL or empty strings in critical dimension columns (State, City, Location, Category, etc.) .

Duplicate Removal: Identified and successfully removed 29 duplicate rows. This was achieved using the ROW_NUMBER() window function partitioned by all business-critical columns within a CTE, retaining one clean copy of each unique order .

2. Dimensional Modeling (Star Schema)

The core of the project involved transforming the data structure into an analytical schema to improve query performance and data clarity .

    Schema Design: A Star Schema was designed, separating descriptive data into dimensions and measurable data into a central fact table.

    Dimension Tables Created:

        dim_date (Order Date components: Year, Month, Quarter, Week, etc.).

        dim_location (State, City, Location).

        dim_restaurant (Restaurant Name).

        dim_category (Cuisine/Category).

        dim_dish (Dish Name).

    Fact Table Created:

        fact_swiggy_orders (Measures: Price_INR, Rating, Rating_Count, plus Foreign Keys linking to all dimension tables).

    Loading: Data was populated by inserting distinct records into the dimension tables and then using JOINs to resolve the foreign keys during the fact table loading process .
<img width="732" height="597" alt="image" src="https://github.com/user-attachments/assets/be7467b3-1897-4a32-8c3f-60aaa0b0f632" />

## Key Business Analysis & Insights

Over 10 complex queries were developed to extract actionable business insights from the optimized Star Schema.

1. Key Performance Indicators (KPIs)

Calculated core metrics for executive reporting:

    Total Orders, Total Revenue (in INR Million).

    Average Dish Price and Average Rating.

2. Advanced Analytical Queries

    Location Performance & Contribution: Calculated the revenue contribution percentage of each state against the total revenue, identifying key markets .

Top N Analysis (Window Functions): Identified the Top 3 most ordered dishes in each state using ROW_NUMBER() partitioned by State .

Customer Spending Segmentation: Grouped total orders into five distinct spending buckets (e.g., 'Under 100', '100-199', '500+') using CASE statements to analyze distribution patterns .

Temporal & Food Analysis: Queried monthly, quarterly, and day-of-week trends, in addition to identifying Top 10 cities and restaurants by order volume .

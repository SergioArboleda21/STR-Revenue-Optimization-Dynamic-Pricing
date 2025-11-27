USE [Airbnb_Property_Rental_Price]
GO

SELECT SUM(price) AS Sum_Price, city 
FROM [dbo].[train]
GROUP BY city
ORDER BY Sum_Price DESC;

/* Step 1: Create a Common Table Expression (CTE) to identify the Top 10 Cities 
by listing volume. This ensures we focus only on statistically significant markets.
*/
WITH TopCities AS (
    SELECT TOP 10 
        city, 
        COUNT(*) as listing_count
    FROM train
    WHERE city IS NOT NULL
    GROUP BY city
    ORDER BY listing_count DESC
),

/* Step 2: Select and Clean the data.
We join the raw data with our TopCities list to filter records.
We also handle missing values and cast data types.
*/
ProcessedListings AS (
    SELECT
        -- IDs
        t1.id AS listing_id,
        t1.host_id,

        -- Location (Cleaned)
        TRIM(t1.city) AS city,
        t1.neighbourhood_cleansed,
        t1.latitude,
        t1.longitude,

        -- Financials (Handle Nulls & Outliers)
        -- Exclude rows where Price is NULL later in the WHERE clause
        CAST(t1.price AS DECIMAL(10,2)) AS price, 
        
        -- Availability (Integer casting)
        ISNULL(t1.availability_30, 0) AS availability_30,
        ISNULL(t1.availability_365, 0) AS availability_365,

        -- Host Metrics (Date Standardization & Null Handling)
        CAST(t1.host_since AS DATE) AS host_since,
        CASE 
            WHEN t1.host_is_superhost = 't' THEN 1 
            ELSE 0 
        END AS is_superhost,

        -- Review Scores (Handle Missing Ratings)
        -- If a rating is missing, we default to NULL (or 0 if strictly required for math)
        t1.number_of_reviews,
        t1.review_scores_rating

    FROM train t1
    INNER JOIN TopCities t2 ON t1.city = t2.city -- Filter for only Top 10 cities
    WHERE 
        t1.price IS NOT NULL  -- Remove dirty data (listings with no price)
        AND t1.price > 0      -- Remove errors (free listings)
)

/* Step 3: Output the Final Cleaned Dataset */
SELECT * FROM ProcessedListings;

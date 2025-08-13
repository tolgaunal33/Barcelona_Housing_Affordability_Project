-- toruist housing data analysis for the step 3 
-- 3. Connecting STR to Rent Pressures
-- Question: Do areas with high STR growth/ density also show higher rent or faster rent growth?

-- AIRBNB and tourist housing data used

SELECT 
    neighbourhood_group_cleansed AS district_name,
    COUNT(*) AS airbnb_listing_count
FROM airbnb_listings_clean
GROUP BY neighbourhood_group_cleansed
ORDER BY airbnb_listing_count DESC;

SELECT 
    year,
    tourist_housing_est AS tourist_housing_units
FROM tourist_housing_city
WHERE year = 2023;



SELECT * FROM tourist_housing_city LIMIT 10;

SELECT * FROM tourist_housing_city
WHERE year IS NULL;

DELETE FROM tourist_housing_city
WHERE year IS NULL;



-- ✅ Step 1: Calculate STR (Tourist Housing) Yearly Growth (%)

SELECT 
    year,
    tourist_housing_est,
    LAG(tourist_housing_est) OVER (ORDER BY year) AS prev_year_est,
    ROUND(
        ((tourist_housing_est - LAG(tourist_housing_est) OVER (ORDER BY year)) 
         / LAG(tourist_housing_est) OVER (ORDER BY year)) * 100, 2
    ) AS yoy_growth_percent
FROM tourist_housing_city
ORDER BY year;


-- Indexing to Base Year (2015 = 100)
SELECT tourist_housing_est
FROM tourist_housing_city
WHERE year = 2015;

SELECT 
    year,
    tourist_housing_est,
    ROUND((tourist_housing_est / 13675.0) * 100, 2) AS index_2015_base
FROM tourist_housing_city
ORDER BY year;

-- 13,675 = the number of tourist housing units in 2015 (your base year)

-- So 2023 has 1.6877x more than 2015

-- Meaning: +68.77% growth over 8 years

-- "Since 2015, the number of licensed tourist housing units in Barcelona has grown by 68.77%, reaching 23,079 units in 2023."

-- ✅ Step 2: Calculate average rent per year across all districts

SELECT 
    year,
    ROUND(AVG(average_rent_price), 2) AS city_avg_rent
FROM rent_prices
WHERE territory_type = 'District'
GROUP BY year
ORDER BY year;

-- Rent YoY % Growth
WITH rent_by_year AS (
    SELECT 
        year,
        ROUND(AVG(average_rent_price), 2) AS city_avg_rent
    FROM rent_prices
    WHERE territory_type = 'District'
    GROUP BY year
)

SELECT 
    year,
    city_avg_rent,
    LAG(city_avg_rent) OVER (ORDER BY year) AS prev_rent,
    ROUND(
        ((city_avg_rent - LAG(city_avg_rent) OVER (ORDER BY year)) / LAG(city_avg_rent) OVER (ORDER BY year)) * 100,
        2
    ) AS yoy_rent_growth_percent
FROM rent_by_year
ORDER BY year;

-- Rent Index (Base Year = 2015)
SELECT ROUND(AVG(average_rent_price), 2)
FROM rent_prices
WHERE year = 2015 AND territory_type = 'District';  -- 723.50 2015 

WITH rent_by_year AS (
    SELECT 
        year,
        ROUND(AVG(average_rent_price), 2) AS city_avg_rent
    FROM rent_prices
    WHERE territory_type = 'District'
      AND year BETWEEN 2015 AND 2023
    GROUP BY year
)

SELECT 
    year,
    city_avg_rent,
    ROUND((city_avg_rent / 723.50) * 100, 2) AS rent_index_2015_base
FROM rent_by_year
ORDER BY year;

-- Rent YoY % Growth + Index (Base 2015 = 100)

WITH rent_by_year AS (
    SELECT 
        year,
        ROUND(AVG(average_rent_price), 2) AS city_avg_rent
    FROM rent_prices
    WHERE territory_type = 'District'
      AND year BETWEEN 2015 AND 2023
    GROUP BY year
)

SELECT 
    year,
    city_avg_rent,
    LAG(city_avg_rent) OVER (ORDER BY year) AS prev_rent,
    ROUND(
        ((city_avg_rent - LAG(city_avg_rent) OVER (ORDER BY year)) / LAG(city_avg_rent) OVER (ORDER BY year)) * 100,
        2
    ) AS yoy_rent_growth_percent,
    ROUND((city_avg_rent / 723.50) * 100, 2) AS rent_index_2015_base
FROM rent_by_year
ORDER BY year;


-- Combined Rent + STR Growth Table (2015–2023)

WITH rent_by_year AS (
    SELECT 
        year,
        ROUND(AVG(average_rent_price), 2) AS city_avg_rent
    FROM rent_prices
    WHERE territory_type = 'District'
      AND year BETWEEN 2015 AND 2023
    GROUP BY year
),

rent_growth AS (
    SELECT 
        year,
        city_avg_rent,
        LAG(city_avg_rent) OVER (ORDER BY year) AS prev_rent,
        ROUND(
            ((city_avg_rent - LAG(city_avg_rent) OVER (ORDER BY year)) / LAG(city_avg_rent) OVER (ORDER BY year)) * 100,
            2
        ) AS yoy_rent_growth_percent,
        ROUND((city_avg_rent / 723.50) * 100, 2) AS rent_index_2015_base
    FROM rent_by_year
),

str_growth AS (
    SELECT 
        year,
        tourist_housing_est,
        LAG(tourist_housing_est) OVER (ORDER BY year) AS prev_str,
        ROUND(
            ((tourist_housing_est - LAG(tourist_housing_est) OVER (ORDER BY year)) / LAG(tourist_housing_est) OVER (ORDER BY year)) * 100,
            2
        ) AS yoy_str_growth_percent,
        ROUND((tourist_housing_est / 13675.0) * 100, 2) AS str_index_2015_base
    FROM tourist_housing_city
    WHERE year BETWEEN 2015 AND 2023
)

SELECT 
    r.year,
    r.city_avg_rent,
    r.yoy_rent_growth_percent,
    r.rent_index_2015_base,
    s.tourist_housing_est,
    s.yoy_str_growth_percent,
    s.str_index_2015_base
FROM rent_growth r
JOIN str_growth s ON r.year = s.year
ORDER BY r.year;

-- “Do neighborhoods with more Airbnb listings also have higher rent levels?”
-- How many Airbnb listings are there per neighborhood? (Airbnb Listing Count by Neighborhood)

SELECT 
    neighbourhood_cleansed AS neighbourhood_name,
    COUNT(*) AS airbnb_listing_count
FROM airbnb_listings_clean
GROUP BY neighbourhood_cleansed
ORDER BY airbnb_listing_count DESC;

--  Get Rent Prices per Neighborhood (2024)
SELECT 
    territory AS neighbourhood_name,
    ROUND(AVG(average_rent_price), 2) AS avg_rent_2024
FROM rent_prices
WHERE territory_type = 'Neighbourhood'
  AND year = 2024
GROUP BY territory;

-- Airbnb
SELECT DISTINCT neighbourhood_cleansed AS neighbourhood_name
FROM airbnb_listings_clean;

-- Rent 
SELECT DISTINCT territory AS neighbourhood_name
FROM rent_prices
WHERE territory_type = 'Neighbourhood'
  AND year = 2024;

-- Neighborhoods in Airbnb but NOT in Rent
SELECT DISTINCT a.neighbourhood_cleansed AS neighbourhood_name
FROM airbnb_listings_clean a
LEFT JOIN (
    SELECT DISTINCT territory 
    FROM rent_prices 
    WHERE territory_type = 'Neighbourhood' AND year = 2024
) r ON a.neighbourhood_cleansed = r.territory
WHERE r.territory IS NULL;

-- Neighborhoods in Rent but NOT in Airbnb
SELECT DISTINCT r.territory AS neighbourhood_name
FROM rent_prices r
LEFT JOIN (
    SELECT DISTINCT neighbourhood_cleansed 
    FROM airbnb_listings_clean
) a ON r.territory = a.neighbourhood_cleansed
WHERE r.territory_type = 'Neighbourhood'
  AND r.year = 2024
  AND a.neighbourhood_cleansed IS NULL;

-- SQL to count rent records per neighborhood for 2024:
SELECT 
    territory AS neighbourhood_name,
    COUNT(*) AS rent_records_2024
FROM rent_prices
WHERE territory_type = 'Neighbourhood'
  AND year = 2024
GROUP BY territory
ORDER BY rent_records_2024;

-- SQL: Average Rent in 2024 per Neighborhood
SELECT 
    territory AS neighbourhood_name,
    ROUND(AVG(average_rent_price), 2) AS avg_rent_2024
FROM rent_prices
WHERE territory_type = 'Neighbourhood'
  AND year = 2024
GROUP BY territory
ORDER BY avg_rent_2024 DESC;


-- 
-- Airbnb listing counts per neighborhood
WITH airbnb_counts AS (
    SELECT 
        neighbourhood_cleansed AS neighbourhood_name,
        COUNT(*) AS airbnb_listing_count
    FROM airbnb_listings_clean
    GROUP BY neighbourhood_cleansed
),

-- Average rent price for 2024 per neighborhood
rent_2024 AS (
    SELECT 
        territory AS neighbourhood_name,
        ROUND(AVG(average_rent_price), 2) AS avg_rent_2024
    FROM rent_prices
    WHERE territory_type = 'Neighbourhood'
      AND year = 2024
    GROUP BY territory
)

-- Final join: neighborhood-level STR vs Rent
SELECT 
    r.neighbourhood_name,
    r.avg_rent_2024,
    a.airbnb_listing_count
FROM rent_2024 r
LEFT JOIN airbnb_counts a ON r.neighbourhood_name = a.neighbourhood_name
ORDER BY r.avg_rent_2024 DESC;

-- 
-- Step 1: AVG Rent (2024) overall
SELECT 
    ROUND(AVG(avg_rent), 2) AS overall_avg_rent_2024
FROM (
    SELECT 
        territory AS neighbourhood_name,
        AVG(average_rent_price) AS avg_rent
    FROM rent_prices
    WHERE territory_type = 'Neighbourhood'
      AND year = 2024
    GROUP BY territory
) AS rent_avg;

-- Step 2: Airbnb Listing Count
SELECT 
    ROUND(AVG(listing_count), 2) AS avg_airbnb_listings_per_neighbourhood
FROM (
    SELECT 
        neighbourhood_cleansed AS neighbourhood_name,
        COUNT(*) AS listing_count
    FROM airbnb_listings_clean
    GROUP BY neighbourhood_cleansed
) AS airbnb_counts;

-- ✅ Final SQL Query: Airbnb Listing Count vs Rent per District (2024)
-- Step 1: Count Airbnb listings per district
WITH airbnb_counts AS (
    SELECT 
        neighbourhood_group_cleansed AS district_name,
        COUNT(*) AS airbnb_listing_count
    FROM airbnb_listings_clean
    GROUP BY neighbourhood_group_cleansed
),

-- Step 2: Average rent per district in 2024
rent_2024 AS (
    SELECT 
        territory AS district_name,
        ROUND(AVG(average_rent_price), 2) AS avg_rent_2024
    FROM rent_prices
    WHERE territory_type = 'District'
      AND year = 2024
    GROUP BY territory
)

-- Step 3: Join both tables
SELECT 
    r.district_name,
    r.avg_rent_2024,
    a.airbnb_listing_count
FROM rent_2024 r
LEFT JOIN airbnb_counts a ON r.district_name = a.district_name
ORDER BY r.avg_rent_2024 DESC;


-- ✅ Step 1: Overall Avg Rent per District (2024)
SELECT 
    ROUND(AVG(avg_rent), 2) AS overall_avg_rent_2024
FROM (
    SELECT 
        territory AS district_name,
        AVG(average_rent_price) AS avg_rent
    FROM rent_prices
    WHERE territory_type = 'District'
      AND year = 2024
    GROUP BY territory
) AS rent_avg;

-- ✅ Step 2: Avg Airbnb Listings per District (2024)
SELECT 
    ROUND(AVG(listing_count), 2) AS avg_airbnb_listings_per_district
FROM (
    SELECT 
        neighbourhood_group_cleansed AS district_name,
        COUNT(*) AS listing_count
    FROM airbnb_listings_clean
    GROUP BY neighbourhood_group_cleansed
) AS airbnb_counts;

-- ✅ Step 1: SQL Join – Neighborhood Airbnb Listings + Rent

-- Count Airbnb listings per neighborhood
WITH airbnb_counts AS (
    SELECT 
        neighbourhood_cleansed AS neighbourhood_name,
        COUNT(*) AS airbnb_listing_count
    FROM airbnb_listings_clean
    GROUP BY neighbourhood_cleansed
),

-- Average rent per neighborhood in 2024
rent_2024 AS (
    SELECT 
        territory AS neighbourhood_name,
        ROUND(AVG(average_rent_price), 2) AS avg_rent_2024
    FROM rent_prices
    WHERE territory_type = 'Neighbourhood'
      AND year = 2024
    GROUP BY territory
)

-- Join
SELECT 
    r.neighbourhood_name,
    r.avg_rent_2024,
    a.airbnb_listing_count
FROM rent_2024 r
LEFT JOIN airbnb_counts a ON r.neighbourhood_name = a.neighbourhood_name
ORDER BY r.avg_rent_2024 DESC;


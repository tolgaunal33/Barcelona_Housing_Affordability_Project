# 🎯 Chapter: Short-Term Renting Growth
-- How STRs have expanded across time and space in Barcelona

SELECT * FROM tourist_housing_city;

# ✅ Step 1A: Get Tourist Housing Growth (City Level)
SELECT 
    CAST(year AS UNSIGNED) AS year,
    tourist_housing_est
FROM 
    tourist_housing_city
WHERE 
    year IS NOT NULL
ORDER BY 
    year ASC;

# ✅ Step 2A: Count Listings per Neighborhood (from MySQL)
SELECT 
    neighbourhood_cleansed AS neighbourhood,
    COUNT(*) AS num_airbnb_listings
FROM 
    airbnb_listings_clean
GROUP BY 
    neighbourhood_cleansed
ORDER BY 
    num_airbnb_listings DESC;
    
# ✅ Step 2B: Get Housing Units Per Neighborhood (for 2025)

SELECT 
    territory AS neighbourhood,
    SUM(num_premises) AS housing_units_2025
FROM 
    housing_stock
WHERE 
    year = 2025
    AND main_use_destination = 'Housing'
    AND territory_type = 'Neighbourhood'
GROUP BY 
    territory
ORDER BY 
    housing_units_2025 DESC;


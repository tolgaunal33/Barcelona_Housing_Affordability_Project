-- OCCUPANCY TENURE NEW 

-- ✅ Step 1B: First SQL Query — Trend of Occupancy Status (1981–2021) (MUNICIPAL) 

SELECT 
    year,
    occupancy_status,
    SUM(num_housing_units) AS total_units
FROM 
    housing_occupancy
WHERE 
    territory_type = 'Municipality'
GROUP BY 
    year, occupancy_status
ORDER BY 
    year, occupancy_status;
    
    
-- vanct and other aggregated 
SELECT 
    year,
    CASE 
        WHEN occupancy_status = 'Main' THEN 'Main'
        ELSE 'Not main'
    END AS grouped_status,
    SUM(num_housing_units) AS total_units
FROM 
    housing_occupancy
WHERE 
    territory_type = 'Municipality'
GROUP BY 
    year, grouped_status
ORDER BY 
    year, grouped_status;


-- tenure counts 

SELECT 
    year,
    tenure_regime,
    SUM(num_main_homes) AS total_main_homes
FROM 
    tenure_data
WHERE 
    territory_type = 'Municipality'
GROUP BY 
    year, tenure_regime
ORDER BY 
    year, tenure_regime;
    
   -- ✅ Step 2G.1: Prep the 2021 Tenure Data
SELECT 
    territory AS neighbourhood,
    tenure_regime,
    SUM(num_main_homes) AS total_main_homes
FROM 
    tenure_data
WHERE 
    year = 2021
    AND territory_type = 'Neighborhood'
GROUP BY 
    territory, tenure_regime
ORDER BY 
    territory, tenure_regime;
    
-- STR density per neighborhood
-- ✅ Step 1: Count Listings per Neighborhood (in SQL)
SELECT 
    neighbourhood_cleansed AS neighbourhood,
    COUNT(*) AS num_airbnb_listings
FROM 
    airbnb_listings_clean
GROUP BY 
    neighbourhood_cleansed
ORDER BY 
    num_airbnb_listings DESC;
    
    -- ✅ Step 2: Aggregate Population per Neighborhood (2021 only)
SELECT 
    neighborhood_name AS neighbourhood,
    SUM(population) AS population_2021
FROM 
    population_data
WHERE 
    year = 2021
GROUP BY 
    neighborhood_name
ORDER BY 
    population_2021 DESC;

-- ✅ Step 3: Get Housing Units per Neighborhood (2021 only, Housing use only)
SELECT 
    territory AS neighbourhood,
    SUM(num_premises) AS housing_units_2021
FROM 
    housing_stock
WHERE 
    year = 2021
    AND main_use_destination = 'Housing'
    AND territory_type = 'Neighbourhood'
GROUP BY 
    territory
ORDER BY 
    housing_units_2021 DESC;


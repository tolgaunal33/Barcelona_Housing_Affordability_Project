# 🎯 Chapter: Connecting STR to Rent Pressures
 -- Main question:
   -- Do areas with more STRs — or faster STR growth — also experience higher or faster-growing rents?
   
SELECT * FROM rent_prices;

# ✅ Step 1A: Join Tourist Housing + Rent Data (City-Level)
SELECT 
    CAST(thc.year AS UNSIGNED) AS year,
    thc.tourist_housing_est,
    AVG(rp.average_rent_price) AS avg_rent_city
FROM 
    tourist_housing_city AS thc
JOIN 
    rent_prices AS rp
    ON CAST(thc.year AS UNSIGNED) = rp.year
WHERE 
    rp.territory_type = 'Municipality'
GROUP BY 
    year, tourist_housing_est
ORDER BY 
    year;

# ✅ Step 2: STR Density vs Rent Level (Neighborhood, 2025)
 -- We’ll now explore:
  -- Are neighborhoods with higher STR density also more expensive to rent in?
  
SELECT 
    territory AS neighbourhood,
    AVG(average_rent_price) AS avg_rent_2024
FROM 
    rent_prices
WHERE 
    year = 2024
    AND territory_type = 'Neighbourhood'
GROUP BY 
    territory;
    
    
 ## ✅ SQL for Median Rent per Neighborhood (2024)   
SELECT neighbourhood, 
       SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(average_rent_price ORDER BY average_rent_price), ',', FLOOR(COUNT(*)/2)+1), ',', -1) AS median_rent_2024
FROM (
    SELECT 
        territory AS neighbourhood,
        average_rent_price
    FROM 
        rent_prices
    WHERE 
        year = 2024
        AND territory_type = 'Neighbourhood'
) AS sub
GROUP BY neighbourhood;

  
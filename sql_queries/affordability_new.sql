# 🎯 Chapter: Is Barcelona Really Facing an Affordability Crisis?
 -- Main question:
  -- Did rents increase faster than incomes from 2015 to 2021, making the city less affordable?

# ✅ Step 1A: SQL – Prepare City-Level Rent & Income (2015–2021)
SELECT 
    year,
    AVG(average_rent_price) AS avg_rent_city
FROM 
    rent_prices
WHERE 
    territory_type = 'Municipality'
    AND year BETWEEN 2015 AND 2021
GROUP BY 
    year
ORDER BY 
    year;
    
-- 🧾 Part 2: Income (City-level proxy = district average)
SELECT 
    year,
    AVG(income_eur) AS avg_income_city
FROM 
    income_data
WHERE 
    year BETWEEN 2015 AND 2021
GROUP BY 
    year
ORDER BY 
    year;
    
    
# ✅ Step 2: Neighborhood-Level Affordability Index (2021)
-- 🧾 SQL 1: Rent per Neighborhood (2021)

SELECT 
    territory AS neighborhood,
    AVG(average_rent_price) AS avg_rent_2021
FROM 
    rent_prices
WHERE 
    territory_type = 'Neighbourhood'
    AND year = 2021
GROUP BY 
    territory;

-- 🧾 SQL 2: Income per Neighborhood (2021)
SELECT 
    neighborhood_name AS neighborhood,
    AVG(income_eur) AS avg_income_2021
FROM 
    income_data
WHERE 
    year = 2021
GROUP BY 
    neighborhood_name;
    
    
SELECT * FROM barcelona_master_2021;

SELECT neighbourhood, COUNT(*) 
FROM barcelona_master_2021
GROUP BY neighbourhood
HAVING COUNT(*) > 1;


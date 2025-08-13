SHOW FULL TABLES IN barcelona_housing_project
WHERE TABLE_TYPE = 'VIEW';

SHOW FULL TABLES IN barcelona_housing_project;

SELECT 'airbnb_summary_2025' AS view_name, COUNT(*) AS row_count FROM airbnb_summary_2025
UNION ALL
SELECT 'final_risk_zones', COUNT(*) FROM final_risk_zones
UNION ALL
SELECT 'income_2021_neighbourhood', COUNT(*) FROM income_2021_neighbourhood
UNION ALL
SELECT 'population_2021_neighbourhood', COUNT(*) FROM population_2021_neighbourhood
UNION ALL
SELECT 'rent_growth_2015_2021', COUNT(*) FROM rent_growth_2015_2021
UNION ALL
SELECT 'rent_prices_2021_neighbourhood', COUNT(*) FROM rent_prices_2021_neighbourhood
UNION ALL
SELECT 'str_listings_2024', COUNT(*) FROM str_listings_2024
UNION ALL
SELECT 'unemployment_2020_neighbourhood', COUNT(*) FROM unemployment_2020_neighbourhood
UNION ALL
SELECT 'unemployment_2021_neighbourhood', COUNT(*) FROM unemployment_2021_neighbourhood
UNION ALL
SELECT 'vulnerability_2021_neighbourhood', COUNT(*) FROM vulnerability_2021_neighbourhood
UNION ALL
SELECT 'vulnerability_raw_2021', COUNT(*) FROM vulnerability_raw_2021
UNION ALL
SELECT 'vulnerability_vs_rent_growth', COUNT(*) FROM vulnerability_vs_rent_growth
UNION ALL
SELECT 'vulnerability_vs_str_2021', COUNT(*) FROM vulnerability_vs_str_2021;


SHOW COLUMNS
FROM housing_stock;

WITH pop AS (
  SELECT 
    neighborhood_name AS neighbourhood,
    year,
    SUM(population) AS total_population
  FROM population_data
  WHERE year IN (2009, 2021)
  GROUP BY neighborhood_name, year
),
pop_pivot AS (
  SELECT 
    neighbourhood,
    MAX(CASE WHEN year = 2009 THEN total_population END) AS population_2009,
    MAX(CASE WHEN year = 2021 THEN total_population END) AS population_2021
  FROM pop
  GROUP BY neighbourhood
),
housing AS (
  SELECT 
    territory AS neighbourhood,
    year,
    SUM(num_premises) AS housing_units
  FROM housing_stock
  WHERE year IN (2009, 2021)
    AND main_use_destination = 'Housing'
  GROUP BY territory, year
),
housing_pivot AS (
  SELECT 
    neighbourhood,
    MAX(CASE WHEN year = 2009 THEN housing_units END) AS housing_2009,
    MAX(CASE WHEN year = 2021 THEN housing_units END) AS housing_2021
  FROM housing
  GROUP BY neighbourhood
)

SELECT 
  p.neighbourhood,
  population_2009,
  population_2021,
  ROUND((population_2021 - population_2009) * 100.0 / NULLIF(population_2009, 0), 2) AS population_growth_pct,
  h.housing_2009,
  h.housing_2021,
  ROUND((housing_2021 - housing_2009) * 100.0 / NULLIF(housing_2009, 0), 2) AS housing_growth_pct
FROM pop_pivot p
JOIN housing_pivot h USING (neighbourhood)
ORDER BY population_growth_pct DESC;


WITH housing_totals AS (
  SELECT 
    year,
    occupancy_status,
    SUM(num_housing_units) AS units
  FROM housing_occupancy
  WHERE territory = 'Barcelona'
    AND year IN (2001, 2021)
  GROUP BY year, occupancy_status
),
pivot AS (
  SELECT
    year,
    MAX(CASE WHEN occupancy_status IN ('Main') THEN units ELSE 0 END) AS main_units,
    SUM(units) AS total_units
  FROM housing_totals
  GROUP BY year
)

SELECT 
  year,
  main_units,
  total_units,
  ROUND(main_units * 100.0 / total_units, 2) AS main_residence_share_pct
FROM pivot
ORDER BY year;

SELECT * FROM housing_occupancy;



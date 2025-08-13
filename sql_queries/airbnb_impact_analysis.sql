-- HUT Licence ANALYSIS 
-- 🔍 “Where has short-term renting grown the most over time?”
-- Get Number of Licenses by Year & District
SELECT 
  year,
  district_name,
  COUNT(*) AS num_hut_licenses
FROM hut_licenses_clean
GROUP BY year, district_name
ORDER BY district_name, year;

-- 🔥 “Which district grew the most?”
SELECT 
  district_name,
  MIN(year) AS first_year,
  MAX(year) AS last_year,
  SUM(num_hut_licenses) AS total_licenses
FROM (
    SELECT 
      year,
      district_name,
      COUNT(*) AS num_hut_licenses
    FROM hut_licenses_clean
    GROUP BY year, district_name
) t
GROUP BY district_name
ORDER BY total_licenses DESC;

-- Cumulative SUM 
WITH yearly_counts AS (
    SELECT 
        year,
        district_name,
        COUNT(*) AS num_hut_licenses
    FROM hut_licenses_clean
    GROUP BY year, district_name
)
SELECT 
    year,
    district_name,
    num_hut_licenses,
    SUM(num_hut_licenses) OVER (
        PARTITION BY district_name 
        ORDER BY year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_licenses
FROM yearly_counts
ORDER BY district_name, year;

-- Neighbourhood 
SELECT 
  year,
  neighbourhood_name,
  COUNT(*) AS num_hut_licenses
FROM hut_licenses_clean
GROUP BY year, neighbourhood_name
ORDER BY neighbourhood_name, year;


--  🔥 “Which neighbourhood grew the most?”
SELECT 
  neighbourhood_name,
  MIN(year) AS first_year,
  MAX(year) AS last_year,
  SUM(num_hut_licenses) AS total_licenses
FROM (
    SELECT 
      year,
      neighbourhood_name,
      COUNT(*) AS num_hut_licenses
    FROM hut_licenses_clean
    GROUP BY year, neighbourhood_name
) t
GROUP BY neighbourhood_name
ORDER BY total_licenses DESC
LIMIT 20;

-- Cumulative SUM Neighbourhood
WITH yearly_counts AS (
    SELECT 
        year,
        neighbourhood_name,
        COUNT(*) AS num_hut_licenses
    FROM hut_licenses_clean
    GROUP BY year, neighbourhood_name
)
SELECT 
    year,
    neighbourhood_name,
    num_hut_licenses,
    SUM(num_hut_licenses) OVER (
        PARTITION BY neighbourhood_name 
        ORDER BY year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_licenses
FROM yearly_counts
ORDER BY neighbourhood_name, year;

SELECT * FROM airbnb_listings_clean;
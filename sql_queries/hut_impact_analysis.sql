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

-- 🔥🔥🔥🔥    Are Rents rising faster in those areas?  🔥 🔥 🔥 🔥 
-- HUT growth vs Rent Growth 
SELECT
  r.year,
  r.neighbourhood,
  r.avg_rent_price,
  h.num_hut_licenses
FROM (
  SELECT
    year,
    territory AS neighbourhood,
    ROUND(AVG(average_rent_price), 2) AS avg_rent_price
  FROM rent_prices
  WHERE territory_type = 'Neighbourhood'
  GROUP BY year, territory
) r
LEFT JOIN (
  SELECT
    year,
    neighbourhood_name AS neighbourhood,
    COUNT(*) AS num_hut_licenses
  FROM hut_licenses_clean
  GROUP BY year, neighbourhood_name
) h
ON r.year = h.year AND r.neighbourhood = h.neighbourhood;

-- tables check 
-- HUT lisanslarındaki benzersiz mahalle isimleri
SELECT DISTINCT neighbourhood_name 
FROM hut_licenses_clean 
ORDER BY neighbourhood_name;

-- Kira fiyatlarındaki benzersiz mahalle isimleri (territory alanı)
SELECT DISTINCT territory 
FROM rent_prices 
WHERE territory_type = 'neighbourhood' 
ORDER BY territory;

-- HUT lisanslarının yıl aralığı
SELECT MIN(year), MAX(year) FROM hut_licenses_clean;

-- Kira fiyatlarının yıl aralığı
SELECT MIN(year), MAX(year) FROM rent_prices;

-- HUT lisanslarında eksik mahalle ismi olan kayıtlar
SELECT COUNT(*) 
FROM hut_licenses_clean 
WHERE neighbourhood_name IS NULL OR neighbourhood_name = '';

-- Kira fiyatlarında mahalle tipindeki eksik kayıtlar
SELECT COUNT(*) 
FROM rent_prices 
WHERE territory IS NULL OR territory = '' AND territory_type = 'neighbourhood';


-- ✅ Final SQL Query (avg rent + HUT licenses + cumulative)

WITH 
hut_aggregated AS (
    SELECT 
        neighbourhood_name,
        year,
        COUNT(DISTINCT generalitat_register_number) AS license_count
    FROM 
        hut_licenses_clean
    WHERE 
        neighbourhood_name IS NOT NULL 
        AND neighbourhood_name != ''
    GROUP BY 
        neighbourhood_name, year
),

rents_prepared AS (
    SELECT 
        territory AS neighbourhood_name,
        year,
        AVG(average_rent_price) AS avg_rent_price
    FROM 
        rent_prices
    WHERE 
        territory_type = 'neighbourhood'
        AND territory IS NOT NULL
        AND territory != ''
    GROUP BY 
        territory, year
)

SELECT 
    r.neighbourhood_name,
    r.year,
    r.avg_rent_price,
    COALESCE(h.license_count, 0) AS license_count,
    COALESCE(
        (SELECT SUM(license_count) 
         FROM hut_aggregated 
         WHERE neighbourhood_name = r.neighbourhood_name AND year <= r.year),
        0
    ) AS cumulative_licenses
FROM 
    rents_prepared r
LEFT JOIN 
    hut_aggregated h ON r.neighbourhood_name = h.neighbourhood_name AND r.year = h.year
ORDER BY 
    r.neighbourhood_name, r.year;


# FINAL RISK ZONES (POWER BI)
CREATE OR REPLACE VIEW airbnb_summary_2025 AS
SELECT
    neighbourhood_cleansed AS neighborhood,
    COUNT(*) AS airbnb_count,
    AVG(latitude) AS avg_latitude,
    AVG(longitude) AS avg_longitude
FROM airbnb_listings
GROUP BY neighbourhood_cleansed;



CREATE OR REPLACE VIEW rent_prices_2021_neighbourhood AS
SELECT
    territory AS neighborhood,
    AVG(average_rent_price) AS avg_rent_2021
FROM rent_prices
WHERE year = 2021
  AND territory_type = 'neighbourhood'
GROUP BY territory;

SELECT * FROM rent_prices_2021_neighbourhood;

###### 
CREATE OR REPLACE VIEW final_risk_zones AS
SELECT
    a.neighborhood,
    a.airbnb_count,
    a.avg_latitude,
    a.avg_longitude,
    r.avg_rent_2021,
    v.vulnerability_score,
    v.income_score,
    v.unemployment_score
FROM airbnb_listings a
JOIN (
    SELECT
        neighbourhood_cleansed AS neighborhood,
        COUNT(*) AS airbnb_count,
        AVG(latitude) AS avg_latitude,
        AVG(longitude) AS avg_longitude
    FROM airbnb_listings
    GROUP BY neighbourhood_cleansed
) a ON a.neighborhood = a.neighborhood
LEFT JOIN rent_prices_2021_neighbourhood r
    ON LOWER(a.neighborhood) = LOWER(r.neighborhood)
LEFT JOIN vulnerability_2021_neighbourhood v
    ON TRIM(LOWER(a.neighborhood)) = TRIM(LOWER(REPLACE(v.neighbourhood, '-', ' ')));

    
SELECT * FROM final_risk_zones;

SELECT *
FROM final_risk_zones
WHERE neighborhood LIKE '%Poble Sec%';

SELECT *
FROM income_data
WHERE LOWER(neighborhood_name) LIKE '%poble sec%'
  AND year = 2021;

SELECT *
FROM unemployed_data
WHERE LOWER(territory) LIKE '%sec%'
  AND territory_type = 'neighbourhood';
  
SELECT * FROM unemployed_data;

SELECT DISTINCT
  TRIM(LOWER(neighbourhood_cleansed)) AS airbnb_name
FROM airbnb_listings
ORDER BY 1;

SELECT DISTINCT
  TRIM(LOWER(REPLACE(neighbourhood, '-', ' '))) AS vuln_name
FROM vulnerability_2021_neighbourhood
ORDER BY 1;

-- update the view after fixin vulnerability_2021
CREATE OR REPLACE VIEW final_risk_zones AS
SELECT
    a.neighborhood,
    a.airbnb_count,
    a.avg_latitude,
    a.avg_longitude,
    r.avg_rent_2021,
    v.vulnerability_score,
    v.income_score,
    v.unemployment_score
FROM airbnb_summary_2025 a
LEFT JOIN rent_prices_2021_neighbourhood r
    ON TRIM(LOWER(a.neighborhood)) = TRIM(LOWER(r.neighborhood))
LEFT JOIN vulnerability_2021_neighbourhood v
    ON TRIM(LOWER(a.neighborhood)) = TRIM(LOWER(REPLACE(SUBSTRING_INDEX(v.neighbourhood, '-', 1), '-', ' ')));

SELECT * FROM final_risk_zones;

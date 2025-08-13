-- 3. Connecting STR to Rent Pressures
-- Question: Do areas with high STR growth/ density also show higher rent or faster rent growth?

-- CANCELLED BECAUSE OF HUT COUNTS 

-- Get total HUT count per year & neighbourhood (YoY) GROWTH
WITH yearly_huts AS (
    SELECT 
        year,
        neighbourhood_name,
        COUNT(*) AS yearly_count
    FROM hut_licenses_clean
    WHERE neighbourhood_name IS NOT NULL
    GROUP BY year, neighbourhood_name
),

cumulative_huts AS (
    SELECT 
        year,
        neighbourhood_name,
        SUM(yearly_count) OVER (
            PARTITION BY neighbourhood_name 
            ORDER BY year
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_licenses
    FROM yearly_huts
),

yoy_growth AS (
    SELECT 
        year,
        neighbourhood_name,
        cumulative_licenses,
        LAG(cumulative_licenses) OVER (
            PARTITION BY neighbourhood_name 
            ORDER BY year
        ) AS prev_cumulative
    FROM cumulative_huts
)

SELECT 
    year,
    neighbourhood_name,
    cumulative_licenses,
    prev_cumulative,
    ROUND(((cumulative_licenses - prev_cumulative) / prev_cumulative) * 100, 2) AS yoy_growth_percent,
    CASE 
        WHEN prev_cumulative < 4 THEN TRUE 
        ELSE FALSE 
    END AS low_start_flag
FROM yoy_growth
WHERE prev_cumulative IS NOT NULL
ORDER BY neighbourhood_name, year;

-- YoY Rent Growth

WITH yearly_rent AS (
    SELECT 
        year,
        territory AS neighbourhood_name,
        ROUND(AVG(average_rent_price), 2) AS avg_rent_year
    FROM rent_prices
    WHERE 
        territory_type = 'Neighbourhood'
        AND territory IS NOT NULL
    GROUP BY territory, year
),

yoy_rent_growth AS (
    SELECT 
        year,
        neighbourhood_name,
        avg_rent_year,
        LAG(avg_rent_year) OVER (
            PARTITION BY neighbourhood_name 
            ORDER BY year
        ) AS prev_avg_rent
    FROM yearly_rent
)

SELECT 
    year,
    neighbourhood_name,
    avg_rent_year,
    prev_avg_rent,
    ROUND(((avg_rent_year - prev_avg_rent) / prev_avg_rent) * 100, 2) AS yoy_rent_growth_percent,
    CASE 
        WHEN prev_avg_rent < 200 THEN TRUE 
        ELSE FALSE 
    END AS low_start_flag
FROM yoy_rent_growth
WHERE prev_avg_rent IS NOT NULL
ORDER BY neighbourhood_name, year;

-- Joining STR and Rent YoY growth -- 
WITH str_yoy_growth AS (
    SELECT 
        year,
        LOWER(neighbourhood_name) AS neighbourhood_key,
        neighbourhood_name,
        cumulative_licenses,
        prev_cumulative,
        ROUND(((cumulative_licenses - prev_cumulative) / prev_cumulative) * 100, 2) AS yoy_str_growth_percent,
        CASE 
            WHEN prev_cumulative < 5 THEN TRUE 
            ELSE FALSE 
        END AS str_low_start_flag
    FROM (
        SELECT 
            year,
            neighbourhood_name,
            cumulative_licenses,
            LAG(cumulative_licenses) OVER (
                PARTITION BY neighbourhood_name 
                ORDER BY year
            ) AS prev_cumulative
        FROM (
            SELECT 
                year,
                neighbourhood_name,
                SUM(COUNT(*)) OVER (PARTITION BY neighbourhood_name ORDER BY year) AS cumulative_licenses
            FROM hut_licenses_clean
            WHERE neighbourhood_name IS NOT NULL
            GROUP BY year, neighbourhood_name
        ) AS cumulative_data
    ) AS growth_data
    WHERE prev_cumulative IS NOT NULL
),

rent_yoy_growth AS (
    SELECT 
        year,
        LOWER(territory) AS neighbourhood_key,
        territory AS neighbourhood_name,
        ROUND(AVG(average_rent_price), 2) AS avg_rent_year,
        LAG(ROUND(AVG(average_rent_price), 2)) OVER (
            PARTITION BY territory ORDER BY year
        ) AS prev_avg_rent
    FROM rent_prices
    WHERE territory_type = 'Neighbourhood' AND territory IS NOT NULL
    GROUP BY territory, year
),

rent_yoy_final AS (
    SELECT 
        year,
        neighbourhood_key,
        neighbourhood_name,
        avg_rent_year,
        prev_avg_rent,
        ROUND(((avg_rent_year - prev_avg_rent) / prev_avg_rent) * 100, 2) AS yoy_rent_growth_percent,
        CASE 
            WHEN prev_avg_rent < 300 THEN TRUE 
            ELSE FALSE 
        END AS rent_low_start_flag
    FROM rent_yoy_growth
    WHERE prev_avg_rent IS NOT NULL
)

-- FULL OUTER JOIN simulation using UNION of LEFT + RIGHT JOINs
SELECT 
    COALESCE(s.year, r.year) AS year,
    COALESCE(s.neighbourhood_name, r.neighbourhood_name) AS neighbourhood_name,
    s.yoy_str_growth_percent,
    r.yoy_rent_growth_percent,
    s.str_low_start_flag,
    r.rent_low_start_flag
FROM str_yoy_growth s
LEFT JOIN rent_yoy_final r 
  ON s.year = r.year AND s.neighbourhood_key = r.neighbourhood_key

UNION

SELECT 
    COALESCE(s.year, r.year) AS year,
    COALESCE(s.neighbourhood_name, r.neighbourhood_name) AS neighbourhood_name,
    s.yoy_str_growth_percent,
    r.yoy_rent_growth_percent,
    s.str_low_start_flag,
    r.rent_low_start_flag
FROM rent_yoy_final r
LEFT JOIN str_yoy_growth s 
  ON s.year = r.year AND s.neighbourhood_key = r.neighbourhood_key

ORDER BY neighbourhood_name, year;






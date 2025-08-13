-- 4. Socioeconomic Vulnerability
-- Question: Are vulnerable neighborhoods (low income, high unemployment) most affected by rent increases & STR pressure?

SELECT * FROM unemployed_data;

SELECT * FROM income_data;

-- ✅ Step 1.1 — Let's start with Unemployment (2020) only
CREATE OR REPLACE VIEW unemployment_2021_neighbourhood AS
SELECT
    territory AS neighbourhood,
    AVG(num_unemployed) AS avg_unemployed_2021
FROM
    unemployed_data
WHERE
    territory_type = 'Neighborhood'
    AND year = 2021
GROUP BY
    territory;

-- 🔜 Next Step: Income Data Aggregation
CREATE OR REPLACE VIEW income_2021_neighbourhood AS
SELECT
    neighborhood_name AS neighbourhood,
    AVG(income_eur) AS avg_income_2021
FROM
    income_data
WHERE
    year = 2021
GROUP BY
    neighborhood_name;

SELECT * FROM income_2021_neighbourhood
LIMIT 10;

-- ✅ Step 2: Join Income + Unemployment into a Vulnerability Table

CREATE OR REPLACE VIEW vulnerability_raw_2021 AS
SELECT
    i.neighbourhood AS neighbourhood,
    u.avg_unemployed_2021,
    i.avg_income_2021
FROM
    unemployment_2021_neighbourhood u
JOIN
    income_2021_neighbourhood i
    ON TRIM(LOWER(REPLACE(REPLACE(u.neighbourhood, '-', ' '), '.', ''))) =
       TRIM(LOWER(REPLACE(REPLACE(SUBSTRING_INDEX(i.neighbourhood, '-', 1), '.', ''), '-', ' ')));


    
-- 🚧 Step 3A: Get min/max for each column
SELECT 
    MIN(avg_unemployed_2021) AS min_unemp,
    MAX(avg_unemployed_2021) AS max_unemp
FROM vulnerability_raw_2021;

SELECT 
    MIN(avg_income_2021) AS min_income,
    MAX(avg_income_2021) AS max_income
FROM vulnerability_raw_2021;

-- 🧾 Final Query — Create the full

CREATE OR REPLACE VIEW vulnerability_2021_neighbourhood AS
SELECT
    neighbourhood,
    avg_unemployed_2021,
    avg_income_2021,

    -- Normalize unemployment (0 = low, 1 = high)
    (avg_unemployed_2021 - 19.333333333333332) / (4211.666666666667 - 19.333333333333332) AS unemployment_score,

    -- Normalize income (0 = high, 1 = low, because lower income = more vulnerable)
    1 - ((avg_income_2021 - 10940.075) / (37785.937273 - 10940.075)) AS income_score,

    -- Final vulnerability score (average of both components)
    (
        ((avg_unemployed_2021 - 19.333333333333332) / (4211.666666666667 - 19.333333333333332)) +
        (1 - ((avg_income_2021 - 10940.075) / (37785.937273 - 10940.075)))
    ) / 2 AS vulnerability_score

FROM vulnerability_raw_2021;

SELECT * 
FROM vulnerability_2021_neighbourhood
WHERE LOWER(neighbourhood) LIKE '%poble%';


SELECT * FROM vulnerability_2021_neighbourhood
WHERE LOWER(neighbourhood) LIKE '%poble%';

SELECT *
FROM unemployment_2021_neighbourhood
WHERE LOWER(neighbourhood) LIKE '%poble%';

SELECT *
FROM income_2021_neighbourhood
WHERE LOWER(neighbourhood) LIKE '%poble%';



-- ✅ 🔹 Part A: Vulnerability vs STR Density

-- ✅ Step 4A.1 – Create STR count per neighborhood 

CREATE OR REPLACE VIEW str_listings_2024 AS
SELECT
    neighbourhood_cleansed AS neighbourhood,
    COUNT(*) AS listing_count_2024
FROM
    airbnb_listings_clean
GROUP BY
    neighbourhood_cleansed;

SELECT * FROM str_listings_2024;

-- ✅ Step 4A.2 – Create population per neighborhood for 2021

CREATE OR REPLACE VIEW population_2021_neighbourhood AS
SELECT
    neighborhood_name AS neighbourhood,
    SUM(population) AS total_population_2021
FROM
    population_data
WHERE
    year = 2021
GROUP BY
    neighborhood_name;

SELECT * FROM population_2021_neighbourhood;


-- 🧾 SQL: Create the final comparison view

CREATE OR REPLACE VIEW vulnerability_vs_str_2021 AS
SELECT
    v.neighbourhood,
    
    -- Raw indicators
    v.vulnerability_score,
    v.avg_unemployed_2021,
    v.avg_income_2021,

    -- STR data
    s.listing_count_2024,
    p.total_population_2021,

    -- STR density per 1000 residents
    (s.listing_count_2024 / (p.total_population_2021 / 1000)) AS str_density_per_1000

FROM 
    vulnerability_2021_neighbourhood v
JOIN 
    str_listings_2024 s ON v.neighbourhood = s.neighbourhood
JOIN 
    population_2021_neighbourhood p ON v.neighbourhood = p.neighbourhood;

SELECT * FROM vulnerability_vs_str_2021;


-- 🔹 Part B: Vulnerability vs Rent Growth
--  ✅ Step 4B.1 – Create Rent Growth per Neighborhood (2015 → 2024)
CREATE OR REPLACE VIEW rent_growth_2015_2021 AS
SELECT
    r2021.territory AS neighbourhood,
    r2015.average_rent_price AS rent_2015,
    r2021.average_rent_price AS rent_2021,
    ROUND(((r2021.average_rent_price - r2015.average_rent_price) / r2015.average_rent_price) * 100, 2) AS rent_growth_pct
FROM
    rent_prices r2015
JOIN
    rent_prices r2021
    ON r2015.territory = r2021.territory
WHERE
    r2015.year = 2015 AND r2015.territory_type = 'Neighbourhood'
    AND r2021.year = 2021 AND r2021.territory_type = 'Neighbourhood';

SELECT * FROM rent_growth_2015_2021; 

-- 🧾 Final SQL Join: Vulnerability + Rent Growth

CREATE OR REPLACE VIEW vulnerability_vs_rent_growth AS
SELECT
    v.neighbourhood,
    v.vulnerability_score,
    v.avg_unemployed_2021,
    v.avg_income_2021,
    r.rent_2015,
    r.rent_2021,
    r.rent_growth_pct
FROM
    vulnerability_2021_neighbourhood v
JOIN
    rent_growth_2015_2021 r ON v.neighbourhood = r.neighbourhood;

SELECT * FROM vulnerability_vs_rent_growth;

SELECT DISTINCT year
FROM rent_prices
ORDER BY year;

--
CREATE OR REPLACE VIEW rent_growth_2015_2021 AS
SELECT
    r2021.territory AS neighbourhood,
    r2015.average_rent_price AS rent_2015,
    r2021.average_rent_price AS rent_2021,
    ROUND(((r2021.average_rent_price - r2015.average_rent_price) / r2015.average_rent_price) * 100, 2) AS rent_growth_pct
FROM
    (SELECT territory, average_rent_price
     FROM rent_prices
     WHERE year = 2015 AND territory_type = 'Neighbourhood') AS r2015
JOIN
    (SELECT territory, average_rent_price
     FROM rent_prices
     WHERE year = 2021 AND territory_type = 'Neighbourhood') AS r2021
ON r2015.territory = r2021.territory;

SELECT * FROM vulnerability_vs_rent_growth;

-- fixed 

CREATE OR REPLACE VIEW rent_growth_2015_2021 AS
SELECT
    r2021.neighbourhood,
    r2015.avg_rent_2015,
    r2021.avg_rent_2021,
    ROUND(((r2021.avg_rent_2021 - r2015.avg_rent_2015) / r2015.avg_rent_2015) * 100, 2) AS rent_growth_pct
FROM
    (
        SELECT
            territory AS neighbourhood,
            AVG(average_rent_price) AS avg_rent_2015
        FROM
            rent_prices
        WHERE
            year = 2015
            AND territory_type = 'Neighbourhood'
        GROUP BY
            territory
    ) AS r2015
JOIN
    (
        SELECT
            territory AS neighbourhood,
            AVG(average_rent_price) AS avg_rent_2021
        FROM
            rent_prices
        WHERE
            year = 2021
            AND territory_type = 'Neighbourhood'
        GROUP BY
            territory
    ) AS r2021
ON r2015.neighbourhood = r2021.neighbourhood;

SELECT * FROM rent_growth_2015_2021;


-- Final SQL: Vulnerability + Rent Growth
CREATE OR REPLACE VIEW vulnerability_vs_rent_growth AS
SELECT
    v.neighbourhood,
    v.vulnerability_score,
    v.avg_unemployed_2021,
    v.avg_income_2021,
    r.avg_rent_2015,
    r.avg_rent_2021,
    r.rent_growth_pct
FROM
    vulnerability_2021_neighbourhood v
JOIN
    rent_growth_2015_2021 r
    ON v.neighbourhood = r.neighbourhood;
    
SELECT * FROM vulnerability_vs_rent_growth;




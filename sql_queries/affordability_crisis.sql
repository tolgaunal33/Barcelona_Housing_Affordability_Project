-- 1. Is Barcelona Really Facing an Affordability Crisis?
-- Question: Did rents increase faster than incomes from 2015 to 2021, making Barcelona less affordable?

-- 🔹 1.1 — Get District-level rent prices (2015–2021)

SELECT 
    territory AS district,
    year,
    average_rent_price
FROM 
    rent_prices
WHERE 
    year BETWEEN 2015 AND 2021
    AND territory_type = 'District'
ORDER BY 
    year, district;

-- 🔹 1.2 — Get Neighborhood-level rent prices (2015–2021)
SELECT 
    territory AS neighborhood,
    year,
    average_rent_price
FROM 
    rent_prices
WHERE 
    year BETWEEN 2015 AND 2021
    AND territory_type = 'Neighbourhood'
ORDER BY 
    year, neighborhood;
    
-- 🔹 2.1 — District-Level Average Income (2015–2021)
SELECT 
    district_name,
    year,
    AVG(income_eur) AS avg_income_eur
FROM 
    income_data
WHERE 
    year BETWEEN 2015 AND 2021
GROUP BY 
    district_name, year
ORDER BY 
    year, district_name;

-- 🔹 2.2 — Neighborhood-Level Average Income (2015–2021)

SELECT 
    neighborhood_name,
    year,
    AVG(income_eur) AS avg_income_eur
FROM 
    income_data
WHERE 
    year BETWEEN 2015 AND 2021
GROUP BY 
    neighborhood_name, year
ORDER BY 
    year, neighborhood_name;

-- 🛠️ 3.1 — District-Level Affordability Index

SELECT 
    r.district,
    r.year,
    ROUND(r.average_rent_price / i.avg_income_eur, 4) AS affordability_index
FROM 
    (
        SELECT 
            territory AS district,
            year,
            AVG(average_rent_price) AS average_rent_price
        FROM 
            rent_prices
        WHERE 
            year BETWEEN 2015 AND 2021
            AND territory_type = 'District'
        GROUP BY 
            territory, year
    ) r
JOIN 
    (
        SELECT 
            district_name,
            year,
            AVG(income_eur) AS avg_income_eur
        FROM 
            income_data
        WHERE 
            year BETWEEN 2015 AND 2021
        GROUP BY 
            district_name, year
    ) i 
ON 
    r.district = i.district_name AND r.year = i.year
ORDER BY 
    r.year, r.district;

-- 🛠️ 3.2 — Neighborhood-Level Affordability Index
SELECT 
    r.neighborhood,
    r.year,
    ROUND(r.average_rent_price / i.avg_income_eur, 4) AS affordability_index
FROM 
    (
        SELECT 
            territory AS neighborhood,
            year,
            AVG(average_rent_price) AS average_rent_price
        FROM 
            rent_prices
        WHERE 
            year BETWEEN 2015 AND 2021
            AND territory_type = 'Neighborhood'
        GROUP BY 
            territory, year
    ) r
JOIN 
    (
        SELECT 
            neighborhood_name,
            year,
            AVG(income_eur) AS avg_income_eur
        FROM 
            income_data
        WHERE 
            year BETWEEN 2015 AND 2021
        GROUP BY 
            neighborhood_name, year
    ) i 
ON 
    r.neighborhood = i.neighborhood_name AND r.year = i.year
ORDER BY 
    r.year, r.neighborhood;

-- 🛠️ 3.2 — Neighborhood-Level Affordability Index
SELECT 
    r.neighborhood,
    r.year,
    ROUND(r.average_rent_price / i.avg_income_eur, 4) AS affordability_index
FROM 
    (
        SELECT 
            territory AS neighborhood,
            year,
            AVG(average_rent_price) AS average_rent_price
        FROM 
            rent_prices
        WHERE 
            year BETWEEN 2015 AND 2021
            AND territory_type = 'Neighbourhood'
        GROUP BY 
            territory, year
    ) r
JOIN 
    (
        SELECT 
            neighborhood_name,
            year,
            AVG(income_eur) AS avg_income_eur
        FROM 
            income_data
        WHERE 
            year BETWEEN 2015 AND 2021
        GROUP BY 
            neighborhood_name, year
    ) i 
ON 
    r.neighborhood = i.neighborhood_name AND r.year = i.year
ORDER BY 
    r.year, r.neighborhood;

-- citywide average income
SELECT 
    r.year,
    ROUND(r.average_rent_price / i.avg_income_eur, 4) AS affordability_index
FROM 
    (
        SELECT 
            year,
            AVG(average_rent_price) AS average_rent_price
        FROM 
            rent_prices
        WHERE 
            year BETWEEN 2015 AND 2021
            AND territory = 'Barcelona'
        GROUP BY year
    ) r
JOIN 
    (
        SELECT 
            year,
            AVG(avg_income_eur) AS avg_income_eur
        FROM 
            (
                SELECT 
                    district_name,
                    year,
                    AVG(income_eur) AS avg_income_eur
                FROM 
                    income_data
                WHERE 
                    year BETWEEN 2015 AND 2021
                GROUP BY district_name, year
            ) sub
        GROUP BY year
    ) i 
ON r.year = i.year
ORDER BY r.year;




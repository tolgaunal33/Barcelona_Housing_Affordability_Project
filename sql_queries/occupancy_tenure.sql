-- 5. Housing Occupancy & Tenure Changes
-- Question: Have main/primary residences decreased where short-term renting is high? Are we shifting from ownership to rental?
-- Goal: Reveal if main homes are decreasing or if ownership is shifting to rental or secondary homes in STR-heavy areas.

SELECT * FROM housing_occupancy;
-- occupancy whole city 
SELECT 
    year,
    occupancy_status,
    SUM(num_housing_units) AS total_units
FROM housing_occupancy
WHERE territory_type = 'Municipality'
GROUP BY year, occupancy_status
ORDER BY year, occupancy_status;

-- district level 
SELECT 
    year,
    territory AS district,
    occupancy_status,
    SUM(num_housing_units) AS total_units
FROM housing_occupancy
WHERE territory_type = 'District'
GROUP BY year, district, occupancy_status
ORDER BY district, year, occupancy_status;

-- neigborhood level ocuppancy only 2021 
SELECT 
    year,
    territory AS neighbourhood,
    occupancy_status,
    SUM(num_housing_units) AS total_units
FROM housing_occupancy
WHERE territory_type = 'Neighbourhood'
GROUP BY year, neighbourhood, occupancy_status
ORDER BY neighbourhood, year, occupancy_status;

-- STR distribution tabel to compare for later
SELECT 
    neighbourhood_cleansed AS neighborhood_name,
    COUNT(*) AS airbnb_listing_count
FROM airbnb_listings_clean
GROUP BY neighbourhood_cleansed
ORDER BY airbnb_listing_count DESC;

-- Step 1: Get Main and Not Main units from housing_occupancy (2021)
SELECT
    territory AS neighbourhood,
    SUM(CASE WHEN occupancy_status = 'Main' THEN num_housing_units ELSE 0 END) AS main_units,
    SUM(CASE WHEN occupancy_status = 'Not main' THEN num_housing_units ELSE 0 END) AS not_main_units
FROM housing_occupancy
WHERE territory_type = 'Neighbourhood' AND year = 2021
GROUP BY territory;

-- Step 2: Join with Airbnb listing counts

WITH occupancy AS (
    SELECT
        territory AS neighbourhood,
        SUM(CASE WHEN occupancy_status = 'Main' THEN num_housing_units ELSE 0 END) AS main_units,
        SUM(CASE WHEN occupancy_status = 'Not main' THEN num_housing_units ELSE 0 END) AS not_main_units
    FROM housing_occupancy
    WHERE territory_type = 'Neighbourhood' AND year = 2021
    GROUP BY territory
),
airbnb_counts AS (
    SELECT 
        neighbourhood_cleansed AS neighbourhood,
        COUNT(*) AS airbnb_listing_count
    FROM airbnb_listings_clean
    GROUP BY neighbourhood
)

SELECT 
    o.neighbourhood,
    o.main_units,
    o.not_main_units,
    (o.not_main_units * 1.0) / (o.main_units + o.not_main_units) AS not_main_share,
    a.airbnb_listing_count
FROM occupancy o
LEFT JOIN airbnb_counts a
    ON o.neighbourhood = a.neighbourhood
ORDER BY not_main_share DESC;

-- ✅ SQL: Filtered comparison for STR-heavy neighbourhoods vs housing occupancy
WITH occupancy AS (
    SELECT
        territory AS neighbourhood,
        SUM(CASE WHEN occupancy_status = 'Main' THEN num_housing_units ELSE 0 END) AS main_units,
        SUM(CASE WHEN occupancy_status = 'Not main' THEN num_housing_units ELSE 0 END) AS not_main_units
    FROM housing_occupancy
    WHERE territory_type = 'Neighbourhood' AND year = 2021
    GROUP BY territory
),
airbnb_counts AS (
    SELECT 
        neighbourhood_cleansed AS neighbourhood,
        COUNT(*) AS airbnb_listing_count
    FROM airbnb_listings_clean
    GROUP BY neighbourhood
),
combined AS (
    SELECT 
        o.neighbourhood,
        o.main_units,
        o.not_main_units,
        (o.not_main_units * 1.0) / (o.main_units + o.not_main_units) AS not_main_share,
        a.airbnb_listing_count
    FROM occupancy o
    LEFT JOIN airbnb_counts a
        ON o.neighbourhood = a.neighbourhood
)

SELECT *
FROM combined
WHERE neighbourhood IN (
    'la Dreta de l''Eixample',
    'el Raval',
    'el Barri Gòtic',
    'Sant Pere, Santa Caterina i la Ribera',
    'la Sagrada Família',
    'la Vila de Gràcia',
    'l''Antiga Esquerra de l''Eixample',
    'Sant Antoni',
    'el Poble Sec',
    'la Nova Esquerra de l''Eixample'
)
ORDER BY not_main_share DESC;


-- ✅ Next quick check: Compare to city-wide average
SELECT
    SUM(CASE WHEN occupancy_status = 'Main' THEN num_housing_units ELSE 0 END) AS total_main,
    SUM(CASE WHEN occupancy_status = 'Not main' THEN num_housing_units ELSE 0 END) AS total_not_main,
    (SUM(CASE WHEN occupancy_status = 'Not main' THEN num_housing_units ELSE 0 END) * 1.0) / 
    (SUM(CASE WHEN occupancy_status IN ('Main', 'Not main') THEN num_housing_units ELSE 0 END)) AS not_main_share_citywide
FROM housing_occupancy
WHERE territory_type = 'Neighbourhood' AND year = 2021;


-- TENURE REGIME STEP 

SELECT * FROM tenure_data;

-- Step 2A: Municipality-level summary

SELECT 
    year,
    tenure_regime,
    SUM(num_main_homes) AS total_main_homes
FROM tenure_data
WHERE territory_type = 'Municipality'
GROUP BY year, tenure_regime
ORDER BY year, tenure_regime;


-- Rent Share per year  city over all 
SELECT 
    year,
    SUM(CASE WHEN tenure_regime = 'Rent' THEN num_main_homes ELSE 0 END) AS rent_units,
    SUM(CASE WHEN tenure_regime = 'Ownership' THEN num_main_homes ELSE 0 END) AS owned_units,
    (SUM(CASE WHEN tenure_regime = 'Rent' THEN num_main_homes ELSE 0 END) * 1.0) /
    (SUM(CASE WHEN tenure_regime IN ('Rent', 'Ownership') THEN num_main_homes ELSE 0 END)) AS rent_share
FROM tenure_data
WHERE territory_type = 'Municipality'
GROUP BY year
ORDER BY year;

-- ✅ Step 2B: Tenure regime summary by district and year
SELECT 
    year,
    territory AS district,
    SUM(CASE WHEN tenure_regime = 'Rent' THEN num_main_homes ELSE 0 END) AS rent_units,
    SUM(CASE WHEN tenure_regime = 'Ownership' THEN num_main_homes ELSE 0 END) AS owned_units,
    (SUM(CASE WHEN tenure_regime = 'Rent' THEN num_main_homes ELSE 0 END) * 1.0) /
    (SUM(CASE WHEN tenure_regime IN ('Rent', 'Ownership') THEN num_main_homes ELSE 0 END)) AS rent_share
FROM tenure_data
WHERE territory_type = 'District'
GROUP BY year, district
ORDER BY district, year;

-- ✅ SQL to get rent share for STR-heavy neighborhoods vs tenure regime with city average rent_share   (neighborhood avg????)
WITH neighbourhood_rent AS (
    SELECT 
        year,
        territory AS neighbourhood,
        SUM(CASE WHEN tenure_regime = 'Rent' THEN num_main_homes ELSE 0 END) AS rent_units,
        SUM(CASE WHEN tenure_regime = 'Ownership' THEN num_main_homes ELSE 0 END) AS owned_units,
        (SUM(CASE WHEN tenure_regime = 'Rent' THEN num_main_homes ELSE 0 END) * 1.0) /
        (SUM(CASE WHEN tenure_regime IN ('Rent', 'Ownership') THEN num_main_homes ELSE 0 END)) AS rent_share
    FROM tenure_data
    WHERE territory_type = 'Neighborhood'
      AND territory IN (
        'la Dreta de l''Eixample',
        'el Raval',
        'el Barri Gòtic',
        'Sant Pere, Santa Caterina i la Ribera',
        'la Sagrada Família',
        'la Vila de Gràcia',
        'l''Antiga Esquerra de l''Eixample',
        'Sant Antoni',
        'el Poble Sec',
        'la Nova Esquerra de l''Eixample'
      )
    GROUP BY year, neighbourhood
),
city_avg_rent AS (
    SELECT 
        year,
        'City Average' AS neighbourhood,
        SUM(CASE WHEN tenure_regime = 'Rent' THEN num_main_homes ELSE 0 END) AS rent_units,
        SUM(CASE WHEN tenure_regime = 'Ownership' THEN num_main_homes ELSE 0 END) AS owned_units,
        (SUM(CASE WHEN tenure_regime = 'Rent' THEN num_main_homes ELSE 0 END) * 1.0) /
        (SUM(CASE WHEN tenure_regime IN ('Rent', 'Ownership') THEN num_main_homes ELSE 0 END)) AS rent_share
    FROM tenure_data
    WHERE territory_type = 'Neighborhood'
    GROUP BY year
)

SELECT * FROM neighbourhood_rent
UNION ALL
SELECT * FROM city_avg_rent
ORDER BY neighbourhood, year;

--
SELECT 
    year,
    territory AS district,
    SUM(CASE WHEN tenure_regime = 'Rent' THEN num_main_homes ELSE 0 END) AS rent_units,
    SUM(CASE WHEN tenure_regime = 'Ownership' THEN num_main_homes ELSE 0 END) AS owned_units,
    (SUM(CASE WHEN tenure_regime = 'Rent' THEN num_main_homes ELSE 0 END) * 1.0) /
    (SUM(CASE WHEN tenure_regime IN ('Rent', 'Ownership') THEN num_main_homes ELSE 0 END)) AS rent_share
FROM tenure_data
WHERE territory_type = 'District'
  AND territory IN (
    'Eixample',
    'Ciutat Vella',
    'Sants-Montjuïc',
    'Sant Martí',
    'Gràcia'
  )
GROUP BY year, district
ORDER BY district, year;


WITH occupancy_2021 AS (
    SELECT
        territory AS neighbourhood,
        SUM(CASE WHEN occupancy_status = 'Main' THEN num_housing_units ELSE 0 END) AS main_units,
        SUM(CASE WHEN occupancy_status = 'Not main' THEN num_housing_units ELSE 0 END) AS not_main_units
    FROM housing_occupancy
    WHERE territory_type = 'Neighbourhood' AND year = 2021
    GROUP BY territory
),
airbnb_counts AS (
    SELECT 
        neighbourhood_cleansed AS neighbourhood,
        COUNT(*) AS airbnb_listing_count
    FROM airbnb_listings_clean
    GROUP BY neighbourhood
)

SELECT 
    o.neighbourhood,
    o.main_units,
    o.not_main_units,
    (o.not_main_units * 1.0) / (o.main_units + o.not_main_units) AS not_main_share,
    a.airbnb_listing_count
FROM occupancy_2021 o
LEFT JOIN airbnb_counts a ON o.neighbourhood = a.neighbourhood
ORDER BY not_main_share DESC;


-- FROM SCRATCH 
-- ✅ Step 1: "Look at changes in occupancy_status over the available years"
SELECT 
    year,
    occupancy_status,
    SUM(num_housing_units) AS total_units
FROM housing_occupancy
WHERE territory_type = 'Municipality'
GROUP BY year, occupancy_status
ORDER BY year, occupancy_status;

-- ✅ Step 2 : STR Distribution at District Level
SELECT 
    year,
    territory AS district,
    SUM(CASE WHEN occupancy_status = 'Main' THEN num_housing_units ELSE 0 END) AS main_units,
    SUM(CASE WHEN occupancy_status IN ('Secondary', 'Vacant', 'Other', 'Not main') THEN num_housing_units ELSE 0 END) AS not_main_units,
    (SUM(CASE WHEN occupancy_status IN ('Secondary', 'Vacant', 'Other', 'Not main') THEN num_housing_units ELSE 0 END) * 1.0) /
    (SUM(CASE WHEN occupancy_status IN ('Main', 'Secondary', 'Vacant', 'Other', 'Not main') THEN num_housing_units ELSE 0 END)) AS not_main_share
FROM housing_occupancy
WHERE territory_type = 'District'
GROUP BY year, district
ORDER BY district, year;

SELECT * FROM tenure_data;





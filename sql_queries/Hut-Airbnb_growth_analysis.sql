-- 2. Short-Term Renting Growth
-- Question: Where are short-term rentals (STR) concentrated and how have they grown?

-- ✅ Step 1: Count HUT Registrations by Year and DISTRICT
SELECT 
    year,
    district_name,
    COUNT(*) AS total_licenses
FROM 
    hut_licenses_clean
GROUP BY 
    year, district_name
ORDER BY 
    year, total_licenses DESC;
    

-- 🧱 Step 2: Cumulative Licenses per District per Year

SELECT 
    year,
    district_name,
    COUNT(*) AS licenses_this_year,
    SUM(COUNT(*)) OVER (
        PARTITION BY district_name
        ORDER BY year
    ) AS cumulative_licenses
FROM 
    hut_licenses_clean
GROUP BY 
    district_name, year
ORDER BY 
    district_name, year;
    
-- 🧱 Step 3: Cumulative Licenses per Neighborhood per Year
SELECT 
    year,
    neighbourhood_name,
    district_name,
    COUNT(*) AS licenses_this_year,
    SUM(COUNT(*)) OVER (
        PARTITION BY neighbourhood_name
        ORDER BY year
    ) AS cumulative_licenses
FROM 
    hut_licenses_clean
GROUP BY 
    neighbourhood_name, year, district_name
ORDER BY 
    neighbourhood_name, year;
    
-- 🧱 Step 4 : Cumulative Licenses Growth by Neighbourhood TOP 10
WITH neighborhood_counts AS (
    SELECT 
        year,
        neighbourhood_name,
        district_name,
        COUNT(*) AS licenses_this_year
    FROM hut_licenses_clean
    GROUP BY neighbourhood_name, district_name, year
),
cumulative AS (
    SELECT 
        year,
        neighbourhood_name,
        district_name,
        licenses_this_year,
        SUM(licenses_this_year) OVER (
            PARTITION BY neighbourhood_name
            ORDER BY year
        ) AS cumulative_licenses
    FROM neighborhood_counts
),
latest_per_neigh AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY neighbourhood_name
            ORDER BY year DESC
        ) AS rn
    FROM cumulative
)

SELECT 
    neighbourhood_name,
    district_name,
    year AS latest_year,
    cumulative_licenses
FROM latest_per_neigh
WHERE rn = 1
ORDER BY cumulative_licenses DESC
LIMIT 10;

-- AIRBNB Analysis; 
-- 🧱 Step 1: Count Active Listings by District 
SELECT 
    neighbourhood_group_cleansed AS district,
    COUNT(*) AS total_listings
FROM airbnb_listings_clean
GROUP BY neighbourhood_group_cleansed
ORDER BY total_listings DESC;

-- 🧱 Step 2: Count Active Listings by Neighbourhood in MySQL
SELECT 
    neighbourhood_cleansed AS neighbourhood,
    COUNT(*) AS total_listings
FROM airbnb_listings_clean
GROUP BY neighbourhood_cleansed
ORDER BY total_listings DESC;

-- for map viz
SELECT id, neighbourhood_cleansed, neighbourhood_group_cleansed, latitude, longitude
FROM airbnb_listings
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Comparison Chart (HUT licenses vs Airbnb listings) 
-- 🟢 Airbnb Listings per Neighbourhood
SELECT 
    neighbourhood_cleansed AS neighbourhood,
    COUNT(*) AS total_airbnb_listings
FROM airbnb_listings_clean
GROUP BY neighbourhood;

-- 🔵 HUT Licenses per Neighbourhood (latest cumulative value)
WITH neighborhood_counts AS (
    SELECT 
        year,
        neighbourhood_name,
        COUNT(*) AS licenses_this_year
    FROM hut_licenses_clean
    GROUP BY neighbourhood_name, year
),
cumulative AS (
    SELECT 
        year,
        neighbourhood_name,
        licenses_this_year,
        SUM(licenses_this_year) OVER (
            PARTITION BY neighbourhood_name
            ORDER BY year
        ) AS cumulative_licenses
    FROM neighborhood_counts
),
latest_per_neigh AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY neighbourhood_name
            ORDER BY year DESC
        ) AS rn
    FROM cumulative
)
SELECT 
    neighbourhood_name AS neighbourhood,
    cumulative_licenses
FROM latest_per_neigh
WHERE rn = 1;


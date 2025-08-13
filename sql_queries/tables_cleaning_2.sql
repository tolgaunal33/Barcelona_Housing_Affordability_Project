-- 1. Basic Exploration & Validation
SELECT COUNT(*) FROM rent_prices;
SELECT COUNT(*) FROM airbnb_listings;
SELECT COUNT(*) FROM hut_licenses;
SELECT COUNT(*) FROM housing_occupancy;
SELECT COUNT(*) FROM income_data;
SELECT COUNT(*) FROM population_data;
SELECT COUNT(*) FROM tenure_data;
SELECT COUNT(*) FROM unemployed_data;
SELECT COUNT(*) FROM housing_stock;

-- Check for duplicates or unexpected row counts (especially in time-series tables).
SELECT * FROM rent_prices;
SELECT year_quarter, COUNT(*) AS row_count
FROM rent_prices
GROUP BY year_quarter
ORDER BY year_quarter;

-- Check min/max for numeric columns (like average_rent_price, income_eur) to spot outliers:
SELECT 
  MIN(average_rent_price), 
  MAX(average_rent_price)
FROM rent_prices;

-- 2. Creating & Checking Derived Fields
-- 2.1 Affordability Index (Rent vs Income)
-- Example approach: create a new table or a view
CREATE OR REPLACE VIEW rent_vs_income AS
SELECT 
   rp.year,
   rp.territory AS neighbourhood_name,
   rp.average_rent_price AS avg_rent,
   i.import_euros AS avg_income,
   (rp.average_rent_price / i.import_euros) AS affordability_index
FROM rent_prices rp
JOIN income_data i 
   ON rp.year = i.year
   AND rp.territory = i.nom_barri; -- or your chosen matching columns

SELECT * FROM income_data;
SELECT * FROM rent_prices;
SELECT * FROM hut_licenses;

-- GOING THROUGHT ALL TABLES 1BY1 
-- airbnb_listings
SELECT * FROM airbnb_listings;
-- price_cleaned
ALTER TABLE airbnb_listings ADD COLUMN price_cleaned DECIMAL(10,2);

UPDATE airbnb_listings
SET price_cleaned = REPLACE(REPLACE(price, '$', ''), ',', '');

-- null control 
SELECT COUNT(*) AS null_reviews
FROM airbnb_listings
WHERE review_scores_rating IS NULL;

-- clean airbnb table 
CREATE TABLE airbnb_listings_clean AS
SELECT
  id,
  price_cleaned,
  neighbourhood_cleansed,
  neighbourhood_group_cleansed,
  room_type,
  property_type,
  accommodates,
  availability_365,
  estimated_occupancy_l365d,
  estimated_revenue_l365d,
  license,
  review_scores_rating,
  number_of_reviews
FROM airbnb_listings;

DROP TABLE IF EXISTS airbnb_listings_clean;

-- recreating the table 

-- Price: mahalle ortalamasıyla doldur
CREATE TABLE airbnb_listings_clean AS
SELECT 
  a.id,
  a.neighbourhood_cleansed,
  a.neighbourhood_group_cleansed,
  a.room_type,
  a.property_type,
  a.accommodates,
  a.availability_365,

  -- PRICE doldurma
  COALESCE(a.price_cleaned, p.avg_price) AS price_cleaned,

  -- REVENUE doldurma
  COALESCE(a.estimated_revenue_l365d, r.avg_revenue) AS estimated_revenue_l365d,

  a.estimated_occupancy_l365d,
  a.license,
  a.review_scores_rating,
  a.number_of_reviews

FROM airbnb_listings a

-- JOIN 1: Mahalle bazlı ortalama fiyat
LEFT JOIN (
    SELECT neighbourhood_cleansed, AVG(price_cleaned) AS avg_price
    FROM airbnb_listings
    WHERE price_cleaned IS NOT NULL
    GROUP BY neighbourhood_cleansed
) p ON a.neighbourhood_cleansed = p.neighbourhood_cleansed

-- JOIN 2: Mahalle bazlı ortalama revenue
LEFT JOIN (
    SELECT neighbourhood_cleansed, AVG(estimated_revenue_l365d) AS avg_revenue
    FROM airbnb_listings
    WHERE estimated_revenue_l365d IS NOT NULL
    GROUP BY neighbourhood_cleansed
) r ON a.neighbourhood_cleansed = r.neighbourhood_cleansed;

SELECT * FROM airbnb_listings_clean;

-- rent_prices

SELECT * FROM rent_prices;

SELECT DISTINCT territory_type FROM rent_prices;


-- incomde_data 
SELECT * FROM income_data;


-- population_data

SELECT * FROM population_data;


-- unemployed_data 
-- creating year and quarter columns 
SELECT * FROM unemployed_data;
ALTER TABLE unemployed_data
ADD COLUMN year INT,
ADD COLUMN quarter VARCHAR(2);

UPDATE unemployed_data
SET 
  year = YEAR(year_raw),
  quarter = CONCAT('Q', QUARTER(year_raw));
  
-- housing_stock 

SELECT * FROM housing_stock;

-- hosuing_ocupancy

SELECT * FROM housing_occupancy;

-- tenure_data 
SELECT * FROM tenure_data;

-- hut_licenses 
SELECT * FROM hut_licenses;

DROP TABLE IF EXISTS hut_licenses_clean;

CREATE TABLE hut_licenses_clean AS
SELECT 
  year,
  district_name,
  neighbourhood_name,
  generalitat_register_number,
  number_of_places,
  expedient_number,
  latitude,
  longitude
FROM hut_licenses;

SELECT * FROM hut_licenses_clean;


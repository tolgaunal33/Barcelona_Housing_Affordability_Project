-- Creating rnet_prices table 
LOAD DATA LOCAL INFILE 'C:/Users/tevfi/Desktop/Ironhack/barcelona_housing_project/Barcelona_Housing_Affordability_Project/rent_prices_utf8_fixed.csv'
INTO TABLE rent_prices
CHARACTER SET utf8
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- RENAME COLUMNS 
ALTER TABLE income_data
CHANGE COLUMN codi_districte district_code INT,
CHANGE COLUMN nom_districte district_name VARCHAR(100),
CHANGE COLUMN codi_barri neighborhood_code INT,
CHANGE COLUMN nom_barri neighborhood_name VARCHAR(100),
CHANGE COLUMN seccio_censal census_section INT,
CHANGE COLUMN any year INT,
CHANGE COLUMN import_euros income_eur DECIMAL(10,2);

-- population dataset column renaming
ALTER TABLE population_data
CHANGE COLUMN Codi_Districte district_code INT,
CHANGE COLUMN Nom_Districte district_name VARCHAR(100),
CHANGE COLUMN Codi_Barri neighborhood_code INT,
CHANGE COLUMN Nom_Barri neighborhood_name VARCHAR(100),
CHANGE COLUMN AEB aeb INT,
CHANGE COLUMN Seccio_Censal census_section INT,
CHANGE COLUMN Valor population DECIMAL(10,2);

-- cleaning and updating UNEMPLOYED DATA SET
ALTER TABLE unemployed_data
CHANGE COLUMN year year_raw DATETIME;

UPDATE unemployed_data
SET territory_type = 'Municipality'
WHERE territory_type = 'Municipi';

UPDATE unemployed_data
SET territory_type = 'District'
WHERE territory_type = 'Districte';

UPDATE unemployed_data
SET territory_type = 'Neighborhood'
WHERE territory_type = 'Barri';

-- updating tenure_data table 
UPDATE tenure_data
SET territory_type = 'Municipality'
WHERE territory_type = 'Municipi';

UPDATE tenure_data
SET territory_type = 'District'
WHERE territory_type = 'Districte';

UPDATE tenure_data
SET territory_type = 'Neighborhood'
WHERE territory_type IN ('Barri');

-- hut_licenses year parsing
ALTER TABLE hut_licenses
ADD COLUMN year INT;
-- update 
UPDATE hut_licenses
SET year = SUBSTRING_INDEX(SUBSTRING_INDEX(expedient_number, '-', 2), '-', -1);

-- test 
SELECT DISTINCT year FROM hut_licenses ORDER BY year;

-- Identify Missing Values
-- hut_licenses table
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN neighbourhood_name IS NULL THEN 1 ELSE 0 END) AS missing_neighborhood,
    SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS missing_year
FROM hut_licenses;


-- Example for rent_prices table
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN average_rent_price IS NULL THEN 1 ELSE 0 END) AS missing_rent_price
FROM rent_prices;

-- Example: Verify if rent_prices has data for all quarters up to 2024 Q4
SELECT DISTINCT year, quarter
FROM rent_prices
ORDER BY year, quarter;


-- rent_prices table creating year column and quarter column
ALTER TABLE rent_prices
ADD COLUMN year INT;

UPDATE rent_prices
SET year = LEFT(year_quarter, 4);

SELECT DISTINCT year FROM rent_prices ORDER BY year;

ALTER TABLE rent_prices ADD COLUMN quarter VARCHAR(2);

UPDATE rent_prices
SET quarter = RIGHT(year_quarter, 2);  -- 'Q1', 'Q2' vs.



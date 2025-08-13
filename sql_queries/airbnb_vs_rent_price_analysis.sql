-- 🎯 SORU 1: "Kira fiyatları zaman içinde nasıl değişti?"
-- (Time series analysis of rent by year and district/neighbourhood)
SELECT 
  year,
  territory,
  ROUND(AVG(average_rent_price), 2) AS avg_rent_eur
FROM rent_prices
WHERE territory_type = 'District'
GROUP BY year, territory
ORDER BY territory, year;

-- neighbourhood 
SELECT 
  year,
  territory AS neighbourhood,
  ROUND(AVG(average_rent_price), 2) AS avg_rent_eur
FROM rent_prices
WHERE territory_type = 'Neighbourhood'
GROUP BY year, neighbourhood
ORDER BY neighbourhood, year;

-- 🎯 SORU 2: En Pahalı & En Ucuz Yerler (Mahalle ve District bazlı)
SELECT 
  year,
  territory AS district,
  ROUND(AVG(average_rent_price), 2) AS rent
FROM rent_prices
WHERE territory_type = 'District' AND year = 2024
GROUP BY year, district
ORDER BY rent DESC;

-- neighbourhood 
SELECT 
  year,
  territory AS neighbourhood,
  ROUND(AVG(average_rent_price), 2) AS rent
FROM rent_prices
WHERE territory_type = 'Neighbourhood' AND year = 2024
GROUP BY year, neighbourhood
ORDER BY rent DESC
LIMIT 20;

-- 🎯 SORU 3: Airbnb mahallelerinde kira artışı daha yüksek mi?
-- Airbnb MAHALLE YOĞUNLUĞU
SELECT 
  neighbourhood_cleansed AS neighbourhood,
  COUNT(*) AS num_airbnb_listings,
  ROUND(AVG(price_cleaned), 2) AS avg_airbnb_price
FROM airbnb_listings_clean
GROUP BY neighbourhood
ORDER BY num_airbnb_listings DESC;

-- rent_prices tablosundaki unique mahalleler (2024)
SELECT DISTINCT territory
FROM rent_prices
WHERE territory_type = 'Neighbourhood' AND year = 2024;

-- airbnb_listings_clean tablosundaki unique mahalleler
SELECT DISTINCT neighbourhood_cleansed
FROM airbnb_listings_clean;

-- Mahalle eşleşmesi kontrol tablosu
SELECT DISTINCT r.territory
FROM rent_prices r
LEFT JOIN airbnb_listings_clean a
ON r.territory = a.neighbourhood_cleansed
WHERE r.territory_type = 'Neighbourhood'
  AND r.year = 2024
  AND a.neighbourhood_cleansed IS NULL;
  
-- eslesmeyen iki mahalle isminin tablolarda guncellenmesi/eslenmesi
UPDATE rent_prices
SET territory = 'el Poble Sec'
WHERE territory = 'el Poble Sec - AEI Parc Montjuïc';

UPDATE rent_prices
SET territory = 'la Marina del Prat Vermell'
WHERE territory = 'la Marina del Prat Vermell - AEI Zona Franca';

-- Airbnb yoğunluğu + kira verisini birleştir
SELECT 
  r.territory AS neighbourhood,
  ROUND(AVG(r.average_rent_price), 2) AS avg_rent_price,
  a.num_airbnb_listings,
  a.avg_airbnb_price
FROM rent_prices r
JOIN (
    SELECT 
        neighbourhood_cleansed,
        COUNT(*) AS num_airbnb_listings,
        ROUND(AVG(price_cleaned), 2) AS avg_airbnb_price
    FROM airbnb_listings_clean
    GROUP BY neighbourhood_cleansed
) a
ON r.territory = a.neighbourhood_cleansed
WHERE r.territory_type = 'Neighbourhood' AND r.year = 2024
GROUP BY r.territory, a.num_airbnb_listings, a.avg_airbnb_price
ORDER BY avg_rent_price DESC;


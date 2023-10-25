CREATE TABLE car_resale  (
	i int NOT NULL PRIMARY KEY AUTO_INCREMENT,
	full_name VARCHAR(70) NOT NULL,
    resale_price VARCHAR(20) NOT NULL,
    engine_capacity VARCHAR(10) NOT NULL,
    insurance VARCHAR(40) NOT NULL,
    transimssion VARCHAR(20) NOT NULL,
    kms_driven VARCHAR(20) NOT NULL,
    owner_type VARCHAR(20) NOT NULL,
    fuel VARCHAR(10) NOT NULL,
    max_power VARCHAR(20) NOT NULL,
    seats int NOT NULL,
    mileage VARCHAR(10) NOT NULL,
    body VARCHAR(20) NOT NULL,
    city VARCHAR(30) NOT NULL
);

-- Get the registeration year from the full name 
SELECT LEFT(full_name, 4)
FROM car_resale;

-- Make a new column for registeration year
ALTER TABLE car_resale
	ADD COLUMN registered_year INT NOT NULL AFTER full_name;

-- Add the regiteration year to the registered_year column
UPDATE car_resale
	SET registered_year = (LEFT(full_name, 4));
    
----------------------------------------------------------- Get the prices fixed -----------------------------------------------------------
-- Get just the number and 
SELECT REGEXP_SUBSTR(resale_price, '([0-9]*[.])?[0-9]+ ?([A-Z][a-z]*)?')
FROM car_resale;

-- Make a new column for prices
ALTER TABLE car_resale
	ADD COLUMN price_fixed VARCHAR(10) NOT NULL AFTER resale_price;
    
-- Fill the column
UPDATE car_resale
	SET price_fixed = (REGEXP_SUBSTR(resale_price, '([0-9]*[.])?[0-9]+ ?([A-Z][a-z]*)?'));

----------------------------------------------------------- Get prices in numbers only -----------------------------------------------------------

-- Get only Lakh/Crore
SELECT REGEXP_SUBSTR(price_fixed, '[A-Z][a-z]+')
FROM car_resale;

-- Convert it to just numbers 
SELECT REGEXP_SUBSTR(price_fixed, '[A-Z][a-z]+'),
CASE 
	WHEN 
	REGEXP_SUBSTR(price_fixed, '[A-Z][a-z]+') = 'Lakh' THEN CAST(REGEXP_SUBSTR(price_fixed, '([0-9]*[.])?[0-9]+') * 100000 AS UNSIGNED)
    WHEN 
    REGEXP_SUBSTR(price_fixed, '[A-Z][a-z]+') = 'Crore' THEN CAST(REGEXP_SUBSTR(price_fixed, '([0-9]*[.])?[0-9]+') * 1000000 AS UNSIGNED)
    WHEN 
    REGEXP_SUBSTR(price_fixed, '[A-Z][a-z]+') NOT IN ('Lakh', 'Crore') THEN CAST(REGEXP_SUBSTR(price_fixed, '([0-9]*[.])?[0-9]+') * 1000000 AS UNSIGNED)
    ELSE 
    CAST(REGEXP_SUBSTR(price_fixed, '([0-9]*[.])?[0-9]+') * 100000 AS UNSIGNED)
END AS num
FROM car_resale
;

-- Comparing and making sure all values got converted
WITH test_price AS (
SELECT price_fixed, REGEXP_SUBSTR(price_fixed, '[A-Z][a-z]+'),
CASE 
	WHEN 
	REGEXP_SUBSTR(price_fixed, '[A-Z][a-z]+') = 'Lakh' THEN CAST(REGEXP_SUBSTR(price_fixed, '([0-9]*[.])?[0-9]+') * 100000 AS UNSIGNED) -- In case of Lakh * 100000
    WHEN 
    REGEXP_SUBSTR(price_fixed, '[A-Z][a-z]+') = 'Crore' THEN CAST(REGEXP_SUBSTR(price_fixed, '([0-9]*[.])?[0-9]+') * 1000000 AS UNSIGNED) -- In case of Crore * 1000000
    ELSE 
    CAST(REGEXP_SUBSTR(price_fixed, '([0-9]*[.])?[0-9]+') * 100000 AS UNSIGNED) -- For the Numbers that doesn't inclued Lakh or Crore Consider it Lakh and multiply by 100000
END AS numeric_price
FROM car_resale
)

SELECT price_fixed, numeric_price
FROM test_price
WHERE numeric_price IS NULL;

-- Adding a column for values
ALTER TABLE car_resale
ADD COLUMN price_in_numbers INT NOT NULL AFTER price_fixed;

-- Inserting data to the column
UPDATE car_resale
SET price_in_numbers = (
CASE 
	WHEN 
	REGEXP_SUBSTR(price_fixed, '[A-Z][a-z]+') = 'Lakh' THEN CAST(REGEXP_SUBSTR(price_fixed, '([0-9]*[.])?[0-9]+') * 100000 AS UNSIGNED)
    WHEN 
    REGEXP_SUBSTR(price_fixed, '[A-Z][a-z]+') = 'Crore' THEN CAST(REGEXP_SUBSTR(price_fixed, '([0-9]*[.])?[0-9]+') * 1000000 AS UNSIGNED)
    WHEN 
    REGEXP_SUBSTR(price_fixed, '[A-Z][a-z]+') NOT IN ('Lakh', 'Crore') THEN CAST(REGEXP_SUBSTR(price_fixed, '([0-9]*[.])?[0-9]+') * 1000000 AS UNSIGNED)
    ELSE 
    CAST(REGEXP_SUBSTR(price_fixed, '([0-9]*[.])?[0-9]+') * 100000 AS UNSIGNED)
END);


----------------------------------------------------------- Get Kilometers driven in numbers only -----------------------------------------------------------

-- Get KMS driven in numbers only
SELECT kms_driven, REPLACE(REGEXP_SUBSTR(kms_driven, '^[0-9]+[,]+[0-9]+([,][0-9]+)?'), ',', '')
FROM car_resale
WHERE REPLACE(REGEXP_SUBSTR(kms_driven, '^[0-9]+[,]+[0-9]+([,][0-9]+)?'), ',', '') IS NULL
;

-- Make a column
ALTER TABLE car_resale
ADD COLUMN kms_int INT NOT NULL AFTER kms_driven;

-- Modift yi to accept NULLs
ALTER TABLE car_resale
MODIFY kms_int INT;

-- Insert the data
UPDATE car_resale
SET kms_int = (REPLACE(REGEXP_SUBSTR(kms_driven, '^[0-9]+[,]+[0-9]+([,][0-9]+)?'), ',', '') );

SELECT * FROM car_resale;

-------------------------------------------------------------- Max Power Rounded -----------------------------------------------------------

-- Change the random values and normalize all of them to bhp
SELECT max_power,
CASE 
WHEN max_power LIKE ('%bhp%') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
WHEN max_power LIKE ('%PS%') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+') * 0.98632
WHEN max_power LIKE ('%HP') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+') * 0.98632
WHEN trim(max_power) REGEXP '^[0-9]+([.]?[0-9]+?)$' THEN max_power
WHEN upper(max_power) LIKE ('%KW') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+') * 1.34102
WHEN max_power REGEXP '^[0-9]+[(]' THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
WHEN max_power REGEXP '^[0-9]+[/]' THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
WHEN max_power REGEXP '^[0-9]+ \\[' THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
END AS s
FROM car_resale;

-- Check if there are any other values than numeric 
SELECT * 
FROM (SELECT max_power,
CASE 
WHEN max_power LIKE ('%bhp%') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
WHEN max_power LIKE ('%PS%') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+') * 0.98632
WHEN max_power LIKE ('%HP') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+') * 0.98632
WHEN trim(max_power) REGEXP '^[0-9]+([.]?[0-9]+?)$' THEN max_power
WHEN upper(max_power) LIKE ('%KW') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+') * 1.34102
WHEN max_power REGEXP '^[0-9]+[(]' THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
WHEN max_power REGEXP '^[0-9]+[/]' THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
WHEN max_power REGEXP '^[0-9]+ \\[' THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
END AS a
FROM car_resale) as temp
WHERE temp.a NOT REGEXP '[0-9]+([.]?)[0-9]+';

-- Create column
ALTER TABLE car_resale
ADD COLUMN max_power_int int AFTER max_power;

-- Insert the values in the column
UPDATE car_resale
SET max_power_int = (CASE 
	WHEN max_power LIKE ('%bhp%') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
	WHEN max_power LIKE ('%PS%') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+') * 0.98632
	WHEN max_power LIKE ('%HP') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+') * 0.98632
	WHEN trim(max_power) REGEXP '^[0-9]+([.]?[0-9]+?)$' THEN max_power
	WHEN upper(max_power) LIKE ('%KW') THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+') * 1.34102
	WHEN max_power REGEXP '^[0-9]+[(]' THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
	WHEN max_power REGEXP '^[0-9]+[/]' THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
	WHEN max_power REGEXP '^[0-9]+ \\[' THEN REGEXP_SUBSTR(max_power, '[0-9]+([.]?)[0-9]+')
END
);

-------------------------------------------------------------- Mileage Power Rounded -----------------------------------------------------------

SELECT mileage, ROUND(REGEXP_SUBSTR(mileage, '[0-9]+([.]?)[0-9]+'))
FROM car_resale;

ALTER TABLE car_resale
ADD COLUMN rounded_mileage INT AFTER mileage;

UPDATE car_resale
SET rounded_mileage = ROUND(REGEXP_SUBSTR(mileage, '[0-9]+([.]?)[0-9]+'));

SELECT * FROM car_resale;

-------------------------------------------------------------- Mileage Power Rounded -----------------------------------------------------------

SELECT engine_capacity, REGEXP_SUBSTR(engine_capacity, '[0-9]+([.]?)[0-9]+')
FROM car_resale;

ALTER TABLE car_resale
ADD COLUMN capacity_int INT AFTER engine_capacity;

UPDATE car_resale
SET capacity_int = REGEXP_SUBSTR(engine_capacity, '[0-9]+([.]?)[0-9]+');

SELECT * FROM car_resale;

-------------------------------------------------------------- Cars for each year -----------------------------------------------------------
SELECT registered_year,COUNT(i) AS Number_Of_Sold_Cars_For_The_Year
FROM car_resale
GROUP BY registered_year
ORDER BY registered_year DESC;

-------------------------------------------------------------- Most expensive car for each year -----------------------------------------------------------

SELECT registered_year, MAX(price_in_numbers) AS max_price
FROM car_resale
GROUP BY registered_year
ORDER BY registered_year DESC;

WITH max_car AS (SELECT registered_year, MAX(price_in_numbers) AS max_price
FROM car_resale
GROUP BY registered_year
ORDER BY registered_year DESC)

SELECT c.registered_year, c.full_name, c.price_in_numbers
FROM car_resale c
JOIN max_car m
ON m.registered_year = c.registered_year AND m.max_price = c.price_in_numbers
ORDER BY c.registered_year DESC;

-------------------------------------------------------------- Most sold car for each year -----------------------------------------------------------

-- Number how many times each car appears
SELECT full_name, registered_year, ROW_NUMBER() over(PARTITION BY full_name) cars_sold
FROM car_resale c
ORDER BY cars_sold DESC;

-- WITH max_sold AS (SELECT c.i, c.full_name, c.registered_year, ROW_NUMBER() over(PARTITION BY full_name) cars_sold
-- FROM car_resale c
-- ORDER BY cars_sold DESC)

-- SELECT registered_year, MAX(cars_sold) number_sold, MAX(i)
-- FROM max_sold
-- GROUP BY registered_year
-- ORDER BY number_sold DESC;

-- SELECT c.i, c.full_name, c.registered_year, ROW_NUMBER() over(PARTITION BY full_name) cars_sold
-- FROM car_resale c
-- ORDER BY cars_sold DESC;

-- Temporary table for the the most sold cars for each registered years and THE index FOR EACH CAR (so we can find the car later)
CREATE TEMPORARY TABLE max_sold
SELECT registered_year, MAX(cars_sold) number_sold, MAX(i) max_i
FROM (SELECT i, full_name, registered_year, ROW_NUMBER() over(PARTITION BY full_name) cars_sold
	FROM car_resale) m
GROUP BY registered_year
ORDER BY number_sold DESC;

-- Using the temporary table to find the most sold cars
SELECT c.full_name, c.registered_year, number_sold
FROM car_resale c
JOIN max_sold ON max_i = c.i
ORDER BY registered_year DESC;

SELECT * from car_resale;

-------------------------------------------------------------- Kilometers driven brackets -----------------------------------------------------------
SELECT kms_int,
CASE 
WHEN kms_int > 0 AND kms_int <= 20000 THEN '[0-20,000]km'
WHEN kms_int > 20000 AND kms_int <= 40000 THEN '[20,000-40,000]km'
WHEN kms_int > 40000 AND kms_int <= 60000 THEN '[40,000-60,000]km'
WHEN kms_int > 60000 AND kms_int <= 80000 THEN '[60,000-80,000]km'
WHEN kms_int > 80000 AND kms_int <= 100000 THEN '[80,000-100,000]km'
WHEN kms_int > 10000 THEN 'More than 100,000 km'
END AS km_driven_bracket
FROM car_resale;

ALTER TABLE car_resale
ADD COLUMN km_driven_bracket VARCHAR(20) AFTER kms_driven;

UPDATE car_resale
SET km_driven_bracket = (CASE 
WHEN kms_int > 0 AND kms_int <= 20000 THEN '[0-20,000]km'
WHEN kms_int > 20000 AND kms_int <= 40000 THEN '[20,000-40,000]km'
WHEN kms_int > 40000 AND kms_int <= 60000 THEN '[40,000-60,000]km'
WHEN kms_int > 60000 AND kms_int <= 80000 THEN '[60,000-80,000]km'
WHEN kms_int > 80000 AND kms_int <= 100000 THEN '[80,000-100,000]km'
WHEN kms_int > 10000 THEN 'More than 100,000 km'
END);

-------------------------------------------------------------- How many cars in each Kilometers driven brackets -----------------------------------------------------------

SELECT km_driven_bracket, COUNT(i) number_of_cars
FROM car_resale
GROUP BY km_driven_bracket
ORDER BY COUNT(i) DESC;

-------------------------------------------------------------- Most popluar car for each city -----------------------------------------------------------

-- A CTE instead of temporary table to get the most popular cars and the index
WITH Temp as (SELECT city, MAX(m_number) number_of_cars, MAX(i) max_i
FROM (SELECT i, full_name, city, ROW_NUMBER() over (PARTITION BY full_name) AS m_number
FROM car_resale) a
GROUP BY city)

-- Use the CTE to get the car and city
SELECT t.city, c.full_name, t.number_of_cars
FROM Temp t
JOIN car_resale c ON c.i = t.max_i
ORDER BY number_of_cars DESC;

-------------------------------------------------------------- Most popluar transimission for each year -----------------------------------------------------------

SELECT * FROM car_resale;
SELECT registered_year, transimssion, COUNT(transimssion) Number_Of_Cars
FROM car_resale
GROUP BY registered_year, transimssion
ORDER BY registered_year DESC;
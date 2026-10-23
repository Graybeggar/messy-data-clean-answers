-- ============================================================
-- Messy Data, Clean Answers
-- 02_clean_data.sql
--
-- Turns the raw plant shop tables into clean, typed tables:
--   plants_clean, customers_clean, orders_clean
-- plus two ID maps and a data_quality_issues table that keeps
-- every rejected order line, with the reason it was rejected.
--
-- Cleaning rules applied:
--   * TRIM stray whitespace everywhere
--   * Categories mapped to one canonical spelling each
--   * Prices stripped of "$" and cast to REAL
--   * Emails lowercased; blank email becomes NULL
--   * Duplicate plants merged (stock added together)
--   * Duplicate customers merged (same person, two rows)
--   * Order dates standardized to ISO format (YYYY-MM-DD)
--   * Exact duplicate order lines removed
--   * Orders with missing price, missing quantity, or
--     quantity of 0 are NOT deleted silently: they are
--     recorded in data_quality_issues instead
-- ============================================================

DROP TABLE IF EXISTS plants_clean;
DROP TABLE IF EXISTS customers_clean;
DROP TABLE IF EXISTS orders_clean;
DROP TABLE IF EXISTS plant_id_map;
DROP TABLE IF EXISTS customer_id_map;
DROP TABLE IF EXISTS data_quality_issues;
DROP VIEW  IF EXISTS orders_std;

-- ------------------------------------------------------------
-- PLANTS: merge duplicates by normalized name, add their stock
-- ------------------------------------------------------------
CREATE TABLE plants_clean AS
WITH grouped AS (
    SELECT LOWER(TRIM(plant_name)) AS name_key,
           MIN(CAST(plant_id AS INTEGER)) AS keep_id,
           SUM(COALESCE(CAST(stock_qty AS INTEGER), 0)) AS total_stock
    FROM raw_plants
    GROUP BY name_key
)
SELECT g.keep_id AS plant_id,
       TRIM(p.plant_name) AS plant_name,
       CASE LOWER(TRIM(p.category))
           WHEN 'tropical'   THEN 'Tropical'
           WHEN 'vine'       THEN 'Vine'
           WHEN 'vines'      THEN 'Vine'
           WHEN 'fern'       THEN 'Fern'
           WHEN 'ferns'      THEN 'Fern'
           WHEN 'succulent'  THEN 'Succulent'
           WHEN 'succulents' THEN 'Succulent'
           WHEN 'flowering'  THEN 'Flowering'
           ELSE TRIM(p.category)
       END AS category,
       CAST(REPLACE(REPLACE(p.price, '$', ''), ',', '') AS REAL) AS price,
       g.total_stock AS stock_qty
FROM grouped g
JOIN raw_plants p ON CAST(p.plant_id AS INTEGER) = g.keep_id;

-- Which raw plant ID became which clean plant ID
CREATE TABLE plant_id_map AS
SELECT CAST(rp.plant_id AS INTEGER) AS old_plant_id,
       pc.plant_id AS clean_plant_id
FROM raw_plants rp
JOIN plants_clean pc
  ON LOWER(TRIM(rp.plant_name)) = LOWER(pc.plant_name);

-- ------------------------------------------------------------
-- CUSTOMERS: one row per person.
-- Duplicates are detected by lowercased email. The one
-- customer with no email on file is kept as her own row.
-- (The title-case expression below assumes two-word names,
--  which holds for this dataset.)
-- ------------------------------------------------------------
CREATE TABLE customer_email_groups AS
SELECT LOWER(TRIM(email)) AS email_key,
       MIN(CAST(customer_id AS INTEGER)) AS keep_id
FROM raw_customers
WHERE TRIM(email) <> ''
GROUP BY email_key;

CREATE TABLE customers_clean AS
SELECT CAST(c.customer_id AS INTEGER) AS customer_id,
       UPPER(SUBSTR(TRIM(c.full_name), 1, 1))
         || LOWER(SUBSTR(TRIM(c.full_name), 2, INSTR(TRIM(c.full_name), ' ') - 2))
         || ' '
         || UPPER(SUBSTR(TRIM(c.full_name), INSTR(TRIM(c.full_name), ' ') + 1, 1))
         || LOWER(SUBSTR(TRIM(c.full_name), INSTR(TRIM(c.full_name), ' ') + 2))
         AS full_name,
       NULLIF(LOWER(TRIM(c.email)), '') AS email,
       TRIM(c.city) AS city
FROM raw_customers c
WHERE TRIM(c.email) = ''
   OR CAST(c.customer_id AS INTEGER) IN (SELECT keep_id FROM customer_email_groups);

-- Which raw customer ID became which clean customer ID
CREATE TABLE customer_id_map AS
SELECT CAST(rc.customer_id AS INTEGER) AS old_customer_id,
       COALESCE(g.keep_id, CAST(rc.customer_id AS INTEGER)) AS clean_customer_id
FROM raw_customers rc
LEFT JOIN customer_email_groups g
  ON LOWER(TRIM(rc.email)) = g.email_key AND TRIM(rc.email) <> '';

DROP TABLE customer_email_groups;

-- ------------------------------------------------------------
-- ORDERS: dedupe, remap IDs, standardize dates, type values.
-- orders_std holds every distinct order line after cleanup;
-- it is then split into orders_clean (usable) and
-- data_quality_issues (rejected, with reasons).
-- ------------------------------------------------------------
CREATE VIEW orders_std AS
SELECT DISTINCT
    CAST(o.order_id AS INTEGER) AS order_id,
    cm.clean_customer_id AS customer_id,
    pm.clean_plant_id AS plant_id,
    CAST(o.quantity AS INTEGER) AS quantity,
    CASE
        WHEN o.order_date LIKE '____-__-__' THEN o.order_date
        WHEN o.order_date LIKE '____/__/__' THEN REPLACE(o.order_date, '/', '-')
        WHEN o.order_date LIKE '__/__/____' THEN
            SUBSTR(o.order_date, 7, 4) || '-' || SUBSTR(o.order_date, 1, 2) || '-' || SUBSTR(o.order_date, 4, 2)
        ELSE  -- 'Mon D, YYYY' format, e.g. Jan 7, 2026
            SUBSTR(o.order_date, -4) || '-'
            || CASE SUBSTR(o.order_date, 1, 3)
                   WHEN 'Jan' THEN '01' WHEN 'Feb' THEN '02' WHEN 'Mar' THEN '03'
                   WHEN 'Apr' THEN '04' WHEN 'May' THEN '05' WHEN 'Jun' THEN '06'
                   WHEN 'Jul' THEN '07' WHEN 'Aug' THEN '08' WHEN 'Sep' THEN '09'
                   WHEN 'Oct' THEN '10' WHEN 'Nov' THEN '11' WHEN 'Dec' THEN '12'
               END || '-'
            || printf('%02d', CAST(TRIM(REPLACE(SUBSTR(o.order_date, 5, 3), ',', '')) AS INTEGER))
    END AS order_date,
    CAST(REPLACE(REPLACE(o.unit_price, '$', ''), ',', '') AS REAL) AS unit_price
FROM raw_orders o
JOIN customer_id_map cm ON cm.old_customer_id = CAST(o.customer_id AS INTEGER)
JOIN plant_id_map pm ON pm.old_plant_id = CAST(o.plant_id AS INTEGER);

CREATE TABLE orders_clean AS
SELECT * FROM orders_std
WHERE quantity IS NOT NULL AND quantity > 0 AND unit_price IS NOT NULL;

CREATE TABLE data_quality_issues AS
SELECT order_id, customer_id, plant_id, quantity, order_date, unit_price,
       CASE
           WHEN quantity IS NULL THEN 'quantity missing'
           WHEN quantity <= 0 THEN 'quantity is zero'
           WHEN unit_price IS NULL THEN 'unit price missing'
       END AS issue
FROM orders_std
WHERE quantity IS NULL OR quantity <= 0 OR unit_price IS NULL;

DROP VIEW orders_std;

-- ------------------------------------------------------------
-- AUDIT: how much did cleaning actually change?
-- ------------------------------------------------------------
SELECT 'raw plants' AS check_name, COUNT(*) AS rows_count FROM raw_plants
UNION ALL SELECT 'clean plants', COUNT(*) FROM plants_clean
UNION ALL SELECT 'raw customers', COUNT(*) FROM raw_customers
UNION ALL SELECT 'clean customers', COUNT(*) FROM customers_clean
UNION ALL SELECT 'raw order lines', COUNT(*) FROM raw_orders
UNION ALL SELECT 'clean orders', COUNT(*) FROM orders_clean
UNION ALL SELECT 'rejected order lines', COUNT(*) FROM data_quality_issues;

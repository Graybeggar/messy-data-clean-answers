-- ============================================================
-- Messy Data, Clean Answers
-- 03_analysis_queries.sql
--
-- Three business questions, answered from the CLEAN tables
-- built by 02_clean_data.sql. Skills on display: INNER JOIN,
-- LEFT JOIN, GROUP BY with SUM and COUNT, ORDER BY, LIMIT.
-- ============================================================

-- ------------------------------------------------------------
-- QUESTION 1: Which plant category brings in the most revenue?
-- ------------------------------------------------------------
SELECT p.category,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(o.quantity) AS units_sold,
       ROUND(SUM(o.quantity * o.unit_price), 2) AS revenue
FROM orders_clean o
JOIN plants_clean p ON p.plant_id = o.plant_id
GROUP BY p.category
ORDER BY revenue DESC;

-- ------------------------------------------------------------
-- QUESTION 2: Who are the shop's top 5 customers by spending?
-- (Priya Nair counts once here, even though the raw data
--  listed her as two different customers.)
-- ------------------------------------------------------------
SELECT c.full_name,
       c.city,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(o.quantity * o.unit_price), 2) AS total_spent
FROM orders_clean o
JOIN customers_clean c ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name, c.city
ORDER BY total_spent DESC
LIMIT 5;

-- ------------------------------------------------------------
-- QUESTION 3a: Which plants in inventory have never sold?
-- A LEFT JOIN keeps every plant; the ones with no matching
-- order come back with NULL order fields.
-- ------------------------------------------------------------
SELECT p.plant_name,
       p.category,
       p.stock_qty,
       p.price
FROM plants_clean p
LEFT JOIN orders_clean o ON o.plant_id = p.plant_id
WHERE o.order_id IS NULL;

-- ------------------------------------------------------------
-- QUESTION 3b: And which plant is the best seller, by units?
-- ------------------------------------------------------------
SELECT p.plant_name,
       SUM(o.quantity) AS units_sold,
       ROUND(SUM(o.quantity * o.unit_price), 2) AS revenue
FROM orders_clean o
JOIN plants_clean p ON p.plant_id = o.plant_id
GROUP BY p.plant_id, p.plant_name
ORDER BY units_sold DESC
LIMIT 1;

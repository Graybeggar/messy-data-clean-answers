-- ============================================================
-- Messy Data, Clean Answers
-- 01_create_raw_tables.sql
--
-- Builds the RAW tables for a small plant shop, exactly as the
-- data arrived: inconsistent capitalization, stray spaces,
-- dollar signs in prices, mixed date formats, duplicate rows,
-- and missing values. Every column is TEXT on purpose, because
-- that is how messy real-world exports actually land.
--
-- The same data also lives in /data as CSV files.
-- Run order: 01 -> 02 -> 03
-- ============================================================

DROP TABLE IF EXISTS raw_plants;
DROP TABLE IF EXISTS raw_customers;
DROP TABLE IF EXISTS raw_orders;

CREATE TABLE raw_plants (
    plant_id   TEXT,
    plant_name TEXT,
    category   TEXT,
    price      TEXT,
    stock_qty  TEXT
);

CREATE TABLE raw_customers (
    customer_id TEXT,
    full_name   TEXT,
    email       TEXT,
    city        TEXT
);

CREATE TABLE raw_orders (
    order_id   TEXT,
    customer_id TEXT,
    plant_id   TEXT,
    quantity   TEXT,
    order_date TEXT,
    unit_price TEXT
);

-- ---------- PLANTS (note the duplicate Monstera and Pothos) ----------
INSERT INTO raw_plants VALUES
('1',  ' Monstera Deliciosa ', 'Tropical',   '29.99',  '14'),
('2',  'monstera deliciosa',   'tropical ',  '$29.99', '6'),
('3',  'Golden Pothos',        'Vine',       '12.50',  '40'),
('4',  'golden pothos ',       'vines',      '12.50',  NULL),
('5',  'Boston Fern',          'FERNS',      '18.00',  '25'),
('6',  'Echeveria',            'succulents', '8.99',   '60'),
('7',  'String of Pearls',     'Succulent',  '14.25',  '0'),
('8',  'Snake Plant',          'Tropical',   '22.00',  '18'),
('9',  'Peace Lily',           'Flowering',  NULL,     '12'),
('10', 'Spider Plant',         'vine',       '11.00',  '33'),
('11', 'ZZ Plant',             'TROPICAL',   '24.99',  '9'),
('12', 'Burro''s Tail',        'Succulent',  '9.50',   '47');

-- ---------- CUSTOMERS (Priya Nair appears twice, one email is blank) ----------
INSERT INTO raw_customers VALUES
('1', 'Ada Green',     'ada.green@example.com',    'Austin'),
('2', '  marcus reed', 'Marcus.Reed@example.com',  'Denver'),
('3', 'Priya Nair',    'priya.nair@example.com',   'Seattle'),
('4', 'Tom Becker',    'tom.becker@example.com',   'Chicago'),
('5', 'priya nair',    'PRIYA.NAIR@example.com',   'Seattle'),
('6', 'June Park',     'june.park@example.com',    'Portland'),
('7', 'Omar Haddad',   'omar.haddad@example.com',  'Denver'),
('8', 'Lena Vogel',    '',                         'Austin');

-- ---------- ORDERS (mixed date formats, one exact duplicate line,
--            one order with no price, one with quantity 0,
--            one with quantity missing) ----------
INSERT INTO raw_orders VALUES
('101', '1', '1',  '2', '2026-01-05', '29.99'),
('102', '2', '3',  '1', '01/06/2026', '12.50'),
('103', '3', '6',  '4', 'Jan 7, 2026', '8.99'),
('104', '5', '2',  '1', '2026/01/08', '29.99'),
('105', '4', '8',  '1', '2026-01-09', '22.00'),
('106', '6', '5',  '2', '01/10/2026', '18.00'),
('107', '7', '12', '3', '2026-01-11', '9.50'),
('108', '1', '10', '2', 'Jan 12, 2026', '11.00'),
('109', '8', '9',  '1', '2026-01-12', NULL),
('110', '2', '6',  '2', '2026-01-13', '8.99'),
('111', '3', '11', '1', '01/14/2026', '24.99'),
('112', '6', '7',  '1', '2026-01-15', '14.25'),
('113', '4', '4',  '3', 'Jan 16, 2026', '12.50'),
('113', '4', '4',  '3', 'Jan 16, 2026', '12.50'),
('114', '7', '8',  '2', '2026-01-17', '22.00'),
('115', '1', '6',  '6', '2026-01-18', '8.99'),
('116', '2', '12', '2', '01/19/2026', '9.50'),
('117', '6', '1',  '1', '2026-01-20', '29.99'),
('118', '3', '5',  '1', '2026-01-21', '18.00'),
('119', '4', '3',  '2', '01/22/2026', '12.50'),
('120', '7', '10', '0', '2026-01-23', '11.00'),
('121', '8', '12', NULL, '2026-01-24', '9.50');

-- =============================================================
-- Game Store Database — queries
-- Run after 01_schema.sql and 02_seed.sql.
-- Revenue everywhere = quantity * unit_price.
-- =============================================================


-- -------------------------------------------------------------
-- 1. Basic retrieval
-- -------------------------------------------------------------

-- 1.1 All customers
SELECT * FROM customer ORDER BY customer_id;

-- 1.2 Orders for one customer
SELECT * FROM customer_order
WHERE customer_id = 5
ORDER BY order_date;

-- 1.3 Orders placed after a date
SELECT * FROM customer_order
WHERE order_date > DATE '2025-04-01'
ORDER BY order_date;

-- 1.4 Orders with customer names (via view)
SELECT * FROM customer_orders ORDER BY order_date;


-- -------------------------------------------------------------
-- 2. Aggregates
-- -------------------------------------------------------------

-- 2.1 Orders per customer.
-- Grouped by customer_id, not by name: customers 1 and 16 are both
-- "John Doe" and must be counted separately. LEFT JOIN keeps customers
-- with zero orders.
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       COUNT(o.order_id) AS total_orders
FROM customer c
LEFT JOIN customer_order o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_orders DESC, c.customer_id;

-- 2.2 Revenue and units sold for one game
SELECT g.title,
       SUM(oi.quantity)                 AS units_sold,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_item oi
JOIN game g ON g.game_id = oi.game_id
WHERE oi.game_id = 2
GROUP BY g.game_id, g.title;

-- 2.3 Highest price each game has sold for
SELECT g.title,
       MAX(oi.unit_price) AS max_unit_price
FROM order_item oi
JOIN game g ON g.game_id = oi.game_id
GROUP BY g.game_id, g.title
ORDER BY max_unit_price DESC;

-- 2.4 Games with their suppliers
SELECT g.title, s.name AS supplier, sg.supplier_price
FROM supplier_game sg
JOIN game g     ON g.game_id     = sg.game_id
JOIN supplier s ON s.supplier_id = sg.supplier_id
ORDER BY g.title, sg.supplier_price;


-- -------------------------------------------------------------
-- 3. Business questions
-- -------------------------------------------------------------

-- 3.1 Revenue per month
SELECT date_trunc('month', o.order_date)::date AS month,
       COUNT(DISTINCT o.order_id)              AS orders,
       SUM(oi.quantity)                        AS units,
       SUM(oi.quantity * oi.unit_price)        AS revenue
FROM customer_order o
JOIN order_item oi ON oi.order_id = o.order_id
GROUP BY 1
ORDER BY 1;

-- 3.2 Top 5 customers by total spend (ties included)
SELECT customer_id, first_name, last_name, orders, total_spent
FROM (
    SELECT c.customer_id,
           c.first_name,
           c.last_name,
           COUNT(DISTINCT o.order_id)        AS orders,
           SUM(oi.quantity * oi.unit_price)  AS total_spent,
           RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS rnk
    FROM customer c
    JOIN customer_order o ON o.customer_id = c.customer_id
    JOIN order_item oi    ON oi.order_id   = o.order_id
    GROUP BY c.customer_id, c.first_name, c.last_name
) ranked
WHERE rnk <= 5
ORDER BY total_spent DESC;

-- 3.3 Games that have never been sold
SELECT g.game_id, g.title, g.platform
FROM game g
LEFT JOIN order_item oi ON oi.game_id = g.game_id
WHERE oi.game_id IS NULL
ORDER BY g.title;

-- 3.4 Cheapest supplier for each game (ties returned)
SELECT title, supplier, supplier_price
FROM (
    SELECT g.title,
           s.name AS supplier,
           sg.supplier_price,
           RANK() OVER (PARTITION BY sg.game_id ORDER BY sg.supplier_price) AS rnk
    FROM supplier_game sg
    JOIN game g     ON g.game_id     = sg.game_id
    JOIN supplier s ON s.supplier_id = sg.supplier_id
) ranked
WHERE rnk = 1
ORDER BY title;

-- 3.5 Gross margin per game: what we sold it for vs. the cheapest
-- supplier price available today.
WITH cheapest AS (
    SELECT game_id, MIN(supplier_price) AS best_cost
    FROM supplier_game
    GROUP BY game_id
)
SELECT g.title,
       SUM(oi.quantity)                                    AS units_sold,
       SUM(oi.quantity * oi.unit_price)                    AS revenue,
       SUM(oi.quantity * ch.best_cost)                     AS cost,
       SUM(oi.quantity * (oi.unit_price - ch.best_cost))   AS gross_margin,
       ROUND(100 * SUM(oi.quantity * (oi.unit_price - ch.best_cost))
                 / SUM(oi.quantity * oi.unit_price), 1)    AS margin_pct
FROM order_item oi
JOIN game g      ON g.game_id  = oi.game_id
JOIN cheapest ch ON ch.game_id = oi.game_id
GROUP BY g.game_id, g.title
ORDER BY gross_margin DESC;

-- 3.6 Revenue by platform
SELECT g.platform,
       SUM(oi.quantity)                 AS units,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_item oi
JOIN game g ON g.game_id = oi.game_id
GROUP BY g.platform
ORDER BY revenue DESC;

-- 3.7 Order totals (via view)
SELECT order_id, order_date, SUM(line_total) AS order_total
FROM order_details
GROUP BY order_id, order_date
ORDER BY order_id;


-- -------------------------------------------------------------
-- 4. Data changes (wrapped in a transaction and rolled back so
--    the script can be re-run against the same seed data)
-- -------------------------------------------------------------
BEGIN;

-- 4.1 Change the quantity on an order line
UPDATE order_item
SET quantity = 5
WHERE order_id = 1 AND game_id = 1;

-- 4.2 Change a supplier's price
UPDATE supplier_game
SET supplier_price = 37.99
WHERE supplier_id = 1 AND game_id = 1;

-- 4.3 Remove an order line
DELETE FROM order_item
WHERE order_id = 2 AND game_id = 3;

SELECT * FROM order_details WHERE order_id IN (1, 2);

ROLLBACK;


-- -------------------------------------------------------------
-- 5. Constraint demonstrations — each statement below is
--    EXPECTED TO FAIL. Uncomment one at a time to see the error.
-- -------------------------------------------------------------

-- Foreign key: customer 999 does not exist
-- INSERT INTO customer_order (customer_id, order_date) VALUES (999, '2025-07-01');

-- CHECK: quantity must be positive
-- INSERT INTO order_item (order_id, game_id, quantity, unit_price) VALUES (3, 1, 0, 59.99);

-- Primary key: game 1 is already on order 1
-- INSERT INTO order_item (order_id, game_id, quantity, unit_price) VALUES (1, 1, 1, 59.99);

-- Primary key: supplier 1 already offers game 1
-- INSERT INTO supplier_game (supplier_id, game_id, supplier_price) VALUES (1, 1, 30.00);

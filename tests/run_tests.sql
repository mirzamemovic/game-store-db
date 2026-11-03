-- =============================================================
-- Automated tests. Run after 01_schema.sql and 02_seed.sql.
-- Any failed check raises an exception and stops the script
-- (psql -v ON_ERROR_STOP=1), so CI turns red.
-- =============================================================

-- Hide the empty result rows; PASS/FAIL lines are printed as notices
\o /dev/null

-- -------------------------------------------------------------
-- Helper: assert that a statement is rejected with a given SQLSTATE
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.expect_error(stmt TEXT, expected_state TEXT, test_name TEXT)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE stmt;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE = expected_state THEN
            RAISE NOTICE 'PASS  %', test_name;
            RETURN;
        END IF;
        RAISE EXCEPTION 'FAIL  % — expected SQLSTATE %, got % (%)',
                        test_name, expected_state, SQLSTATE, SQLERRM;
    END;
    RAISE EXCEPTION 'FAIL  % — statement was accepted but should have been rejected', test_name;
END $$;

-- -------------------------------------------------------------
-- Helper: assert two values are equal
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.expect_equal(actual NUMERIC, expected NUMERIC, test_name TEXT)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF actual IS DISTINCT FROM expected THEN
        RAISE EXCEPTION 'FAIL  % — expected %, got %', test_name, expected, actual;
    END IF;
    RAISE NOTICE 'PASS  %', test_name;
END $$;


-- =============================================================
-- Integrity: the database must reject invalid data
-- (23503 foreign_key_violation, 23514 check_violation,
--  23505 unique_violation)
-- =============================================================
SELECT pg_temp.expect_error(
  $$INSERT INTO customer_order (customer_id, order_date) VALUES (999, '2025-07-01')$$,
  '23503', 'order for non-existent customer is rejected');

SELECT pg_temp.expect_error(
  $$INSERT INTO order_item (order_id, game_id, quantity, unit_price) VALUES (1, 999, 1, 10)$$,
  '23503', 'order line for non-existent game is rejected');

SELECT pg_temp.expect_error(
  $$DELETE FROM customer WHERE customer_id = 1$$,
  '23503', 'customer with orders cannot be deleted');

SELECT pg_temp.expect_error(
  $$INSERT INTO order_item (order_id, game_id, quantity, unit_price) VALUES (3, 1, 0, 59.99)$$,
  '23514', 'zero quantity is rejected');

SELECT pg_temp.expect_error(
  $$INSERT INTO order_item (order_id, game_id, quantity, unit_price) VALUES (3, 1, 1, -5)$$,
  '23514', 'negative price is rejected');

SELECT pg_temp.expect_error(
  $$INSERT INTO order_item (order_id, game_id, quantity, unit_price) VALUES (1, 1, 1, 59.99)$$,
  '23505', 'same game twice in one order is rejected');

SELECT pg_temp.expect_error(
  $$INSERT INTO supplier_game (supplier_id, game_id, supplier_price) VALUES (1, 1, 30)$$,
  '23505', 'duplicate supplier offer is rejected');

SELECT pg_temp.expect_error(
  $$INSERT INTO customer (first_name, last_name, email) VALUES ('X', 'Y', 'john.doe1@example.com')$$,
  '23505', 'duplicate customer email is rejected');


-- =============================================================
-- Cascades behave as designed
-- =============================================================
BEGIN;
DELETE FROM customer_order WHERE order_id = 1;
SELECT pg_temp.expect_equal(
  (SELECT COUNT(*) FROM order_item WHERE order_id = 1), 0,
  'deleting an order removes its lines');
ROLLBACK;


-- =============================================================
-- Seed data and report results
-- =============================================================
SELECT pg_temp.expect_equal((SELECT COUNT(*) FROM customer),       16, 'seed: 16 customers');
SELECT pg_temp.expect_equal((SELECT COUNT(*) FROM game),           18, 'seed: 18 games');
SELECT pg_temp.expect_equal((SELECT COUNT(*) FROM customer_order), 24, 'seed: 24 orders');
SELECT pg_temp.expect_equal((SELECT COUNT(*) FROM order_item),     37, 'seed: 37 order lines');

SELECT pg_temp.expect_equal(
  (SELECT SUM(quantity * unit_price) FROM order_item), 2329.48,
  'total revenue = 2329.48');

SELECT pg_temp.expect_equal(
  (SELECT SUM(line_total) FROM order_details),
  (SELECT SUM(quantity * unit_price) FROM order_item),
  'order_details view agrees with raw revenue');

SELECT pg_temp.expect_equal(
  (SELECT COUNT(*) FROM (
      SELECT c.customer_id
      FROM customer c JOIN customer_order o ON o.customer_id = c.customer_id
      WHERE c.first_name = 'John' AND c.last_name = 'Doe'
      GROUP BY c.customer_id) t), 2,
  'two customers with the same name are counted separately');

SELECT pg_temp.expect_equal(
  (SELECT COUNT(*) FROM game g
   LEFT JOIN order_item oi ON oi.game_id = g.game_id
   WHERE oi.game_id IS NULL), 3,
  'three games have never been sold');

SELECT pg_temp.expect_equal(
  (SELECT MIN(supplier_price) FROM supplier_game WHERE game_id = 1), 39.50,
  'cheapest supplier price for game 1 = 39.50');

\o
\echo
\echo 'All tests passed.'

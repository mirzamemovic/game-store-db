-- =============================================================
-- Game Store Database — schema
-- PostgreSQL 13+
-- Run order: 01_schema.sql -> 02_seed.sql -> 03_queries.sql
-- =============================================================

DROP VIEW  IF EXISTS order_details, customer_orders;
DROP TABLE IF EXISTS supplier_game, order_item, supplier, game, customer_order, customer CASCADE;

-- -------------------------------------------------------------
-- Customers
-- -------------------------------------------------------------
CREATE TABLE customer (
    customer_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name   VARCHAR(100) NOT NULL,
    last_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(255) NOT NULL UNIQUE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- Orders  ("order" is a reserved word, so the table is customer_order)
-- -------------------------------------------------------------
CREATE TABLE customer_order (
    order_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  INT  NOT NULL REFERENCES customer (customer_id) ON DELETE RESTRICT,
    order_date   DATE NOT NULL DEFAULT CURRENT_DATE
);

-- -------------------------------------------------------------
-- Games (catalogue). list_price is the current shelf price;
-- order_item.unit_price records what the customer actually paid.
-- -------------------------------------------------------------
CREATE TABLE game (
    game_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title       VARCHAR(200)  NOT NULL,
    genre       VARCHAR(100),
    platform    VARCHAR(100)  NOT NULL,
    list_price  NUMERIC(10,2) NOT NULL CHECK (list_price >= 0),
    UNIQUE (title, platform)
);

-- -------------------------------------------------------------
-- Order lines. One row per game per order (composite natural key).
-- unit_price is the price of ONE copy at the time of sale.
-- -------------------------------------------------------------
CREATE TABLE order_item (
    order_id    INT NOT NULL REFERENCES customer_order (order_id) ON DELETE CASCADE,
    game_id     INT NOT NULL REFERENCES game (game_id)            ON DELETE RESTRICT,
    quantity    INT NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, game_id)
);

-- -------------------------------------------------------------
-- Suppliers
-- -------------------------------------------------------------
CREATE TABLE supplier (
    supplier_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           VARCHAR(200) NOT NULL,
    contact_email  VARCHAR(255) NOT NULL UNIQUE
);

-- -------------------------------------------------------------
-- Which supplier offers which game, at what wholesale price.
-- M:N between supplier and game.
-- -------------------------------------------------------------
CREATE TABLE supplier_game (
    supplier_id     INT NOT NULL REFERENCES supplier (supplier_id) ON DELETE CASCADE,
    game_id         INT NOT NULL REFERENCES game (game_id)         ON DELETE CASCADE,
    supplier_price  NUMERIC(10,2) NOT NULL CHECK (supplier_price >= 0),
    PRIMARY KEY (supplier_id, game_id)
);

-- -------------------------------------------------------------
-- Indexes on foreign-key columns.
-- PostgreSQL does NOT index foreign keys automatically.
-- Composite PKs above already cover their leading column
-- (order_item.order_id, supplier_game.supplier_id).
-- -------------------------------------------------------------
CREATE INDEX idx_customer_order_customer ON customer_order (customer_id);
CREATE INDEX idx_customer_order_date     ON customer_order (order_date);
CREATE INDEX idx_order_item_game         ON order_item (game_id);
CREATE INDEX idx_supplier_game_game      ON supplier_game (game_id);

-- -------------------------------------------------------------
-- Reporting views
-- -------------------------------------------------------------
CREATE VIEW customer_orders AS
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       o.order_id,
       o.order_date
FROM customer_order o
JOIN customer c ON c.customer_id = o.customer_id;

CREATE VIEW order_details AS
SELECT o.order_id,
       o.order_date,
       o.customer_id,
       g.game_id,
       g.title                       AS game_title,
       oi.quantity,
       oi.unit_price,
       oi.quantity * oi.unit_price   AS line_total
FROM customer_order o
JOIN order_item oi ON oi.order_id = o.order_id
JOIN game g        ON g.game_id   = oi.game_id;

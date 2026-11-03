-- =============================================================
-- Game Store Database — sample data
-- Run after 01_schema.sql. IDs are assigned 1..n in insert order.
-- =============================================================

TRUNCATE supplier_game, order_item, supplier, customer_order, game, customer
    RESTART IDENTITY CASCADE;

-- -------------------------------------------------------------
-- Customers (16 is a second "John Doe" — different person, same name)
-- -------------------------------------------------------------
INSERT INTO customer (first_name, last_name, email) VALUES
('John',        'Doe',       'john.doe1@example.com'),
('Jane',        'Smith',     'jane.smith2@example.com'),
('James',       'Brown',     'james.brown3@example.com'),
('Mary',        'Johnson',   'mary.johnson4@example.com'),
('Patricia',    'Williams',  'patricia.williams5@example.com'),
('Robert',      'Jones',     'robert.jones6@example.com'),
('Michael',     'Garcia',    'michael.garcia7@example.com'),
('William',     'Martinez',  'william.martinez8@example.com'),
('David',       'Hernandez', 'david.hernandez9@example.com'),
('Joseph',      'Lopez',     'joseph.lopez10@example.com'),
('Charles',     'Gonzalez',  'charles.gonzalez11@example.com'),
('Thomas',      'Perez',     'thomas.perez12@example.com'),
('Christopher', 'Wilson',    'christopher.wilson13@example.com'),
('Daniel',      'Anderson',  'daniel.anderson14@example.com'),
('Matthew',     'Thomas',    'matthew.thomas15@example.com'),
('John',        'Doe',       'j.doe.gaming@example.com');

-- -------------------------------------------------------------
-- Games
-- -------------------------------------------------------------
INSERT INTO game (title, genre, platform, list_price) VALUES
('The Last of Us Part II',                  'Action-Adventure', 'PlayStation', 59.99),  -- 1
('The Witcher 3: Wild Hunt',                'RPG',              'PC',          39.99),  -- 2
('Halo Infinite',                           'Shooter',          'Xbox',        59.99),  -- 3
('Minecraft',                               'Sandbox',          'PC',          29.99),  -- 4
('Grand Theft Auto V',                      'Action-Adventure', 'PC',          29.99),  -- 5
('Red Dead Redemption 2',                   'Action-Adventure', 'PlayStation', 59.99),  -- 6
('Fortnite V-Bucks Bundle',                 'Battle Royale',    'PC',          19.99),  -- 7
('Cyberpunk 2077',                          'RPG',              'PC',          49.99),  -- 8
('The Legend of Zelda: Breath of the Wild', 'Adventure',        'Switch',      59.99),  -- 9
('Super Mario Odyssey',                     'Platformer',       'Switch',      49.99),  -- 10
('Uncharted 4: A Thief''s End',             'Action-Adventure', 'PlayStation', 19.99),  -- 11
('Animal Crossing: New Horizons',           'Simulation',       'Switch',      59.99),  -- 12
('Apex Legends Champion Edition',           'Battle Royale',    'PC',          39.99),  -- 13
('Call of Duty: Modern Warfare III',        'Shooter',          'PlayStation', 69.99),  -- 14
('Ghost of Tsushima',                       'Action-Adventure', 'PlayStation', 49.99),  -- 15
('Elden Ring',                              'RPG',              'PC',          59.99),  -- 16 (never sold)
('Hollow Knight',                           'Metroidvania',     'Switch',      14.99),  -- 17 (never sold)
('Forza Horizon 5',                         'Racing',           'Xbox',        59.99);  -- 18 (never sold)

-- -------------------------------------------------------------
-- Orders: January–June 2025
-- -------------------------------------------------------------
INSERT INTO customer_order (customer_id, order_date) VALUES
(1,  '2025-01-04'),  -- 1
(2,  '2025-01-09'),  -- 2
(3,  '2025-01-15'),  -- 3
(4,  '2025-01-22'),  -- 4
(5,  '2025-02-02'),  -- 5
(6,  '2025-02-11'),  -- 6
(7,  '2025-02-14'),  -- 7
(8,  '2025-02-27'),  -- 8
(1,  '2025-03-03'),  -- 9
(9,  '2025-03-10'),  -- 10
(10, '2025-03-18'),  -- 11
(2,  '2025-03-29'),  -- 12
(11, '2025-04-05'),  -- 13
(12, '2025-04-12'),  -- 14
(5,  '2025-04-20'),  -- 15
(13, '2025-04-30'),  -- 16
(14, '2025-05-06'),  -- 17
(16, '2025-05-13'),  -- 18
(1,  '2025-05-21'),  -- 19
(3,  '2025-05-28'),  -- 20
(15, '2025-06-02'),  -- 21
(16, '2025-06-09'),  -- 22
(7,  '2025-06-17'),  -- 23
(2,  '2025-06-25');  -- 24

-- -------------------------------------------------------------
-- Order lines. unit_price = price of ONE copy at time of sale
-- (can differ from today's list_price because of sales/discounts).
-- -------------------------------------------------------------
INSERT INTO order_item (order_id, game_id, quantity, unit_price) VALUES
(1,  1,  2, 59.99),
(1,  2,  1, 39.99),
(2,  3,  3, 49.99),
(2,  4,  1, 29.99),
(3,  5,  2, 29.99),
(3,  6,  1, 59.99),
(4,  7,  1, 19.99),
(4,  8,  2, 24.99),   -- sale price
(5,  9,  3, 59.99),
(5,  10, 1, 49.99),
(6,  11, 2, 19.99),
(6,  12, 1, 59.99),
(7,  13, 1, 39.99),
(7,  14, 2, 69.99),
(8,  15, 1, 49.99),
(9,  4,  2, 29.99),
(9,  15, 1, 39.99),   -- sale price
(10, 1,  1, 59.99),
(11, 8,  1, 49.99),
(11, 2,  1, 29.99),   -- sale price
(12, 12, 2, 59.99),
(13, 6,  1, 59.99),
(14, 9,  1, 59.99),
(14, 10, 1, 49.99),
(15, 14, 1, 69.99),
(16, 4,  3, 29.99),
(17, 3,  1, 59.99),
(18, 5,  1, 29.99),
(18, 7,  2, 19.99),
(19, 6,  1, 49.99),   -- sale price
(19, 1,  1, 59.99),
(20, 8,  1, 49.99),
(21, 13, 2, 39.99),
(22, 2,  1, 39.99),
(23, 11, 1, 19.99),
(24, 9,  1, 59.99),
(24, 12, 1, 59.99);

-- -------------------------------------------------------------
-- Suppliers
-- -------------------------------------------------------------
INSERT INTO supplier (name, contact_email) VALUES
('Balkan Game Distribution', 'orders@balkangames.example.com'),  -- 1
('EuroPlay Wholesale',       'sales@europlay.example.com'),      -- 2
('PixelSource',              'trade@pixelsource.example.com'),   -- 3
('NordicKeys',               'b2b@nordickeys.example.com'),      -- 4
('Adriatic Media',           'info@adriaticmedia.example.com');  -- 5

-- -------------------------------------------------------------
-- Supplier offers. Several games have competing suppliers.
-- -------------------------------------------------------------
INSERT INTO supplier_game (supplier_id, game_id, supplier_price) VALUES
(1, 1,  42.00), (2, 1,  39.50), (3, 1,  44.00),
(1, 2,  22.00), (4, 2,  19.75),
(2, 3,  41.00), (5, 3,  43.20),
(3, 4,  18.00), (4, 4,  17.50), (5, 4,  18.90),
(1, 5,  17.00), (2, 5,  16.40),
(1, 6,  40.00), (3, 6,  38.80),
(4, 7,  12.00),
(2, 8,  30.00), (4, 8,  31.50),
(5, 9,  45.00),
(5, 10, 36.00), (3, 10, 35.10),
(1, 11, 11.00),
(5, 12, 44.50),
(4, 13, 24.00),
(2, 14, 52.00), (1, 14, 50.90),
(3, 15, 33.00),
(4, 16, 41.00), (2, 16, 40.20),
(5, 17,  8.50),
(2, 18, 42.00);

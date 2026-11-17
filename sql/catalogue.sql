-- =====================================================================
-- Catalogue data: categories, products and the sample customer list
-- Run after schema.sql
-- =====================================================================

INSERT INTO category (category_id, category_name) VALUES
(1, 'Computers'),
(2, 'Accessories'),
(3, 'Phones'),
(4, 'Tablets'),
(5, 'Printers'),
(6, 'Wearables');

INSERT INTO product (product_id, name, description, price, stock, category_id, image_url) VALUES
(1,  'Laptop',              'Dell laptop V2025',                        2000.00,  5, 1, NULL),
(2,  'Mouse',               'Wireless Dell mouse',                        50.00, 20, 2, NULL),
(3,  'Keyboard',            'Mechanical gaming keyboard',                120.00, 15, 2, NULL),
(4,  'iPhone 15',           'Apple smartphone 128GB',                   3000.00,  8, 3, NULL),
(5,  'Samsung S24',         'Samsung Galaxy S24',                       2800.00, 10, 3, NULL),
(6,  'Business Laptop',     '15-inch laptop for office work',           3499.00, 10, 1, 'images/laptop.jpg'),
(7,  'Smartphone',          '128GB smartphone with dual SIM',           2499.00,  0, 3, 'images/smartphone.jpg'),
(8,  'Wireless Headphones', 'Over-ear Bluetooth headphones',             599.00, 18, 2, 'images/headphones.jpg'),
(9,  'Smartwatch',          'Fitness tracking and phone notifications',  899.00,  4, 6, 'images/smartwatch.jpg'),
(10, 'Tablet',              '11-inch tablet with stylus support',       1799.00, 12, 4, 'images/tablet.jpg'),
(11, 'Gaming Mouse',        'Programmable mouse with side buttons',      249.00, 30, 2, 'images/gaming-mouse.jpg'),
(12, 'Ultrabook',           'Thin and light 14-inch laptop',            4299.00,  3, 1, NULL),
(13, 'Desktop PC',          'Tower computer for home and office',       2899.00,  7, 1, NULL),
(14, 'Budget Smartphone',   'Affordable 64GB smartphone',                899.00, 22, 3, NULL),
(15, 'Foldable Phone',      'Large folding display',                    5999.00,  2, 3, NULL),
(16, 'USB-C Charger',       '65W fast wall charger',                      79.00,  0, 2, NULL),
(17, 'Bluetooth Speaker',   'Portable water-resistant speaker',          199.00,  5, 2, NULL),
(18, 'Fitness Band',        'Step, sleep, and heart rate tracker',       299.00, 20, 6, NULL),
(19, 'Wireless Earbuds',    'Compact earbuds with charging case',        449.00,  9, 2, NULL),
(20, 'Laser Printer',       'Compact black-and-white office printer',    899.00,  6, 5, NULL);

INSERT INTO customer (customer_id, name, email) VALUES
(1, 'Ahmed Ali',     'ahmed@example.com'),
(2, 'Sara Khan',     'sara@example.com'),
(3, 'John Smith',    'john@example.com'),
(4, 'Fatima Hassan', 'fatima@example.com'),
(5, 'Omar Ahmed',    'omar@example.com');

-- Explicit ids were used above, so move each sequence past them
SELECT setval('category_category_id_seq', (SELECT MAX(category_id) FROM category));
SELECT setval('product_product_id_seq',   (SELECT MAX(product_id)  FROM product));
SELECT setval('customer_customer_id_seq', (SELECT MAX(customer_id) FROM customer));

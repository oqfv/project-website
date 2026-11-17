-- =====================================================================
-- Analytics KPIs  (the orders table is named "orderr")
-- Run each query on its own in the Supabase SQL Editor, then
-- export the result as CSV (results panel -> Export -> Download CSV).
-- =====================================================================

-- 1. Total revenue, number of orders, average order value
SELECT
    SUM(total) AS total_revenue,
    COUNT(*) AS number_of_orders,
    ROUND(AVG(total), 2) AS avg_order_value
FROM "orderr"
WHERE status != 'Cancelled';


-- 2. Number of customers
SELECT COUNT(DISTINCT customer_id) AS number_of_customers
FROM "orderr"
WHERE status != 'Cancelled';


-- 3. Top-selling products
SELECT
    p.name,
    SUM(oi.quantity) AS units_sold
FROM order_item oi
JOIN product p
    ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY units_sold DESC
LIMIT 10;


-- 4. Revenue by category
SELECT
    c.category_name,
    SUM(oi.quantity * oi.price) AS category_revenue
FROM order_item oi
JOIN product p
    ON oi.product_id = p.product_id
JOIN category c
    ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY category_revenue DESC;


-- 5. Monthly sales trend
SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(total) AS monthly_revenue
FROM "orderr"
WHERE status != 'Cancelled'
GROUP BY month
ORDER BY month;


-- 6. Order status distribution
SELECT
    status,
    COUNT(*) AS orders
FROM "orderr"
GROUP BY status;


-- =====================================================================
-- Helper queries for the business interpretation questions
-- =====================================================================

-- Category revenue vs. number of products in the category
SELECT
    c.category_name,
    COUNT(DISTINCT p.product_id) AS products_in_catalogue,
    COALESCE(SUM(oi.quantity * oi.price), 0) AS category_revenue
FROM category c
LEFT JOIN product p ON p.category_id = c.category_id
LEFT JOIN order_item oi ON oi.product_id = p.product_id
GROUP BY c.category_name
ORDER BY category_revenue DESC;


-- Units sold vs. current stock (what to promote or restock)
SELECT
    p.name,
    p.stock,
    COALESCE(SUM(oi.quantity), 0) AS units_sold
FROM product p
LEFT JOIN order_item oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.name, p.stock
ORDER BY units_sold DESC, p.stock DESC;


-- =====================================================================
-- Dashboard export: every dataset above in ONE result.
-- Export this as CSV and use it to build the dashboard workbook.
-- =====================================================================
SELECT section, label, value, value2
FROM (
    SELECT 'KPI' AS section, 'Total revenue' AS label, SUM(total) AS value, NULL::numeric AS value2, 1 AS sort
    FROM orderr WHERE status != 'Cancelled'
    UNION ALL
    SELECT 'KPI', 'Number of orders', COUNT(*), NULL, 2
    FROM orderr WHERE status != 'Cancelled'
    UNION ALL
    SELECT 'KPI', 'Average order value', ROUND(AVG(total), 2), NULL, 3
    FROM orderr WHERE status != 'Cancelled'
    UNION ALL
    SELECT 'KPI', 'Number of customers', COUNT(DISTINCT customer_id), NULL, 4
    FROM orderr WHERE status != 'Cancelled'
    UNION ALL
    SELECT 'TopProducts', name, units_sold, NULL, ROW_NUMBER() OVER (ORDER BY units_sold DESC, name)::int
    FROM (
        SELECT p.name, SUM(oi.quantity) AS units_sold
        FROM order_item oi JOIN product p ON oi.product_id = p.product_id
        GROUP BY p.name
        ORDER BY units_sold DESC, p.name
        LIMIT 10
    ) t
    UNION ALL
    SELECT 'RevenueByCategory', c.category_name, SUM(oi.quantity * oi.price), NULL, 0
    FROM order_item oi
    JOIN product p ON oi.product_id = p.product_id
    JOIN category c ON p.category_id = c.category_id
    GROUP BY c.category_name
    UNION ALL
    SELECT 'MonthlyRevenue', TO_CHAR(DATE_TRUNC('month', order_date), 'YYYY-MM'), SUM(total), NULL, 0
    FROM orderr WHERE status != 'Cancelled'
    GROUP BY DATE_TRUNC('month', order_date)
    UNION ALL
    SELECT 'OrderStatus', COALESCE(status, 'Unknown'), COUNT(*), NULL, 0
    FROM orderr
    GROUP BY status
    UNION ALL
    SELECT 'CategoryProducts', c.category_name, COUNT(p.product_id), NULL, 0
    FROM category c LEFT JOIN product p ON p.category_id = c.category_id
    GROUP BY c.category_name
    UNION ALL
    SELECT 'StockVsSales', p.name, COALESCE(SUM(oi.quantity), 0), p.stock, 0
    FROM product p LEFT JOIN order_item oi ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.name, p.stock
) all_data
ORDER BY section, sort, label;

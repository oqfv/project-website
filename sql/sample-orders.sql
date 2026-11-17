-- =====================================================================
-- Sample order data for the analytics dashboard. Run after catalogue.sql.
--
-- 1. Creates a login account (auth.users) for each sample customer, so
--    orders can belong to them. These accounts have no password and
--    use @example.com addresses: nobody can log in with them.
-- 2. Adds the 5 original Lab 3 sample orders.
-- 3. Generates 36 orders from June to mid-November 2026 with mixed
--    statuses (including some Cancelled).
--
-- Generated orders are stamped with 777 microseconds in order_date,
-- so the DELETE at the bottom removes exactly those 36 orders.
-- =====================================================================

-- 1. Sample customer accounts
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
SELECT
  '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
  c.email, '',
  '{"provider": "email", "providers": ["email"]}', jsonb_build_object('name', c.name),
  c.created_at, c.created_at,
  '', '', '', ''
FROM customer c
WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.email = c.email);


-- 2. Original Lab 3 sample orders (one per sample customer)
INSERT INTO orderr (customer_id, order_date, status, total)
SELECT u.id, TIMESTAMP '2026-10-05 13:54:43', v.status, v.total
FROM (VALUES
  (1, 'ahmed@example.com',  'Pending',   2000.00),
  (2, 'sara@example.com',   'Completed',   50.00),
  (3, 'john@example.com',   'Shipped',   3000.00),
  (4, 'fatima@example.com', 'Completed', 2800.00),
  (5, 'omar@example.com',   'Pending',    120.00)
) AS v(n, email, status, total)
JOIN auth.users u ON u.email = v.email
ORDER BY v.n;

-- Laptop, Mouse, iPhone 15, Samsung S24, Keyboard (matched by price)
INSERT INTO order_item (order_id, product_id, quantity, price)
SELECT o.order_id, p.product_id, 1, p.price
FROM orderr o
JOIN product p ON p.price = o.total
  AND p.product_id IN (1, 2, 3, 4, 5)
WHERE o.order_date = TIMESTAMP '2026-10-05 13:54:43';


-- 3. Generated orders, June to mid-November 2026
DO $$
DECLARE
  users     uuid[] := ARRAY(
                SELECT u.id FROM auth.users u
                JOIN customer c ON c.email = u.email
                ORDER BY c.customer_id);
  per_month int[]  := ARRAY[4, 5, 7, 6, 8, 6];   -- Jun, Jul, Aug, Sep, Oct, Nov
  m         int;
  k         int;
  d         timestamp;
  new_id    int;
  st        text;
  r         float;
  prod      record;
BEGIN
  IF array_length(users, 1) IS NULL THEN
    RAISE EXCEPTION 'No sample customer accounts found';
  END IF;

  PERFORM setseed(0.42);

  FOR m IN 1..6 LOOP
    FOR k IN 1..per_month[m] LOOP
      d := make_timestamp(
             2026, 5 + m,
             1 + floor(random() * (CASE WHEN m = 6 THEN 15 ELSE 28 END))::int,
             10 + floor(random() * 10)::int,
             floor(random() * 60)::int,
             0.000777);

      r := random();
      IF m <= 4 THEN
        st := CASE WHEN r < 0.12 THEN 'Cancelled' ELSE 'Delivered' END;
      ELSIF m = 5 THEN
        st := CASE WHEN r < 0.10 THEN 'Cancelled' WHEN r < 0.70 THEN 'Delivered' ELSE 'Shipped' END;
      ELSE
        st := CASE WHEN r < 0.10 THEN 'Cancelled' WHEN r < 0.40 THEN 'Shipped'
                   WHEN r < 0.70 THEN 'Processing' ELSE 'Paid' END;
      END IF;

      INSERT INTO orderr (customer_id, order_date, status, total)
      VALUES (users[1 + floor(random() * array_length(users, 1))::int], d, st, 0)
      RETURNING order_id INTO new_id;

      FOR prod IN
        SELECT product_id, price FROM product
        WHERE stock > 0
        ORDER BY random()
        LIMIT 1 + floor(random() * 3)::int
      LOOP
        INSERT INTO order_item (order_id, product_id, quantity, price)
        VALUES (new_id, prod.product_id,
                CASE WHEN prod.price < 500 THEN 1 + floor(random() * 3)::int ELSE 1 END,
                prod.price);
      END LOOP;

      UPDATE orderr
      SET total = (SELECT SUM(quantity * price) FROM order_item WHERE order_id = new_id)
      WHERE order_id = new_id;
    END LOOP;
  END LOOP;
END $$;

-- Check
SELECT
  COUNT(*) AS all_orders,
  COUNT(*) FILTER (WHERE EXTRACT(microseconds FROM order_date)::bigint % 1000000 = 777) AS generated_orders
FROM orderr;


-- =====================================================================
-- To REMOVE the 36 generated orders later, run these two lines:
-- =====================================================================
-- DELETE FROM order_item WHERE order_id IN (SELECT order_id FROM orderr WHERE EXTRACT(microseconds FROM order_date)::bigint % 1000000 = 777);
-- DELETE FROM orderr WHERE EXTRACT(microseconds FROM order_date)::bigint % 1000000 = 777;

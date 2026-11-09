-- =====================================================================
-- Checkout and orders  (the orders table is named "orderr")
-- The schema change and RLS policies below are already applied in Supabase.
-- =====================================================================

-- Schema change: customer_id = Supabase Auth user id (UUID)
ALTER TABLE orderr DROP CONSTRAINT orderr_customer_id_fkey;
ALTER TABLE orderr ALTER COLUMN customer_id TYPE UUID USING NULL;
ALTER TABLE orderr ADD CONSTRAINT orderr_customer_id_fkey
  FOREIGN KEY (customer_id) REFERENCES auth.users(id);

-- RLS policies: customers can only create/view their own orders
ALTER TABLE orderr ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can insert their own orders" ON orderr
  FOR INSERT WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Customers can view their own orders" ON orderr
  FOR SELECT USING (auth.uid() = customer_id);

ALTER TABLE order_item ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can insert their own order items" ON order_item
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM orderr WHERE order_id = order_item.order_id AND customer_id = auth.uid())
  );

CREATE POLICY "Customers can view their own order items" ON order_item
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM orderr WHERE order_id = order_item.order_id AND customer_id = auth.uid())
  );

-- =====================================================================
-- Order-status updates — run these one at a time in the SQL Editor
-- (replace 1 with your real order_id)
-- =====================================================================
SELECT * FROM orderr ORDER BY order_id DESC;

UPDATE orderr SET status = 'Processing' WHERE order_id = 1;
UPDATE orderr SET status = 'Shipped'    WHERE order_id = 1;
UPDATE orderr SET status = 'Delivered'  WHERE order_id = 1;

-- Evidence query: order with its items and product names
SELECT o.order_id, o.status, o.total, p.name, oi.quantity, oi.price
FROM orderr o
JOIN order_item oi ON oi.order_id = o.order_id
JOIN product p     ON p.product_id = oi.product_id
ORDER BY o.order_id DESC;

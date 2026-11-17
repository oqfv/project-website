-- =====================================================================
-- ShopNow database schema (Supabase project "ShopNow")
-- Tables: category, product, customer, orderr, order_item
-- =====================================================================

CREATE TABLE category (
  category_id SERIAL PRIMARY KEY,
  category_name TEXT NOT NULL
);

CREATE TABLE product (
  product_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  category_id INTEGER REFERENCES category(category_id),
  image_url TEXT
);

CREATE TABLE customer (
  customer_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);

-- "order" is a reserved word, so the table is named orderr.
-- customer_id is the Supabase Auth user id of whoever placed the order.
CREATE TABLE orderr (
  order_id SERIAL PRIMARY KEY,
  customer_id UUID REFERENCES auth.users(id),
  order_date TIMESTAMP DEFAULT now(),
  status TEXT DEFAULT 'Pending',
  total NUMERIC(10,2) NOT NULL DEFAULT 0
);

CREATE TABLE order_item (
  order_item_id SERIAL PRIMARY KEY,
  order_id INTEGER REFERENCES orderr(order_id),
  product_id INTEGER REFERENCES product(product_id),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  price NUMERIC(10,2) NOT NULL
);

-- Indexes on foreign keys (used by joins and by the RLS checks below)
CREATE INDEX product_category_id_idx ON product (category_id);
CREATE INDEX orderr_customer_id_idx ON orderr (customer_id);
CREATE INDEX order_item_order_id_idx ON order_item (order_id);
CREATE INDEX order_item_product_id_idx ON order_item (product_id);

-- =====================================================================
-- Row Level Security
-- =====================================================================
ALTER TABLE category ENABLE ROW LEVEL SECURITY;
ALTER TABLE product ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer ENABLE ROW LEVEL SECURITY;
ALTER TABLE orderr ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_item ENABLE ROW LEVEL SECURITY;

-- Anyone can browse the catalogue
CREATE POLICY "Public read access" ON category FOR SELECT USING (true);
CREATE POLICY "Public read access" ON product FOR SELECT USING (true);

-- Customers can only create and view their own orders
CREATE POLICY "Customers can insert their own orders" ON orderr
  FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = customer_id);

CREATE POLICY "Customers can view their own orders" ON orderr
  FOR SELECT TO authenticated USING ((select auth.uid()) = customer_id);

CREATE POLICY "Customers can insert their own order items" ON order_item
  FOR INSERT TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM orderr WHERE orderr.order_id = order_item.order_id AND orderr.customer_id = (select auth.uid()))
  );

CREATE POLICY "Customers can view their own order items" ON order_item
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM orderr WHERE orderr.order_id = order_item.order_id AND orderr.customer_id = (select auth.uid()))
  );

-- API access (RLS above still decides which rows each user can see)
GRANT SELECT ON category, product TO anon, authenticated;
GRANT SELECT, INSERT ON orderr, order_item TO authenticated;
GRANT USAGE ON SEQUENCE orderr_order_id_seq, order_item_order_item_id_seq TO authenticated;

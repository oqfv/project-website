# ShopNow — INT424 E-Commerce Project

A small e-commerce storefront built with plain HTML, CSS and JavaScript, using Supabase for the
database and user accounts.

## Pages
| Page | What it does |
|---|---|
| `index.html` | Home page with featured products |
| `products.html` | Full catalogue with search, category filter and price sorting |
| `product-detail.html` | Details for one product |
| `cart.html` | Shopping cart stored in localStorage |
| `register.html` / `login.html` | Sign-up and login with Supabase Auth |
| `checkout.html` | Shipping form + Place Order |
| `order-confirmation.html` | Order number, items and total |

## Database (Supabase)
Tables: `category`, `product`, `customer`, `orderr`, `order_item`.

SQL scripts are in [`sql/`](sql/):
- [`checkout-orders.sql`](sql/checkout-orders.sql): orders linked to logged-in users, row-level security, order-status updates

## Checkout and orders

### Transaction flow
Product → Cart (localStorage) → Checkout form → `orderr` + `order_item` rows created in Supabase → Confirmation page.

### Where a real payment gateway would fit
Payment is simulated, so clicking "Place Order" inserts the order with status "Paid" straight away.
A real payment gateway such as Stripe would sit between "checkout form submitted" and "order
created". After the form is validated, the customer would be sent to the gateway's secure payment
page (so card details never touch this site). The gateway charges the card and confirms success
back to the application, usually through a webhook to a server function. Only after that
confirmation should the `orderr` and `order_item` rows be created (or a "Pending" order be updated
to "Paid"). If the payment fails, no paid order is created and the cart is kept.

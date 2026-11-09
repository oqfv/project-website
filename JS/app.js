const SUPABASE_URL = "https://trqaicnxwkcyktxwyseg.supabase.co";

const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRycWFpY254d2tjeWt0eHd5c2VnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyMDA0MjIsImV4cCI6MjEwNjc3NjQyMn0.U7agC3JIWaO6AXIpPWGsBUD1cgaxr32jqgROCXO6JSY";

const supabaseClient = window.supabase.createClient(
    SUPABASE_URL,
    SUPABASE_ANON_KEY
);

// Store products loaded from Supabase
let allProducts = [];

let currentCategory = "All";
let searchTerm = "";
let sortOrder = "default";

// Display Products
function renderProducts(list, container) {

    if (!container) return;

    if (list.length === 0) {
        container.innerHTML = "<p>No products found.</p>";
        return;
    }

    container.innerHTML = list.map(prod => {

        const image = prod.image_url
            ? `<img src="${prod.image_url}" alt="${prod.name}" onerror="this.remove()">`
            : "";

        const stockText = prod.stock > 0
            ? `Stock: ${prod.stock}`
            : `<span class="out-of-stock">Out of stock</span>`;

        return `
            <div class="product">

                ${image}

                <h3>${prod.name}</h3>

                <p class="price">AED ${Number(prod.price).toFixed(2)}</p>

                <p>${stockText}</p>

                <button onclick="addToCartById(${prod.product_id})" ${prod.stock > 0 ? "" : "disabled"}>
                    Add to Cart
                </button>

                <a href="product-detail.html?id=${prod.product_id}">
                    View Details
                </a>

            </div>
        `;

    }).join("");
}

// Search, Category Filter and Sorting
function updateProductView() {

    let filtered = [...allProducts];

    // Category filter
    if (currentCategory !== "All") {
        filtered = filtered.filter(
            p => p.category?.category_name === currentCategory
        );
    }

    // Search filter
    filtered = filtered.filter(
        p => p.name.toLowerCase().includes(searchTerm)
    );

    // Price sorting
    if (sortOrder === "low-high") {
        filtered.sort((a, b) => a.price - b.price);
    }

    if (sortOrder === "high-low") {
        filtered.sort((a, b) => b.price - a.price);
    }

    renderProducts(filtered, document.getElementById("product-list"));
}

// Load Products from Supabase
async function loadProducts() {

    const container = document.getElementById("product-list");
    const featured = document.getElementById("featured-products");

    if (!container && !featured) return;

    (container || featured).innerHTML = "<p>Loading products...</p>";

    const { data, error } = await supabaseClient
        .from("product")
        .select("*, category(category_name)")
        .order("product_id");

    if (error) {

        console.error("Supabase Error:", error);

        (container || featured).innerHTML =
            `<p>Could not load products: ${error.message}</p>`;

        return;
    }

    allProducts = data || [];

    if (container) {
        updateProductView();
    }

    // Home page: show the first 4 in-stock products
    if (featured) {
        renderProducts(
            allProducts.filter(p => p.stock > 0).slice(0, 4),
            featured
        );
    }
}

// Search
const searchBox = document.getElementById("search-box");

if (searchBox) {

    searchBox.addEventListener("input", e => {

        searchTerm = e.target.value.toLowerCase();

        updateProductView();
    });
}

// Category Filter
document.querySelectorAll(".category-btn").forEach(btn => {

    btn.addEventListener("click", () => {

        currentCategory = btn.dataset.category;

        document.querySelectorAll(".category-btn")
            .forEach(b => b.classList.toggle("active", b === btn));

        updateProductView();
    });

});

// Price Sorting
const sortSelect = document.getElementById("sort-select");

if (sortSelect) {

    sortSelect.addEventListener("change", e => {

        sortOrder = e.target.value;

        updateProductView();
    });
}

// Start loading
loadProducts();

// cart shopping code
function getCart() {
    return JSON.parse(
        localStorage.getItem("cart") || "[]"
    );
}

// save cart function
function saveCart(cart) {
    localStorage.setItem(
        "cart",
        JSON.stringify(cart)
    );
}

// Update product quantity
function updateQuantity(productId, quantity) {

    const cart = getCart();

    const item = cart.find(
        p => String(p.product_id) === String(productId)
    );

    if (!item) return;

    const newQuantity = parseInt(quantity);

    if (isNaN(newQuantity) || newQuantity < 1) {
        return;
    }

    item.quantity = newQuantity;

    saveCart(cart);
}

// Remove product from cart
function removeFromCart(productId) {

    let cart = getCart();

    cart = cart.filter(
        p => String(p.product_id) !== String(productId)
    );

    saveCart(cart);
}

// add product to cart
function addToCart(product) {

    const cart = getCart();

    const existing = cart.find(
        item => item.product_id === product.product_id
    );

    if (existing) {

        existing.quantity += 1;

    } else {

        cart.push({
            product_id: product.product_id,
            name: product.name,
            price: Number(product.price),
            quantity: 1
        });
    }

    saveCart(cart);

    alert("Product added to cart!");
}

// look up a loaded product by id, then add it to the cart
function addToCartById(productId) {

    const product = allProducts.find(
        p => p.product_id === productId
    );

    if (product) {
        addToCart(product);
    }
}

// render card function
function renderCart() {
    const cart = getCart();
    const container = document.getElementById("cart-items");

    if (cart.length === 0) {
        container.innerHTML = "<p>Your cart is empty.</p>";
        document.getElementById("subtotal").textContent = "0.00";
        return;
    }

    let subtotal = 0;

    container.innerHTML = cart.map(item => {
        const lineTotal = item.price * item.quantity;
        subtotal += lineTotal;

        return `
            <div class="cart-item">
                <span>${item.name}</span>

                <input
                    type="number"
                    min="1"
                    value="${item.quantity}"
                    onchange="
                        updateQuantity(
                            ${item.product_id},
                            this.value
                        );
                        renderCart();
                    "
                >

                <span>AED ${lineTotal.toFixed(2)}</span>

                <button
                    onclick="
                        removeFromCart(${item.product_id});
                        renderCart();
                    "
                >
                    Remove
                </button>
            </div>
        `;
    }).join("");

    document.getElementById("subtotal").textContent =
        subtotal.toFixed(2);
}

if (document.getElementById("cart-items")) {
    renderCart();
}

// registeration steps.......................................................
const registerForm = document.getElementById("register-form");

if (registerForm) {

    registerForm.addEventListener("submit", async (e) => {

        e.preventDefault();

        const email = document.getElementById("email").value.trim();
        const password = document.getElementById("password").value;

        try {

            const { data, error } = await supabaseClient.auth.signUp({
                email: email,
                password: password
            });

            if (error) {
                alert("Registration Error: " + error.message);
                console.error(error);
                return;
            }

            alert("Account created — you can now log in.");

            console.log("Registration result:", data);

            window.location.href = "login.html";

        } catch (err) {

            console.error("Unexpected error:", err);
            alert("Something went wrong. Check the browser console.");

        }

    });
}
//User logging............................................
const loginForm = document.getElementById("login-form");

if (loginForm) {

    loginForm.addEventListener("submit", async e => {

        e.preventDefault();

        const email = document.getElementById("email").value;
        const password = document.getElementById("password").value;

        const { error } = await supabaseClient.auth.signInWithPassword({
            email,
            password
        });

        if (error) {
            alert(error.message);
        } else {
            window.location.href = "index.html";
        }
    });
}
//checking steps....................................................................
const checkoutButton =
    document.getElementById("checkout-btn");

if (checkoutButton) {

    checkoutButton.addEventListener("click", async () => {

        const user = await requireLogin();

        if (!user) return;

        const cart = getCart();

        if (cart.length === 0) {
            alert("Your cart is empty!");
            return;
        }

        window.location.href = "checkout.html";

    });
}

// Update NAV For Auth
async function updateNavForAuth() {
    const {
        data: { user }
    } = await supabaseClient.auth.getUser();

    const navSlot =
        document.getElementById("auth-nav-slot");

    if (!navSlot) return;

    if (user) {
        navSlot.innerHTML = `
            <span>Hi, ${user.email}</span>
            <a href="#" id="logout-link">Log out</a>
        `;

        document
            .getElementById("logout-link")
            .addEventListener("click", async e => {
                e.preventDefault();
                await logout();
            });

    } else {
        navSlot.innerHTML =
            '<a href="login.html">Login</a>';
    }
}

//User logging out
async function logout() {
    const { error } = await supabaseClient.auth.signOut();

    if (error) {
        alert(error.message);
        return;
    }

    window.location.href = "index.html";

}

updateNavForAuth();

// Restrict checkout to logged-in users
async function requireLogin() {
    const {
        data: { user },
        error
    } = await supabaseClient.auth.getUser();

    if (error || !user) {
        window.location.href = "login.html";
        return null;
    }

    return user;
}

// =====================================================================
// Checkout and Orders
// =====================================================================

// Checkout page: show order summary............................................
function renderCheckoutSummary() {
    const cart = getCart();
    const container = document.getElementById("checkout-summary");

    if (cart.length === 0) {
        container.innerHTML = "<p>Your cart is empty.</p>";
        return;
    }

    let subtotal = 0;

    container.innerHTML = cart.map(item => {
        const lineTotal = item.price * item.quantity;
        subtotal += lineTotal;

        return `<p>${item.name} × ${item.quantity} — AED ${lineTotal.toFixed(2)}</p>`;
    }).join("");

    document.getElementById("checkout-total").textContent =
        subtotal.toFixed(2);
}

if (document.getElementById("checkout-summary")) {
    renderCheckoutSummary();
}

// Checkout form: validate shipping information.................................
const checkoutForm = document.getElementById("checkout-form");

if (checkoutForm) {

    checkoutForm.addEventListener("submit", async e => {

        e.preventDefault();

        const name = document.getElementById("name").value.trim();
        const address = document.getElementById("address").value.trim();
        const phone = document.getElementById("phone").value.trim();

        if (!name || !address) {
            alert("Name and address are required.");
            return;
        }

        if (!/^[0-9+ ]{7,15}$/.test(phone)) {
            alert("Enter a valid phone number.");
            return;
        }

        await placeOrder(name, address, phone);
    });
}

// Create the Order and Order_Item rows.........................................
async function placeOrder(name, address, phone) {

    const {
        data: { user }
    } = await supabaseClient.auth.getUser();

    if (!user) {
        window.location.href = "login.html";
        return;
    }

    const cart = getCart();

    if (cart.length === 0) {
        alert("Your cart is empty!");
        return;
    }

    const subtotal = cart.reduce(
        (sum, item) => sum + item.price * item.quantity,
        0
    );

    // Payment is simulated: a real gateway (e.g. Stripe) would confirm
    // the charge HERE, before the order row is created.
    const { data: order, error } = await supabaseClient
        .from("orderr")
        .insert([{
            customer_id: user.id,
            total: subtotal,
            status: "Paid"
        }])
        .select()
        .single();

    if (error) {
        console.error(error);
        alert("Could not place order: " + error.message);
        return;
    }

    const items = cart.map(item => ({
        order_id: order.order_id,
        product_id: item.product_id,
        quantity: item.quantity,
        price: item.price
    }));

    const { error: itemsError } = await supabaseClient
        .from("order_item")
        .insert(items);

    if (itemsError) {
        console.error(itemsError);
        alert("Order was created but items could not be saved: " + itemsError.message);
        return;
    }

    // Clear the cart only after BOTH inserts succeeded
    localStorage.removeItem("cart");

    window.location.href = `order-confirmation.html?id=${order.order_id}`;
}

// Order confirmation page......................................................
async function loadConfirmation() {

    const user = await requireLogin();

    if (!user) return;

    const orderId = new URLSearchParams(window.location.search).get("id");

    const { data: order, error: orderError } = await supabaseClient
        .from("orderr")
        .select("*")
        .eq("order_id", orderId)
        .maybeSingle();

    if (orderError || !order) {
        document.getElementById("items").innerHTML =
            "<p>Order not found.</p>";
        return;
    }

    const { data: items, error } = await supabaseClient
        .from("order_item")
        .select("*, product(name)")
        .eq("order_id", orderId);

    if (error) {
        console.error(error);
        document.getElementById("items").innerHTML =
            "<p>Could not load order items.</p>";
        return;
    }

    document.getElementById("order-number").textContent = order.order_id;
    document.getElementById("order-status").textContent = order.status;
    document.getElementById("order-total").textContent =
        Number(order.total).toFixed(2);

    document.getElementById("items").innerHTML = items
        .map(i => `<p>${i.product.name} × ${i.quantity} — AED ${(i.price * i.quantity).toFixed(2)}</p>`)
        .join("");
}

if (document.getElementById("order-number")) {
    loadConfirmation();
}

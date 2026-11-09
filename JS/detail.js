// Uses supabaseClient, allProducts and addToCart from app.js (loaded first)

const params = new URLSearchParams(window.location.search);
const productId = params.get("id");

async function loadProduct() {
    const detail = document.getElementById("detail");

    if (!detail) {
        console.error("Element with id='detail' was not found");
        return;
    }

    if (!productId) {
        detail.innerHTML = "<p>Product ID is missing from URL.</p>";
        return;
    }

    const { data, error } = await supabaseClient
        .from("product")
        .select("*, category(category_name)")
        .eq("product_id", productId)
        .maybeSingle();

    if (error) {
        console.error("Supabase error:", error);
        detail.innerHTML = "<p>Error loading product details.</p>";
        return;
    }

    if (!data) {
        detail.innerHTML = "<p>Product not found.</p>";
        return;
    }

    allProducts = [data];

    const image = data.image_url
        ? `<img src="${data.image_url}" alt="${data.name}" onerror="this.remove()">`
        : "";

    detail.innerHTML = `
        ${image}
        <h2>${data.name}</h2>
        <p>${data.category?.category_name ?? ""}</p>
        <p>${data.description ?? ""}</p>
        <p class="price">Price: AED ${Number(data.price).toFixed(2)}</p>
        <p>Stock: ${data.stock}</p>
        <button onclick="addToCartById(${data.product_id})" ${data.stock > 0 ? "" : "disabled"}>
            Add to Cart
        </button>
    `;
}

loadProduct();

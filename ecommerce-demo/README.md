# E-Commerce Demo

A minimal FastAPI + SQLite e-commerce app, purpose-built as a backend for an **MCP (Model Context Protocol) Server**.

An AI agent can use the REST APIs below to search products, add items to cart, place orders, and inspect order history — all through natural language via MCP tools.

---

## Setup

```bash
cd ecommerce-demo
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
uvicorn app:app --reload
# → http://localhost:8000
```

On first start the app auto-creates `ecommerce.db` and seeds all 126 products from `items.csv`.

---

## REST API Reference

Base URL: `http://localhost:8000`

---

### 1. List Categories

Returns all distinct product categories. Useful for MCP to understand available product groups before filtering.

```
GET /api/categories
```

**Response**
```json
[
  "Baby Care",
  "Bakery",
  "Beverages",
  "Condiments",
  "Dairy & Eggs",
  "Electronics",
  "Fruits",
  "Grocery",
  "Home Care",
  "Home Essentials",
  "Personal Care",
  "Snacks",
  "Stationery",
  "Vegetables"
]
```

**curl**
```bash
curl http://localhost:8000/api/categories
```

---

### 2. List / Search Products

Returns all products. Supports free-text search and category filtering.

```
GET /api/items
GET /api/items?q={search_term}
GET /api/items?category={category_name}
GET /api/items?q={search_term}&category={category_name}
```

**Query parameters**

| Parameter  | Type   | Description |
|------------|--------|-------------|
| `q`        | string | Full-text search across name, description, tags, and semantic description |
| `category` | string | Filter by category name (partial match, case-insensitive) |

**Response** — array of item summaries
```json
[
  {
    "id": 1,
    "name": "Apple",
    "price": 120.0,
    "category": "Fruits",
    "tags": ["fresh", "fruit", "healthy", "vitamin-c", "seasonal"]
  }
]
```

**curl examples**
```bash
# All products
curl http://localhost:8000/api/items

# Search by keyword (searches name + description + tags + semantic description)
curl "http://localhost:8000/api/items?q=protein"

# Search for breakfast items
curl "http://localhost:8000/api/items?q=breakfast"

# Filter by category
curl "http://localhost:8000/api/items?category=Electronics"

# Combined — protein-rich items in Dairy & Eggs
curl "http://localhost:8000/api/items?q=protein&category=Dairy"
```

---

### 3. Get Product Detail

Returns full details for a single product including semantic description.

```
GET /api/items/{id}
```

**Path parameter**

| Parameter | Type    | Description   |
|-----------|---------|---------------|
| `id`      | integer | Product ID    |

**Response**
```json
{
  "id": 6,
  "name": "Watermelon",
  "description": "Fresh Watermelon - 1 piece",
  "price": 80.0,
  "category": "Fruits",
  "tags": ["fresh", "fruit", "summer", "hydrating", "sweet"],
  "semantic_description": "Over 90% water content makes this ideal for summer hydration. Low calorie and naturally sweet. Great for juice, smoothies, or eating chilled on a hot day."
}
```

**Error** — `404 Not Found`
```json
{ "detail": "Item not found" }
```

**curl examples**
```bash
# Get product with ID 6
curl http://localhost:8000/api/items/6

# Get product with ID 107 (USB Keyboard)
curl http://localhost:8000/api/items/107
```

---

### 4. Add Item to Cart

Adds an item to the global cart. If the item is already in the cart, its quantity is incremented.

```
POST /api/cart
Content-Type: application/json
```

**Request body**
```json
{
  "item_id": 5,
  "quantity": 2
}
```

| Field      | Type    | Required | Description |
|------------|---------|----------|-------------|
| `item_id`  | integer | yes      | ID of the product to add |
| `quantity` | integer | yes      | Number of units to add   |

**Response** — `200 OK`
```json
{ "message": "Item added" }
```

**Error** — `404 Not Found`
```json
{ "detail": "Item not found" }
```

**curl examples**
```bash
# Add 2 units of item ID 5 (Grapes)
curl -X POST http://localhost:8000/api/cart \
  -H "Content-Type: application/json" \
  -d '{"item_id": 5, "quantity": 2}'

# Add item already in cart — quantity will be incremented by 1
curl -X POST http://localhost:8000/api/cart \
  -H "Content-Type: application/json" \
  -d '{"item_id": 5, "quantity": 1}'
```

---

### 5. View Cart

Returns everything currently in the cart with per-item totals and grand total.

```
GET /api/cart
```

**Response**
```json
{
  "items": [
    {
      "item_id": 5,
      "name": "Grapes",
      "price": 110.0,
      "quantity": 3,
      "total": 330.0
    },
    {
      "item_id": 1,
      "name": "Apple",
      "price": 120.0,
      "quantity": 1,
      "total": 120.0
    }
  ],
  "grand_total": 450.0
}
```

Returns `"items": []` and `"grand_total": 0.0` when cart is empty.

**curl**
```bash
curl http://localhost:8000/api/cart
```

---

### 6. Place Order

Reads the current cart, creates an order with payment mode `Cash on Delivery`, and empties the cart.

```
POST /api/orders
```

No request body required.

**Response** — `200 OK`
```json
{
  "order_id": 3,
  "payment_mode": "Cash on Delivery",
  "total_amount": 450.0
}
```

**Error** — `400 Bad Request` when cart is empty
```json
{ "detail": "Cart is empty" }
```

**curl**
```bash
curl -X POST http://localhost:8000/api/orders
```

---

### 7. List Orders

Returns all placed orders, newest first.

```
GET /api/orders
```

**Response** — array of orders
```json
[
  {
    "id": 3,
    "total_amount": 450.0,
    "payment_mode": "Cash on Delivery"
  },
  {
    "id": 2,
    "total_amount": 640.0,
    "payment_mode": "Cash on Delivery"
  }
]
```

Returns `[]` when no orders have been placed.

**curl**
```bash
curl http://localhost:8000/api/orders
```

---

## Full End-to-End Flow (curl)

This is the complete sequence an MCP agent would follow to complete a purchase:

```bash
BASE=http://localhost:8000

# 1. Discover available categories
curl $BASE/api/categories

# 2. Search for protein-rich breakfast items
curl "$BASE/api/items?q=protein&category=Dairy"

# 3. Inspect a specific item (Eggs = id 64)
curl $BASE/api/items/64

# 4. Add Eggs (qty 2) and Peanut Butter (qty 1) to cart
curl -X POST $BASE/api/cart \
  -H "Content-Type: application/json" \
  -d '{"item_id": 64, "quantity": 2}'

curl -X POST $BASE/api/cart \
  -H "Content-Type: application/json" \
  -d '{"item_id": 76, "quantity": 1}'

# 5. Review cart before placing order
curl $BASE/api/cart

# 6. Place the order
curl -X POST $BASE/api/orders

# 7. Confirm order was recorded
curl $BASE/api/orders
```

---

## API Summary Table

| Method | Endpoint             | Description                                      |
|--------|----------------------|--------------------------------------------------|
| GET    | `/api/categories`    | List all product categories                      |
| GET    | `/api/items`         | List all products (supports `?q=` and `?category=`) |
| GET    | `/api/items/{id}`    | Get full detail for one product                  |
| POST   | `/api/cart`          | Add item to cart (body: `item_id`, `quantity`)   |
| GET    | `/api/cart`          | View current cart with totals                    |
| POST   | `/api/orders`        | Place order from cart (Cash on Delivery)         |
| GET    | `/api/orders`        | List all placed orders, newest first             |

---

## HTML Pages

| URL               | Description                                      |
|-------------------|--------------------------------------------------|
| `/`               | Product grid — browse all 126 products           |
| `/products/{id}`  | Product detail with semantic description + tags  |
| `/cart`           | Cart view with order summary                     |
| `/orders`         | Order history listing                            |
| `/order-success`  | Confirmation page after placing an order         |

---

## Design Notes

- **Single global cart** — no users, no sessions, no auth
- **`?q=` searches everything** — name, description, tags, and semantic description
- **`semantic_description`** on each item is written for LLM consumption: it describes nutritional value, use cases, occasions, and context
- SQLite DB is auto-created and seeded on first startup; delete `ecommerce.db` to reset
- FastAPI auto-generates interactive docs at `/docs` (Swagger UI) and `/redoc`

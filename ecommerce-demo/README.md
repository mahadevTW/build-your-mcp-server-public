# E-Commerce Demo

A minimal e-commerce application built with FastAPI + SQLite, designed as a backend for MCP (Model Context Protocol) integration.

## Install

```bash
cd ecommerce-demo
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
uvicorn app:app --reload
```

App runs at: http://localhost:8000

---

## HTML Pages

| URL | Description |
|-----|-------------|
| `/` | Product listing — browse all ~120 products |
| `/products/{id}` | Product detail — add to cart with quantity |
| `/cart` | View cart, grand total, place order |
| `/order-success` | Confirmation after order placement |

---

## REST APIs

### List all products
```
GET /api/items
```
Returns id, name, price for all items.

### Get product details
```
GET /api/items/{id}
```
Returns id, name, description, price.

### Add item to cart
```
POST /api/cart
Content-Type: application/json

{ "item_id": 5, "quantity": 2 }
```
If item already in cart, quantity is incremented.

### View cart
```
GET /api/cart
```
Returns all cart items with totals and grand total.

### Place order
```
POST /api/orders
```
Reads cart, creates order (Cash on Delivery), clears cart.

---

## Design Notes

- Single global cart — no users, no sessions
- SQLite database auto-created on first run
- ~120 products seeded from `items.csv` on startup
- This app exists purely to be exposed via an MCP Server

# Pune AI Builders Meetup — Build Your First MCP Server

Hands-on session: build an **MCP (Model Context Protocol) server** that lets Claude browse products, manage a cart, and place orders through natural language.

```
Claude
  |  MCP tools
  v
MCP Server  ->  E-Commerce REST API  ->  SQLite DB
```

---

## Requirements

- Python 3.10+
- Node.js 18+
- Git
- Claude Code CLI

Install Claude Code CLI if you haven't already:
```bash
npm install -g @anthropic-ai/claude-code
```

---

## Step 1 — Run Setup

Clone the repo and run the setup script from the repo root:

```bash
git clone <this-repo>
cd build-your-mcp-server-public
bash setup.sh
```

This will:
- Install all Python dependencies for both `ecommerce-demo` and `mcp-server`
- Start the ecommerce server on port 8000
- Run end-to-end API tests to verify everything is working

If all steps show `[OK]`, the ecommerce server is up and ready.

Open http://localhost:8000 to see the store. API docs at http://localhost:8000/docs.

---

## Step 2 — Register the MCP Server with Claude

Open a **new terminal** (keep the ecommerce server running). Run once from the repo root:

**Mac / Linux**
```bash
claude mcp add ecommerce \
  -e "ECOMMERCE_BASE_URL=http://localhost:8000" \
  -- mcp-server/.venv/bin/python mcp-server/server.py
```

**Windows (Git Bash)**
```bash
claude mcp add ecommerce \
  -e "ECOMMERCE_BASE_URL=http://localhost:8000" \
  -- mcp-server/.venv/Scripts/python.exe mcp-server/server.py
```

Verify the server is connected:
```bash
claude mcp list
# ecommerce: ... - Connected
```

---

## Step 3 — Chat with Claude

```bash
claude
```

Try these prompts:
```
Use the ecommerce tools to list all product categories.
Search for high-protein breakfast items and show me the options.
Add 2 packs of eggs and 1 peanut butter to my cart.
What is in my cart and what is the total?
Place the order.
Show my order history.
```

---

## Option B — Deploy to Railway (Remote)

Deploy both services so they are publicly accessible from anywhere.

### Prerequisites

```bash
npm install -g @railway/cli
railway login
```

### 1. Deploy the E-Commerce API

```bash
cd ecommerce-demo
railway init        # create a new Railway project, select "Empty project"
railway up
```

Note the public URL from the Railway dashboard, e.g.:
`https://ecommerce-demo-production-xxxx.up.railway.app`

### 2. Deploy the MCP Server

```bash
cd ../mcp-server
railway init        # create a second Railway project
railway up
```

In the **Railway dashboard** for the MCP server service, set these environment variables:

| Variable | Value |
|---|---|
| `MCP_TRANSPORT` | `http` |
| `ECOMMERCE_BASE_URL` | `https://ecommerce-demo-production-xxxx.up.railway.app` |

Railway will auto-redeploy after you save the variables.

### 3. Register the Remote MCP Server with Claude

```bash
claude mcp add ecommerce \
  --transport http \
  https://your-mcp-server-production.up.railway.app/mcp
```

Verify:
```bash
claude mcp list
# ecommerce: https://...railway.app/mcp (HTTP) - Connected
```

### 4. Chat with Claude

```bash
claude
> Use the ecommerce tools to search for peanut butter, add it to my cart, and place the order.
```

---

## MCP Tools Reference

| Tool | What it does |
|---|---|
| `list_categories` | All product categories |
| `search_products(q, category)` | Search/filter products |
| `get_product(item_id)` | Full product details |
| `add_to_cart(item_id, quantity)` | Add item to cart |
| `view_cart` | Cart contents and totals |
| `place_order` | Checkout (Cash on Delivery) |
| `list_orders` | Order history |

---

## Project Structure

```
build-your-mcp-server-public/
├── ecommerce-demo/           FastAPI app — products, cart, orders, HTML UI
│   ├── app.py
│   ├── models.py
│   ├── schemas.py
│   ├── database.py
│   ├── seed.py               seeds 126 products from items.csv on first run
│   ├── items.csv
│   ├── requirements.txt
│   ├── Procfile              Railway start command
│   ├── railway.toml          Railway deploy config
│   └── notebooks/
│       └── test_setup.ipynb  end-to-end API test suite (runs in setup.sh)
├── mcp-server/               MCP server wrapping the REST API as tools
│   ├── server.py
│   ├── requirements.txt
│   ├── Procfile
│   └── railway.toml
├── scripts/                  helper scripts (ngrok, MCP registration)
├── setup.sh                  one-shot setup: deps + start ecommerce + run tests
└── README.md
```

---

## Troubleshooting

**`claude mcp list` shows Failed to connect**

Make sure the ecommerce server is running (`bash setup.sh` or start manually), then re-register from the repo root:

Mac / Linux:
```bash
claude mcp remove ecommerce
claude mcp add ecommerce \
  -e "ECOMMERCE_BASE_URL=http://localhost:8000" \
  -- mcp-server/.venv/bin/python mcp-server/server.py
```

Windows (Git Bash):
```bash
claude mcp remove ecommerce
claude mcp add ecommerce \
  -e "ECOMMERCE_BASE_URL=http://localhost:8000" \
  -- mcp-server/.venv/Scripts/python.exe mcp-server/server.py
```

**Claude answers from the README instead of using tools**
Be explicit in your prompt:
```
Use the ecommerce MCP tools to...
```

**Reset the database**
```bash
rm ecommerce-demo/ecommerce.db
# Restart the server — it re-seeds automatically
```

**Railway deploy fails healthcheck**
Check that `MCP_TRANSPORT=http` and `ECOMMERCE_BASE_URL` are set in Railway variables.

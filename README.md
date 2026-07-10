# Pune AI Builders Meetup — Build Your First MCP Server

Hands-on session: build an **MCP (Model Context Protocol) server** that lets Claude browse products, manage a cart, and place orders through natural language.

```
Claude
  |  MCP tools
  v
MCP Server  →  E-Commerce REST API  →  SQLite DB
```

---

## Before the Meetup — One-Time Setup

Requires **Python 3.10+**, **Node.js 18+**, and **Git**.

```bash
git clone git@github.com:mahadevTW/build-your-mcp-server-public.git
cd build-your-mcp-server-public
bash setup.sh
```

The script installs all dependencies, starts the ecommerce server, registers the MCP server with Claude, and verifies everything is connected.

If all steps show `[OK]`, you are ready.

---

> **Manual setup (if you prefer step-by-step)**
>
> Install Claude Code CLI:
> ```bash
> npm install -g @anthropic-ai/claude-code
> ```
>
> Install ecommerce-demo deps:
> ```bash
> cd ecommerce-demo && python -m venv .venv
> source .venv/bin/activate          # Mac/Linux
> # .venv\Scripts\activate           # Windows
> pip install -r requirements.txt && deactivate && cd ..
> ```


---

## Option A — Run Locally (Quickest)

### 1. Start the E-Commerce API

**Mac / Linux**
```bash
cd ecommerce-demo
source .venv/bin/activate
uvicorn app:app --host 0.0.0.0 --port 8000
```

**Windows**
```bash
cd ecommerce-demo
.venv\Scripts\uvicorn app:app --host 0.0.0.0 --port 8000
```

Open http://localhost:8000 — you should see the store. API docs at http://localhost:8000/docs.

On first start it auto-creates `ecommerce.db` and seeds 126 products.

---

## Option B — Deploy to Railway (Cloud)

Deploy both services to Railway so the MCP server is accessible remotely.

Requires the **Railway CLI** — install it once:

```bash
npm install -g @railway/cli
```

### 1. Deploy the E-Commerce API

```bash
bash ecommerce-demo/railway_setup.sh
```

This will:
- Log you in to Railway (browser prompt)
- Create a new Railway project called `ecommerce-demo`
- Deploy the FastAPI app using Nixpacks
- Print the public URL (e.g. `https://ecommerce-demo.up.railway.app`)

Override the project name if needed:
```bash
RAILWAY_PROJECT_NAME=my-store bash ecommerce-demo/railway_setup.sh
```

### 2. Deploy the MCP Server

```bash
ECOMMERCE_BASE_URL=https://ecommerce-demo.up.railway.app bash mcp-server/railway_setup_mcp.sh
```

If `ECOMMERCE_BASE_URL` is not set, the script will prompt for it interactively.

This will:
- Create a new Railway project called `ecommerce-mcp`
- Set `MCP_TRANSPORT=streamable-http`, `ECOMMERCE_BASE_URL`, and `MCP_PATH=/mcp` as env vars
- Deploy the MCP server
- Print the Claude connection command, e.g.:

```bash
claude mcp add ecommerce --transport http https://ecommerce-mcp.up.railway.app/mcp
```

### Useful commands after deployment

```bash
railway logs          # stream live logs
railway status        # check deployment status
railway open          # open project in Railway dashboard
```

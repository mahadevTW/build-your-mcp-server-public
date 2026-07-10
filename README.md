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
```

**Mac / Linux**
```bash
bash setup.sh
```

**Windows (CMD or PowerShell)** — run from repo root:
```cmd
.\setup.bat
```

Open http://localhost:8000 to verify the store is running.

If all steps show `[OK]`, you are ready.

## Step 2 — Register the MCP Server with Claude

Open a **new terminal** and run once from the repo root:

**Mac / Linux**
```bash
claude mcp add ecommerce \
  -e "ECOMMERCE_BASE_URL=http://localhost:8000" \
  -- mcp-server/.venv/bin/python mcp-server/server.py
```

**Windows (CMD or PowerShell)**
```cmd
claude mcp add ecommerce -e "ECOMMERCE_BASE_URL=http://localhost:8000" -- mcp-server/.venv/Scripts/python.exe mcp-server/server.py
```

Verify it's connected:
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

## Option B — Deploy to Railway (Cloud)

Deploy both services to Railway so the MCP server is accessible remotely.

Requires the **Railway CLI** — install it once:

```bash
npm install -g @railway/cli
```

### 1. Deploy the E-Commerce API

**Mac / Linux**
```bash
bash ecommerce-demo/railway_setup.sh
```

**Windows**
```cmd
ecommerce-demo\railway_setup.bat
```

This will log you in to Railway, create a project, deploy the app, and print the public URL (e.g. `https://ecommerce-demo.up.railway.app`).

### 2. Deploy the MCP Server

**Mac / Linux**
```bash
ECOMMERCE_BASE_URL=https://ecommerce-demo.up.railway.app bash mcp-server/railway_setup_mcp.sh
```

**Windows**
```cmd
set ECOMMERCE_BASE_URL=https://ecommerce-demo.up.railway.app
mcp-server\railway_setup_mcp.bat
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

---

## Troubleshooting

**Port 8000 already in use**

Mac / Linux:
```bash
lsof -ti tcp:8000 | xargs kill -9
```

Windows (PowerShell):
```powershell
netstat -ano | findstr :8000
# note the PID in the last column, then:
taskkill /F /PID <PID>
```

Then start the server again.

**`claude mcp list` shows Failed to connect**

Make sure the ecommerce server is running on port 8000, then re-register from the repo root:

Mac / Linux:
```bash
claude mcp remove ecommerce
claude mcp add ecommerce \
  -e "ECOMMERCE_BASE_URL=http://localhost:8000" \
  -- mcp-server/.venv/bin/python mcp-server/server.py
```

Windows (PowerShell):
```powershell
claude mcp remove ecommerce
claude mcp add ecommerce -e "ECOMMERCE_BASE_URL=http://localhost:8000" -- mcp-server/.venv/Scripts/python.exe mcp-server/server.py
```

**Claude answers from the README instead of using tools**
```
Use the ecommerce MCP tools to...
```

**Reset the database**

Mac / Linux:
```bash
rm ecommerce-demo/ecommerce.db
```

Windows:
```cmd
del ecommerce-demo\ecommerce.db
```

Restart the server — it re-seeds automatically.

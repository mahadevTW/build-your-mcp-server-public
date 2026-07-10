#!/usr/bin/env bash
# scripts/railway_setup_mcp.sh
# End-to-end setup: creates a Railway project and deploys the mcp-server.
# Run from repo root: bash scripts/railway_setup_mcp.sh
#
# Required env vars (or set interactively):
#   ECOMMERCE_BASE_URL  -- URL of the deployed ecommerce-demo (e.g. https://ecommerce-demo.up.railway.app)
#
# Optional env vars:
#   RAILWAY_PROJECT_NAME  -- defaults to "ecommerce-mcp"
#   MCP_PATH              -- defaults to /mcp

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_DIR="$REPO_ROOT/mcp-server"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }
error()   { echo "[ERROR] $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1. Check Railway CLI is installed
# ---------------------------------------------------------------------------
if ! command -v railway &>/dev/null; then
  echo ""
  echo "Railway CLI not found. Install it first:"
  echo "  npm install -g @railway/cli"
  echo "  -- or --"
  echo "  curl -fsSL https://railway.app/install.sh | sh"
  echo ""
  error "Railway CLI is required. Please install it and re-run this script."
fi
success "Railway CLI found: $(railway --version)"

# ---------------------------------------------------------------------------
# 2. Ensure user is logged in
# ---------------------------------------------------------------------------
info "Checking Railway login status..."
if ! railway whoami &>/dev/null; then
  info "Not logged in. Opening browser for authentication..."
  railway login
fi
success "Logged in as: $(railway whoami)"

# ---------------------------------------------------------------------------
# 3. Resolve ECOMMERCE_BASE_URL
# ---------------------------------------------------------------------------
if [ -z "${ECOMMERCE_BASE_URL:-}" ]; then
  echo ""
  echo "ECOMMERCE_BASE_URL is not set."
  echo "This is the public URL of your deployed ecommerce-demo service."
  echo "Example: https://ecommerce-demo.up.railway.app"
  echo ""
  read -rp "Enter ECOMMERCE_BASE_URL: " ECOMMERCE_BASE_URL
  [ -z "$ECOMMERCE_BASE_URL" ] && error "ECOMMERCE_BASE_URL cannot be empty."
fi

# Strip trailing slash
ECOMMERCE_BASE_URL="${ECOMMERCE_BASE_URL%/}"
info "Using ECOMMERCE_BASE_URL: $ECOMMERCE_BASE_URL"

# ---------------------------------------------------------------------------
# 4. Create a new Railway project (from mcp-server directory)
# ---------------------------------------------------------------------------
PROJECT_NAME="${RAILWAY_PROJECT_NAME:-ecommerce-mcp}"
MCP_PATH_VAL="${MCP_PATH:-/mcp}"

info "Creating Railway project: $PROJECT_NAME"
cd "$MCP_DIR"

railway init --name "$PROJECT_NAME"
success "Project '$PROJECT_NAME' created and linked."

# ---------------------------------------------------------------------------
# 5. Set environment variables on Railway
# ---------------------------------------------------------------------------
info "Setting environment variables..."
railway variables --set "MCP_TRANSPORT=streamable-http"
railway variables --set "ECOMMERCE_BASE_URL=$ECOMMERCE_BASE_URL"
railway variables --set "MCP_PATH=$MCP_PATH_VAL"
success "Environment variables set."

# ---------------------------------------------------------------------------
# 6. Deploy
# ---------------------------------------------------------------------------
info "Deploying mcp-server to Railway..."
railway up --detach
success "Deployment triggered."

# ---------------------------------------------------------------------------
# 7. Print the public URL and Claude connection command
# ---------------------------------------------------------------------------
echo ""
info "Fetching deployment URL..."
sleep 3

DOMAIN=$(railway domain 2>/dev/null || true)
if [ -n "$DOMAIN" ]; then
  MCP_URL="https://$DOMAIN$MCP_PATH_VAL"
  success "MCP server is live at: $MCP_URL"
  echo ""
  echo "Connect Claude to this MCP server:"
  echo "  claude mcp add ecommerce --transport http $MCP_URL"
else
  info "URL not available yet. Once deployed, run:"
  echo "  cd $MCP_DIR && railway domain"
  echo "  then: claude mcp add ecommerce --transport http https://<domain>$MCP_PATH_VAL"
fi

echo ""
info "Useful commands:"
echo "  railway logs          -- stream live logs"
echo "  railway status        -- check deployment status"
echo "  railway open          -- open the project in Railway dashboard"
echo ""

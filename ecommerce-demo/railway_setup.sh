#!/usr/bin/env bash
# scripts/railway_setup.sh
# End-to-end setup: creates a Railway project and deploys the ecommerce-demo app.
# Run from repo root: bash scripts/railway_setup.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ECOM_DIR="$REPO_ROOT/ecommerce-demo"

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
# 3. Create a new Railway project (from ecommerce-demo directory)
# ---------------------------------------------------------------------------
PROJECT_NAME="${RAILWAY_PROJECT_NAME:-ecommerce-demo}"

info "Creating Railway project: $PROJECT_NAME"
cd "$ECOM_DIR"

# 'railway init' creates a new project and writes .railway/config.json
railway init --name "$PROJECT_NAME"
success "Project '$PROJECT_NAME' created and linked."

# ---------------------------------------------------------------------------
# 4. Deploy
# ---------------------------------------------------------------------------
info "Deploying ecommerce-demo to Railway..."
railway up --detach

success "Deployment triggered."

# ---------------------------------------------------------------------------
# 5. Print the public URL
# ---------------------------------------------------------------------------
echo ""
info "Fetching deployment URL..."
sleep 3   # give Railway a moment to register the service

DOMAIN=$(railway domain 2>/dev/null || true)
if [ -n "$DOMAIN" ]; then
  success "App is live at: https://$DOMAIN"
else
  info "URL not available yet. Run the following to check status and get URL:"
  echo "  cd $ECOM_DIR && railway status"
  echo "  cd $ECOM_DIR && railway domain"
fi

echo ""
info "Useful commands:"
echo "  railway logs          -- stream live logs"
echo "  railway status        -- check deployment status"
echo "  railway open          -- open the project in Railway dashboard"
echo ""

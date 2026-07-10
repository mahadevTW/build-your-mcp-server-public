#!/usr/bin/env bash
# setup.sh — One-shot setup for the MCP + E-Commerce demo
# Run from repo root: bash setup.sh
# Works on Mac, Linux, and Windows (Git Bash)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OK="[OK]"
FAIL="[FAIL]"
INFO="[..]"

ECOM_PORT=8000
ECOM_DIR="$REPO_ROOT/ecommerce-demo"
MCP_DIR="$REPO_ROOT/mcp-server"

echo ""
echo "========================================"
echo "  MCP Server Setup"
echo "========================================"
echo ""

# ── 1. Find Python ────────────────────────────────────────────────────────────
PYTHON=""
for cmd in python python3 py; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ver=$("$cmd" --version 2>&1)
    if echo "$ver" | grep -q "^Python 3"; then
      PYTHON="$cmd"
      echo "$OK $ver"
      break
    fi
  fi
done

if [ -z "$PYTHON" ]; then
  echo "$FAIL Python 3.10+ not found. Install from https://www.python.org/downloads/"
  exit 1
fi

# ── 2. Check / Install Claude Code CLI ───────────────────────────────────────
if command -v claude >/dev/null 2>&1; then
  echo "$OK Claude Code CLI: $(claude --version 2>/dev/null | head -1)"
else
  echo "$INFO Claude Code CLI not found. Installing..."
  if ! command -v npm >/dev/null 2>&1; then
    echo "$FAIL npm not found. Install Node.js 18+ from https://nodejs.org then re-run."
    exit 1
  fi
  npm install -g @anthropic-ai/claude-code
  if command -v claude >/dev/null 2>&1; then
    echo "$OK Claude Code CLI installed: $(claude --version 2>/dev/null | head -1)"
  else
    echo "$FAIL Claude Code CLI install failed. Try manually: npm install -g @anthropic-ai/claude-code"
    exit 1
  fi
fi

# ── Helper: resolve venv python/pip paths (Windows vs Unix) ───────────────────
venv_python() {
  local dir="$1"
  if   [ -f "$dir/.venv/Scripts/python.exe" ]; then echo "$dir/.venv/Scripts/python.exe"
  elif [ -f "$dir/.venv/Scripts/python"     ]; then echo "$dir/.venv/Scripts/python"
  else                                               echo "$dir/.venv/bin/python"
  fi
}

venv_bin() {
  local dir="$1" bin="$2"
  if   [ -f "$dir/.venv/Scripts/${bin}.exe" ]; then echo "$dir/.venv/Scripts/${bin}.exe"
  elif [ -f "$dir/.venv/Scripts/${bin}"     ]; then echo "$dir/.venv/Scripts/${bin}"
  else                                               echo "$dir/.venv/bin/${bin}"
  fi
}

# ── 3. Install ecommerce-demo deps ───────────────────────────────────────────
echo ""
echo "$INFO Setting up ecommerce-demo..."
cd "$ECOM_DIR"
if [ ! -d ".venv" ]; then
  "$PYTHON" -m venv .venv
fi
PY="$(venv_python "$ECOM_DIR")"
"$PY" -m pip install --upgrade pip -q 2>/dev/null || true
"$PY" -m pip install -r requirements.txt -q
echo "$OK ecommerce-demo dependencies installed"

# ── 4. Install MCP server deps ────────────────────────────────────────────────
echo "$INFO Setting up mcp-server..."
cd "$MCP_DIR"
if [ ! -d ".venv" ]; then
  "$PYTHON" -m venv .venv
fi
PY_MCP="$(venv_python "$MCP_DIR")"
"$PY_MCP" -m pip install --upgrade pip -q 2>/dev/null || true
"$PY_MCP" -m pip install -r requirements.txt -q
echo "$OK mcp-server dependencies installed"

# ── 5. Start ecommerce-demo server ───────────────────────────────────────────
echo ""
echo "$INFO Starting ecommerce-demo on port $ECOM_PORT..."

# Kill any previous instance on this port
if command -v lsof >/dev/null 2>&1; then
  lsof -ti tcp:$ECOM_PORT | xargs kill -9 2>/dev/null || true
elif command -v netstat >/dev/null 2>&1; then
  netstat -ano 2>/dev/null | grep ":$ECOM_PORT " | awk '{print $5}' | xargs -I{} taskkill //F //PID {} 2>/dev/null || true
fi

UVICORN="$(venv_bin "$ECOM_DIR" uvicorn)"
cd "$ECOM_DIR"
"$UVICORN" app:app --host 0.0.0.0 --port $ECOM_PORT > /tmp/ecommerce.log 2>&1 &
ECOM_PID=$!

# ── 6. Wait for server to be ready ───────────────────────────────────────────
echo "$INFO Waiting for server to be ready..."
MAX_WAIT=30
WAITED=0
until curl -s "http://localhost:$ECOM_PORT/api/categories" >/dev/null 2>&1; do
  sleep 1
  WAITED=$((WAITED + 1))
  if [ $WAITED -ge $MAX_WAIT ]; then
    echo "$FAIL Server did not start within ${MAX_WAIT}s."
    echo "     Check logs: cat /tmp/ecommerce.log"
    kill $ECOM_PID 2>/dev/null
    exit 1
  fi
done

echo "$OK ecommerce-demo is up at http://localhost:$ECOM_PORT"

# ── 7. Verify API returns expected data ──────────────────────────────────────
CATEGORIES=$(curl -s "http://localhost:$ECOM_PORT/api/categories")
COUNT=$(echo "$CATEGORIES" | "$PY" -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
if [ "$COUNT" -gt 0 ] 2>/dev/null; then
  echo "$OK API healthy — $COUNT categories available"
else
  echo "$FAIL API returned unexpected response: $CATEGORIES"
  kill $ECOM_PID 2>/dev/null
  exit 1
fi

# ── 8. Run end-to-end notebook tests ─────────────────────────────────────────
echo ""
echo "$INFO Running end-to-end API tests (notebooks/test_setup.ipynb)..."
JUPYTER="$(venv_bin "$ECOM_DIR" jupyter)"
cd "$ECOM_DIR"
"$JUPYTER" nbconvert --to notebook --execute \
  notebooks/test_setup.ipynb \
  --ExecutePreprocessor.timeout=60 \
  --output /tmp/test_result.ipynb \
  2>/tmp/nbconvert.log

if [ $? -eq 0 ]; then
  echo "$OK All API tests passed"
else
  echo "$FAIL Notebook tests failed. Check output:"
  cat /tmp/nbconvert.log
  kill $ECOM_PID 2>/dev/null
  exit 1
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Setup complete!"
echo ""
echo "  Store UI : http://localhost:$ECOM_PORT"
echo "  API docs : http://localhost:$ECOM_PORT/docs"
echo ""
echo "  Server is running in the background (PID $ECOM_PID)."
echo "  To stop it:  kill $ECOM_PID"
echo "========================================"
echo ""

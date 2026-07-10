@echo off
:: railway_setup_mcp.bat — Deploy mcp-server to Railway (Windows)
:: Run from repo root: mcp-server\railway_setup_mcp.bat
:: Set ECOMMERCE_BASE_URL before running:
::   set ECOMMERCE_BASE_URL=https://ecommerce-demo.up.railway.app
::   mcp-server\railway_setup_mcp.bat

setlocal EnableDelayedExpansion

set PROJECT_NAME=ecommerce-mcp
if not "%RAILWAY_PROJECT_NAME%"=="" set PROJECT_NAME=%RAILWAY_PROJECT_NAME%

set MCP_PATH_VAL=/mcp
if not "%MCP_PATH%"=="" set MCP_PATH_VAL=%MCP_PATH%

echo.
echo [..] Checking Railway CLI...
railway --version >nul 2>&1
if !errorlevel! neq 0 (
    echo [FAIL] Railway CLI not found. Install it first:
    echo        npm install -g @railway/cli
    exit /b 1
)
echo [OK] Railway CLI found

echo [..] Checking login status...
railway whoami >nul 2>&1
if !errorlevel! neq 0 (
    echo [..] Not logged in. Opening browser...
    railway login
)
echo [OK] Logged in

:: Prompt for ECOMMERCE_BASE_URL if not set
if "%ECOMMERCE_BASE_URL%"=="" (
    echo.
    echo ECOMMERCE_BASE_URL is not set.
    echo This is the public URL of your deployed ecommerce-demo service.
    echo Example: https://ecommerce-demo.up.railway.app
    echo.
    set /p ECOMMERCE_BASE_URL="Enter ECOMMERCE_BASE_URL: "
)
if "%ECOMMERCE_BASE_URL%"=="" (
    echo [FAIL] ECOMMERCE_BASE_URL cannot be empty.
    exit /b 1
)
echo [..] Using ECOMMERCE_BASE_URL: %ECOMMERCE_BASE_URL%

echo [..] Creating Railway project: %PROJECT_NAME%
cd /d "%~dp0"
railway init --name "%PROJECT_NAME%"
echo [OK] Project created

echo [..] Setting environment variables...
railway variables --set "MCP_TRANSPORT=streamable-http"
railway variables --set "ECOMMERCE_BASE_URL=%ECOMMERCE_BASE_URL%"
railway variables --set "MCP_PATH=%MCP_PATH_VAL%"
echo [OK] Environment variables set

echo [..] Deploying mcp-server...
railway up --detach
echo [OK] Deployment triggered

echo.
echo [..] Fetching deployment URL...
timeout /t 3 >nul
for /f %%d in ('railway domain 2^>nul') do (
    echo [OK] MCP server live at: https://%%d%MCP_PATH_VAL%
    echo.
    echo Connect Claude to this MCP server:
    echo   claude mcp add ecommerce --transport http https://%%d%MCP_PATH_VAL%
)

echo.
echo Useful commands:
echo   railway logs     -- stream live logs
echo   railway status   -- check deployment status
echo   railway open     -- open Railway dashboard
echo.

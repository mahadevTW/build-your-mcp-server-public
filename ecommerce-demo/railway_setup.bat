@echo off
:: railway_setup.bat — Deploy ecommerce-demo to Railway (Windows)
:: Run from repo root: ecommerce-demo\railway_setup.bat

setlocal EnableDelayedExpansion

set PROJECT_NAME=ecommerce-demo
if not "%RAILWAY_PROJECT_NAME%"=="" set PROJECT_NAME=%RAILWAY_PROJECT_NAME%

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

echo [..] Creating Railway project: %PROJECT_NAME%
cd /d "%~dp0"
railway init --name "%PROJECT_NAME%"
echo [OK] Project created

echo [..] Deploying ecommerce-demo...
railway up --detach
echo [OK] Deployment triggered

echo.
echo [..] Fetching deployment URL...
timeout /t 3 >nul
railway domain

echo.
echo Useful commands:
echo   railway logs     -- stream live logs
echo   railway status   -- check deployment status
echo   railway open     -- open Railway dashboard
echo.

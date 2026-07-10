@echo off
:: setup.bat — One-shot setup for Windows (CMD or PowerShell)
:: Run from repo root: setup.bat
:: Requires Python 3.10+ and Node.js 18+. Installs Claude Code CLI if missing.

setlocal EnableDelayedExpansion

set ECOM_PORT=8000
set ECOM_DIR=%~dp0ecommerce-demo
set MCP_DIR=%~dp0mcp-server

echo.
echo ========================================
echo   MCP Server Setup
echo ========================================
echo.

:: ── 1. Find Python ───────────────────────────────────────────────────────────
set PYTHON=
for %%c in (python py) do (
    if "!PYTHON!"=="" (
        %%c --version >nul 2>&1
        if !errorlevel! == 0 (
            for /f "tokens=*" %%v in ('%%c --version 2^>^&1') do (
                echo [OK] %%v
                set PYTHON=%%c
            )
        )
    )
)

if "!PYTHON!"=="" (
    echo [FAIL] Python 3.10+ not found. Install from https://www.python.org/downloads/
    exit /b 1
)

:: ── 2. Check / Install Claude Code CLI ───────────────────────────────────────
call claude --version >nul 2>&1
set CLAUDE_OK=!errorlevel!
if !CLAUDE_OK! neq 0 (
    echo [..] Claude Code CLI not found. Installing...
    call npm --version >nul 2>&1
    if !errorlevel! neq 0 (
        echo [FAIL] npm not found. Install Node.js 18+ from https://nodejs.org then re-run.
        exit /b 1
    )
    call npm install -g @anthropic-ai/claude-code
    call claude --version >nul 2>&1
    if !errorlevel! neq 0 (
        echo [FAIL] Claude Code CLI install failed. Try manually: npm install -g @anthropic-ai/claude-code
        exit /b 1
    )
)
echo [OK] Claude Code CLI ready

:: ── 4. Install ecommerce-demo deps ───────────────────────────────────────────
echo [..] Setting up ecommerce-demo...
cd /d "%ECOM_DIR%"

if not exist ".venv" (
    !PYTHON! -m venv .venv
)

.venv\Scripts\python -m pip install --upgrade pip -q
.venv\Scripts\pip install -r requirements.txt -q
echo [OK] ecommerce-demo dependencies installed

:: ── 5. Install mcp-server deps ────────────────────────────────────────────────
echo [..] Setting up mcp-server...
cd /d "%MCP_DIR%"

if not exist ".venv" (
    !PYTHON! -m venv .venv
)

.venv\Scripts\python -m pip install --upgrade pip -q
.venv\Scripts\pip install -r requirements.txt -q
echo [OK] mcp-server dependencies installed

:: ── 4. Kill any existing process on port 8000 ────────────────────────────────
echo.
echo [..] Starting ecommerce-demo on port %ECOM_PORT%...
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":%ECOM_PORT% " ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)
:: Wait for port to be released
timeout /t 2 >nul

:: Clear old log file
if exist "%TEMP%\ecommerce.log" del "%TEMP%\ecommerce.log" >nul 2>&1

:: ── 5. Start ecommerce server in background ───────────────────────────────────
cd /d "%ECOM_DIR%"
start /B "" .venv\Scripts\uvicorn app:app --host 0.0.0.0 --port %ECOM_PORT% >> "%TEMP%\ecommerce.log" 2>&1

:: ── 6. Wait for server to be ready ───────────────────────────────────────────
echo [..] Waiting for server to be ready...
set WAITED=0
:wait_loop
    curl -s "http://localhost:%ECOM_PORT%/api/categories" >nul 2>&1
    if !errorlevel! == 0 goto server_ready
    set /a WAITED+=1
    if !WAITED! geq 30 (
        echo [FAIL] Server did not start within 30s.
        echo        Check logs: type "%TEMP%\ecommerce.log"
        exit /b 1
    )
    ping -n 2 127.0.0.1 >nul
    goto wait_loop

:server_ready
echo [OK] ecommerce-demo is up at http://localhost:%ECOM_PORT%

:: ── 7. Verify API returns data ───────────────────────────────────────────────
for /f %%c in ('curl -s "http://localhost:%ECOM_PORT%/api/categories" ^| .venv\Scripts\python -c "import sys,json; print(len(json.load(sys.stdin)))" 2^>nul') do set COUNT=%%c
if "%COUNT%"=="" set COUNT=0
if %COUNT% gtr 0 (
    echo [OK] API healthy — %COUNT% categories available
) else (
    echo [FAIL] API returned unexpected response
    type "%TEMP%\ecommerce.log"
    exit /b 1
)

:: ── 8. Run end-to-end notebook tests ─────────────────────────────────────────
echo.
echo [..] Running end-to-end API tests...
cd /d "%ECOM_DIR%"
.venv\Scripts\jupyter nbconvert --to notebook --execute notebooks\test_setup.ipynb --ExecutePreprocessor.timeout=60 --output "%TEMP%\test_result.ipynb" > "%TEMP%\nbconvert.log" 2>&1
if !errorlevel! == 0 (
    echo [OK] All API tests passed
) else (
    echo [FAIL] Notebook tests failed. Check output:
    type "%TEMP%\nbconvert.log"
    exit /b 1
)

:: ── Done ──────────────────────────────────────────────────────────────────────
echo.
echo ========================================
echo   Setup complete!
echo.
echo   Store UI : http://localhost:%ECOM_PORT%
echo   API docs : http://localhost:%ECOM_PORT%/docs
echo.
echo   Server is running in the background.
echo   To stop it: close this window or taskkill /F /IM uvicorn.exe
echo ========================================
echo.

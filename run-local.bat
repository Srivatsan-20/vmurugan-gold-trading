@echo off
REM =====================================================
REM VMUrugan Gold Trading - Local Development Startup Script (Windows)
REM =====================================================

echo 🚀 Starting VMUrugan Gold Trading Platform Locally
echo ==================================================

REM Check if we're in the right directory
if not exist "server\package-sqlserver.json" (
    echo ❌ Please run this script from the project root directory
    echo    Current directory: %CD%
    echo    Expected: vmurugan-gold-trading\
    pause
    exit /b 1
)

REM Step 1: Check Node.js
echo.
echo 1️⃣ Checking Node.js installation...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js not found. Please install Node.js 16+
    echo    Download from: https://nodejs.org/
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo ✅ Node.js found: %NODE_VERSION%
)

REM Step 2: Check SQL Server
echo.
echo 2️⃣ Checking SQL Server availability...
sqlcmd -? >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  SQL Server tools not found in PATH
    echo    This is OK if you're using Docker or have SQL Server installed differently
) else (
    echo ✅ SQL Server tools found
)

REM Step 3: Setup Backend
echo.
echo 3️⃣ Setting up backend server...
cd server

REM Install dependencies
echo    Installing dependencies...
call npm install
if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)
echo ✅ Dependencies installed

REM Setup environment
echo    Setting up environment...
if not exist ".env" (
    if exist ".env.local" (
        copy ".env.local" ".env" >nul
        echo ✅ Copied .env.local to .env
    ) else if exist ".env.example" (
        copy ".env.example" ".env" >nul
        echo ✅ Copied .env.example to .env
        echo ⚠️  Please update .env with your SQL Server password
    ) else (
        echo ❌ No environment template found
        pause
        exit /b 1
    )
) else (
    echo ✅ .env file already exists
)

REM Create logs directory
if not exist "logs" mkdir logs

REM Step 4: Database Setup
echo.
echo 4️⃣ Setting up database...
echo    This will create the database schema and test data...
echo    Make sure SQL Server is running before proceeding!
echo.
pause

node setup-sqlserver.js
if %errorlevel% neq 0 (
    echo ❌ Database setup failed
    echo.
    echo 🔧 Troubleshooting:
    echo    1. Make sure SQL Server is running
    echo    2. Update DB_PASSWORD in .env file
    echo    3. Check SQL Server connection settings
    echo.
    echo 📋 SQL Server Setup Options:
    echo.
    echo 🪟 Windows:
    echo    Download SQL Server Express: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
    echo.
    echo 🐳 Docker:
    echo    docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Passw0rd" ^
    echo       -p 1433:1433 --name sqlserver ^
    echo       -d mcr.microsoft.com/mssql/server:2022-latest
    echo.
    pause
    echo    Fix the issue and press any key to retry...
    pause
    node setup-sqlserver.js
    if %errorlevel% neq 0 (
        echo ❌ Database setup still failing. Please check the configuration.
        pause
        exit /b 1
    )
)
echo ✅ Database setup completed

REM Step 5: Start the server
echo.
echo 5️⃣ Starting the server...
echo    The server will start on http://localhost:3000
echo    Press Ctrl+C to stop the server
echo.
echo 🌐 Access URLs:
echo    Health Check:    http://localhost:3000/health
echo    API Docs:        http://localhost:3000/api-docs
echo    Admin Portal:    http://localhost:3000/admin
echo    API Base:        http://localhost:3000/api
echo.
echo 🔐 Test Credentials:
echo    Admin:           9999999999 / VMURUGAN_ADMIN_2025
echo    Customer:        9876543210 / test123
echo.

REM Start server with auto-reload
call npm run dev

#!/bin/bash

# =====================================================
# VMUrugan Gold Trading - Local Development Startup Script
# =====================================================

echo "🚀 Starting VMUrugan Gold Trading Platform Locally"
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "server/package-sqlserver.json" ]; then
    echo "❌ Please run this script from the project root directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected: vmurugan-gold-trading/"
    exit 1
fi

# Step 1: Check Node.js
echo ""
echo "1️⃣ Checking Node.js installation..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js found: $NODE_VERSION"
    
    # Check if version is 16 or higher
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
    if [ "$NODE_MAJOR" -lt 16 ]; then
        echo "⚠️  Node.js version 16+ required. Current: $NODE_VERSION"
        echo "   Please upgrade: https://nodejs.org/"
        exit 1
    fi
else
    echo "❌ Node.js not found. Please install Node.js 16+"
    echo "   Download from: https://nodejs.org/"
    exit 1
fi

# Step 2: Check SQL Server (optional check)
echo ""
echo "2️⃣ Checking SQL Server availability..."
if command -v sqlcmd &> /dev/null; then
    echo "✅ SQL Server tools found"
else
    echo "⚠️  SQL Server tools not found in PATH"
    echo "   This is OK if you're using Docker or have SQL Server installed differently"
fi

# Step 3: Setup Backend
echo ""
echo "3️⃣ Setting up backend server..."
cd server

# Install dependencies
echo "   Installing dependencies..."
if npm install; then
    echo "✅ Dependencies installed"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Setup environment
echo "   Setting up environment..."
if [ ! -f ".env" ]; then
    if [ -f ".env.local" ]; then
        cp .env.local .env
        echo "✅ Copied .env.local to .env"
    elif [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✅ Copied .env.example to .env"
        echo "⚠️  Please update .env with your SQL Server password"
    else
        echo "❌ No environment template found"
        exit 1
    fi
else
    echo "✅ .env file already exists"
fi

# Create logs directory
mkdir -p logs

# Step 4: Database Setup
echo ""
echo "4️⃣ Setting up database..."
echo "   This will create the database schema and test data..."
echo "   Make sure SQL Server is running before proceeding!"
echo ""
read -p "   Press Enter to continue or Ctrl+C to abort..."

if node setup-sqlserver.js; then
    echo "✅ Database setup completed"
else
    echo "❌ Database setup failed"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   1. Make sure SQL Server is running"
    echo "   2. Update DB_PASSWORD in .env file"
    echo "   3. Check SQL Server connection settings"
    echo ""
    echo "📋 SQL Server Setup Options:"
    echo ""
    echo "🪟 Windows:"
    echo "   Download SQL Server Express: https://www.microsoft.com/en-us/sql-server/sql-server-downloads"
    echo ""
    echo "🐳 Docker (All Platforms):"
    echo "   docker run -e \"ACCEPT_EULA=Y\" -e \"MSSQL_SA_PASSWORD=YourStrong@Passw0rd\" \\"
    echo "      -p 1433:1433 --name sqlserver \\"
    echo "      -d mcr.microsoft.com/mssql/server:2022-latest"
    echo ""
    read -p "   Fix the issue and press Enter to retry, or Ctrl+C to exit..."
    node setup-sqlserver.js || exit 1
fi

# Step 5: Start the server
echo ""
echo "5️⃣ Starting the server..."
echo "   The server will start on http://localhost:3000"
echo "   Press Ctrl+C to stop the server"
echo ""

# Start server with auto-reload
npm run dev

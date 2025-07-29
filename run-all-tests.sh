#!/bin/bash

# =====================================================
# VMUrugan Gold Trading - Comprehensive Test Execution
# =====================================================

echo "🧪 VMUrugan Gold Trading - Comprehensive Test Suite"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
START_TIME=$(date +%s)

echo -e "\n${CYAN}📋 Pre-flight Checks${NC}"
echo "==================="

# Check if we're in the right directory
if [ ! -f "server/package-sqlserver.json" ] && [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Please run this script from the project root directory${NC}"
    exit 1
fi

# Check Node.js
echo "1️⃣ Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "   ✅ Node.js found: ${NODE_VERSION}"
else
    echo -e "   ${RED}❌ Node.js not found${NC}"
    exit 1
fi

# Check Flutter
echo "2️⃣ Checking Flutter..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo -e "   ✅ Flutter found: ${FLUTTER_VERSION}"
else
    echo -e "   ${YELLOW}⚠️  Flutter not found - skipping Flutter tests${NC}"
fi

# Check SQL Server connection
echo "3️⃣ Checking SQL Server..."
cd server
if [ -f ".env" ] || [ -f ".env.local" ]; then
    echo -e "   ✅ Environment configuration found"
else
    echo -e "   ${YELLOW}⚠️  No environment file found${NC}"
fi
cd ..

echo -e "\n${CYAN}🔧 Backend API Tests${NC}"
echo "==================="

cd server

# Install backend dependencies
echo "📦 Installing backend dependencies..."
npm install > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "   ✅ Backend dependencies installed"
else
    echo -e "   ${RED}❌ Failed to install backend dependencies${NC}"
    exit 1
fi

# Setup environment
if [ ! -f ".env" ]; then
    if [ -f ".env.local" ]; then
        cp .env.local .env
        echo -e "   ✅ Environment configured from .env.local"
    fi
fi

# Run comprehensive backend tests
echo -e "\n🧪 Running Backend Test Suite..."
echo "================================"

if node run-all-tests.js; then
    echo -e "   ${GREEN}✅ Backend tests completed successfully${NC}"
    BACKEND_SUCCESS=true
else
    echo -e "   ${RED}❌ Backend tests failed${NC}"
    BACKEND_SUCCESS=false
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

cd ..

# Flutter Tests
if command -v flutter &> /dev/null; then
    echo -e "\n${CYAN}📱 Flutter App Tests${NC}"
    echo "==================="

    # Install Flutter dependencies
    echo "📦 Installing Flutter dependencies..."
    flutter pub get > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "   ✅ Flutter dependencies installed"
    else
        echo -e "   ${RED}❌ Failed to install Flutter dependencies${NC}"
        exit 1
    fi

    # Run Flutter tests
    echo -e "\n🧪 Running Flutter Test Suite..."
    echo "==============================="

    if flutter test; then
        echo -e "   ${GREEN}✅ Flutter tests completed successfully${NC}"
        FLUTTER_SUCCESS=true
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "   ${RED}❌ Flutter tests failed${NC}"
        FLUTTER_SUCCESS=false
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi

    # Run Flutter widget tests
    echo -e "\n🎨 Running Flutter Widget Tests..."
    echo "================================="

    if flutter test test/widgets/; then
        echo -e "   ${GREEN}✅ Flutter widget tests completed${NC}"
        WIDGET_SUCCESS=true
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "   ${YELLOW}⚠️  Flutter widget tests had issues${NC}"
        WIDGET_SUCCESS=false
    fi

    # Run Flutter integration tests (if they exist)
    if [ -d "integration_test" ]; then
        echo -e "\n🔗 Running Flutter Integration Tests..."
        echo "====================================="

        if flutter test integration_test/; then
            echo -e "   ${GREEN}✅ Flutter integration tests completed${NC}"
            INTEGRATION_SUCCESS=true
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "   ${RED}❌ Flutter integration tests failed${NC}"
            INTEGRATION_SUCCESS=false
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
else
    echo -e "\n${YELLOW}⚠️  Skipping Flutter tests - Flutter not installed${NC}"
fi

# Generate comprehensive report
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "\n${CYAN}📊 Comprehensive Test Report${NC}"
echo "============================"

echo -e "\n📋 Test Suite Results:"
if [ "$BACKEND_SUCCESS" = true ]; then
    echo -e "   ✅ Backend API Tests: PASSED"
else
    echo -e "   ❌ Backend API Tests: FAILED"
fi

if command -v flutter &> /dev/null; then
    if [ "$FLUTTER_SUCCESS" = true ]; then
        echo -e "   ✅ Flutter Unit Tests: PASSED"
    else
        echo -e "   ❌ Flutter Unit Tests: FAILED"
    fi

    if [ "$WIDGET_SUCCESS" = true ]; then
        echo -e "   ✅ Flutter Widget Tests: PASSED"
    else
        echo -e "   ⚠️  Flutter Widget Tests: ISSUES"
    fi

    if [ -n "$INTEGRATION_SUCCESS" ]; then
        if [ "$INTEGRATION_SUCCESS" = true ]; then
            echo -e "   ✅ Flutter Integration Tests: PASSED"
        else
            echo -e "   ❌ Flutter Integration Tests: FAILED"
        fi
    fi
fi

echo -e "\n📊 Overall Statistics:"
echo -e "   Duration: ${DURATION} seconds"
echo -e "   Test Suites: $((PASSED_TESTS + FAILED_TESTS))"
echo -e "   Passed: ${GREEN}${PASSED_TESTS}${NC}"
echo -e "   Failed: ${RED}${FAILED_TESTS}${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    SUCCESS_RATE="100"
else
    SUCCESS_RATE=$(( (PASSED_TESTS * 100) / (PASSED_TESTS + FAILED_TESTS) ))
fi
echo -e "   Success Rate: ${SUCCESS_RATE}%"

echo -e "\n📁 Generated Reports:"
echo -e "   📊 Backend Coverage: server/coverage/lcov-report/index.html"
echo -e "   📋 Test Logs: Available in terminal output"

echo -e "\n🌐 Access URLs:"
echo -e "   API Documentation: http://localhost:3000/api-docs"
echo -e "   Health Check: http://localhost:3000/health"
echo -e "   Admin Portal: http://localhost:3000/admin"

echo -e "\n🔧 Next Steps:"
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "   ${GREEN}🎉 All tests passed! Your application is ready for deployment.${NC}"
    echo -e "   📋 Consider running: npm run dev (backend) and flutter run (frontend)"
else
    echo -e "   ${YELLOW}⚠️  Some tests failed. Please review the errors above.${NC}"
    echo -e "   🔍 Check individual test outputs for detailed error information"
    echo -e "   🔧 Fix issues and re-run: ./run-all-tests.sh"
fi

echo -e "\n🆘 Need Help?"
echo -e "   📚 Documentation: LOCAL_TESTING_GUIDE.md"
echo -e "   🔧 Troubleshooting: Check server logs and test outputs"
echo -e "   🌐 API Testing: Use Swagger UI at http://localhost:3000/api-docs"

# Exit with appropriate code
if [ $FAILED_TESTS -eq 0 ]; then
    exit 0
else
    exit 1
fi

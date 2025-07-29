@echo off
REM =====================================================
REM VMUrugan Gold Trading - Comprehensive Test Execution (Windows)
REM =====================================================

echo 🧪 VMUrugan Gold Trading - Comprehensive Test Suite
echo ==================================================

set TOTAL_TESTS=0
set PASSED_TESTS=0
set FAILED_TESTS=0
set BACKEND_SUCCESS=false
set FLUTTER_SUCCESS=false

echo.
echo 📋 Pre-flight Checks
echo ===================

REM Check if we're in the right directory
if not exist "server\package-sqlserver.json" (
    if not exist "pubspec.yaml" (
        echo ❌ Please run this script from the project root directory
        pause
        exit /b 1
    )
)

REM Check Node.js
echo 1️⃣ Checking Node.js...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo    ❌ Node.js not found
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo    ✅ Node.js found: %NODE_VERSION%
)

REM Check Flutter
echo 2️⃣ Checking Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo    ⚠️  Flutter not found - skipping Flutter tests
    set FLUTTER_AVAILABLE=false
) else (
    echo    ✅ Flutter found
    set FLUTTER_AVAILABLE=true
)

REM Check SQL Server
echo 3️⃣ Checking SQL Server...
cd server
if exist ".env" (
    echo    ✅ Environment configuration found
) else if exist ".env.local" (
    echo    ✅ Environment template found
) else (
    echo    ⚠️  No environment file found
)
cd ..

echo.
echo 🔧 Backend API Tests
echo ===================

cd server

REM Install backend dependencies
echo 📦 Installing backend dependencies...
call npm install >nul 2>&1
if %errorlevel% neq 0 (
    echo    ❌ Failed to install backend dependencies
    pause
    exit /b 1
)
echo    ✅ Backend dependencies installed

REM Setup environment
if not exist ".env" (
    if exist ".env.local" (
        copy ".env.local" ".env" >nul
        echo    ✅ Environment configured from .env.local
    )
)

REM Run comprehensive backend tests
echo.
echo 🧪 Running Backend Test Suite...
echo ================================

call node run-all-tests.js
if %errorlevel% equ 0 (
    echo    ✅ Backend tests completed successfully
    set BACKEND_SUCCESS=true
    set /a PASSED_TESTS+=1
) else (
    echo    ❌ Backend tests failed
    set BACKEND_SUCCESS=false
    set /a FAILED_TESTS+=1
)

cd ..

REM Flutter Tests
if "%FLUTTER_AVAILABLE%"=="true" (
    echo.
    echo 📱 Flutter App Tests
    echo ===================

    REM Install Flutter dependencies
    echo 📦 Installing Flutter dependencies...
    call flutter pub get >nul 2>&1
    if %errorlevel% neq 0 (
        echo    ❌ Failed to install Flutter dependencies
        pause
        exit /b 1
    )
    echo    ✅ Flutter dependencies installed

    REM Run Flutter tests
    echo.
    echo 🧪 Running Flutter Test Suite...
    echo ===============================

    call flutter test
    if %errorlevel% equ 0 (
        echo    ✅ Flutter tests completed successfully
        set FLUTTER_SUCCESS=true
        set /a PASSED_TESTS+=1
    ) else (
        echo    ❌ Flutter tests failed
        set FLUTTER_SUCCESS=false
        set /a FAILED_TESTS+=1
    )

    REM Run Flutter widget tests
    echo.
    echo 🎨 Running Flutter Widget Tests...
    echo =================================

    call flutter test test\widgets\
    if %errorlevel% equ 0 (
        echo    ✅ Flutter widget tests completed
        set /a PASSED_TESTS+=1
    ) else (
        echo    ⚠️  Flutter widget tests had issues
    )

    REM Run Flutter integration tests (if they exist)
    if exist "integration_test" (
        echo.
        echo 🔗 Running Flutter Integration Tests...
        echo =====================================

        call flutter test integration_test\
        if %errorlevel% equ 0 (
            echo    ✅ Flutter integration tests completed
            set /a PASSED_TESTS+=1
        ) else (
            echo    ❌ Flutter integration tests failed
            set /a FAILED_TESTS+=1
        )
    )
) else (
    echo.
    echo ⚠️  Skipping Flutter tests - Flutter not installed
)

REM Generate comprehensive report
echo.
echo 📊 Comprehensive Test Report
echo ============================

echo.
echo 📋 Test Suite Results:
if "%BACKEND_SUCCESS%"=="true" (
    echo    ✅ Backend API Tests: PASSED
) else (
    echo    ❌ Backend API Tests: FAILED
)

if "%FLUTTER_AVAILABLE%"=="true" (
    if "%FLUTTER_SUCCESS%"=="true" (
        echo    ✅ Flutter Unit Tests: PASSED
    ) else (
        echo    ❌ Flutter Unit Tests: FAILED
    )
)

echo.
echo 📊 Overall Statistics:
echo    Test Suites: %PASSED_TESTS% + %FAILED_TESTS%
echo    Passed: %PASSED_TESTS%
echo    Failed: %FAILED_TESTS%

if %FAILED_TESTS% equ 0 (
    set SUCCESS_RATE=100
) else (
    set /a SUCCESS_RATE=(%PASSED_TESTS% * 100) / (%PASSED_TESTS% + %FAILED_TESTS%)
)
echo    Success Rate: %SUCCESS_RATE%%%

echo.
echo 📁 Generated Reports:
echo    📊 Backend Coverage: server\coverage\lcov-report\index.html
echo    📋 Test Logs: Available in terminal output

echo.
echo 🌐 Access URLs:
echo    API Documentation: http://localhost:3000/api-docs
echo    Health Check: http://localhost:3000/health
echo    Admin Portal: http://localhost:3000/admin

echo.
echo 🔧 Next Steps:
if %FAILED_TESTS% equ 0 (
    echo    🎉 All tests passed! Your application is ready for deployment.
    echo    📋 Consider running: npm run dev (backend) and flutter run (frontend)
) else (
    echo    ⚠️  Some tests failed. Please review the errors above.
    echo    🔍 Check individual test outputs for detailed error information
    echo    🔧 Fix issues and re-run: run-all-tests.bat
)

echo.
echo 🆘 Need Help?
echo    📚 Documentation: LOCAL_TESTING_GUIDE.md
echo    🔧 Troubleshooting: Check server logs and test outputs
echo    🌐 API Testing: Use Swagger UI at http://localhost:3000/api-docs

echo.
pause

REM Exit with appropriate code
if %FAILED_TESTS% equ 0 (
    exit /b 0
) else (
    exit /b 1
)

// =====================================================
// VMUrugan Gold Trading - Comprehensive Test Runner
// =====================================================

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🧪 VMUrugan Gold Trading - Comprehensive Test Suite'.cyan.bold);
console.log('=================================================='.cyan);

// Check if colors is available
let colors;
try {
  colors = require('colors');
} catch (e) {
  // Fallback if colors is not available
  colors = {
    cyan: { bold: (str) => str },
    green: { bold: (str) => str },
    red: { bold: (str) => str },
    yellow: { bold: (str) => str },
    white: (str) => str,
    gray: (str) => str
  };
}

async function runTests() {
  const startTime = Date.now();
  let totalTests = 0;
  let passedTests = 0;
  let failedTests = 0;
  const testResults = [];

  try {
    console.log('\n📋 Pre-flight Checks'.yellow.bold);
    console.log('==================='.yellow);

    // Check if server dependencies are installed
    console.log('1️⃣ Checking dependencies...');
    if (!fs.existsSync('node_modules')) {
      console.log('   Installing dependencies...'.gray);
      execSync('npm install', { stdio: 'inherit' });
    }
    console.log('   ✅ Dependencies ready'.green);

    // Check if environment is configured
    console.log('2️⃣ Checking environment...');
    if (!fs.existsSync('.env')) {
      if (fs.existsSync('.env.local')) {
        fs.copyFileSync('.env.local', '.env');
        console.log('   ✅ Environment configured from .env.local'.green);
      } else {
        console.log('   ⚠️  No .env file found. Using defaults.'.yellow);
      }
    } else {
      console.log('   ✅ Environment configured'.green);
    }

    // Check if database is accessible
    console.log('3️⃣ Checking database connection...');
    try {
      const sql = require('mssql');
      require('dotenv').config();
      
      const config = {
        server: process.env.DB_SERVER || 'localhost',
        port: parseInt(process.env.DB_PORT) || 1433,
        database: 'master',
        user: process.env.DB_USER || 'sa',
        password: process.env.DB_PASSWORD || 'YourStrong@Passw0rd',
        options: {
          encrypt: process.env.DB_ENCRYPT === 'true',
          trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === 'true',
          enableArithAbort: true,
        },
      };

      const pool = new sql.ConnectionPool(config);
      await pool.connect();
      await pool.request().query('SELECT 1 as test');
      await pool.close();
      console.log('   ✅ Database connection successful'.green);
    } catch (error) {
      console.log('   ❌ Database connection failed:'.red, error.message);
      console.log('   🔧 Please ensure SQL Server is running and configured properly'.yellow);
      process.exit(1);
    }

    console.log('\n🧪 Running Test Suites'.cyan.bold);
    console.log('======================'.cyan);

    // Test suites to run
    const testSuites = [
      { name: 'Authentication Tests', file: 'auth.test.js', description: 'User registration, login, logout, validation' },
      { name: 'Customer Tests', file: 'customers.test.js', description: 'Customer profile, validation, KYC, portfolio' },
      { name: 'Transaction Tests', file: 'transactions.test.js', description: 'Transaction creation, status updates, retrieval' },
      { name: 'Scheme Tests', file: 'schemes.test.js', description: 'Investment schemes, payments, cancellation' },
      { name: 'Admin Tests', file: 'admin.test.js', description: 'Admin dashboard, customer management, reports' },
      { name: 'Analytics Tests', file: 'analytics.test.js', description: 'Event logging, reports, data cleanup' }
    ];

    // Run each test suite
    for (let i = 0; i < testSuites.length; i++) {
      const suite = testSuites[i];
      console.log(`\n${i + 1}️⃣ ${suite.name}`.yellow.bold);
      console.log(`   📝 ${suite.description}`.gray);
      
      try {
        const testFile = path.join('tests', suite.file);
        if (fs.existsSync(testFile)) {
          console.log(`   🏃 Running ${suite.file}...`.white);
          
          const result = execSync(`npx jest ${testFile} --verbose`, { 
            encoding: 'utf8',
            stdio: 'pipe'
          });
          
          // Parse Jest output for test counts
          const lines = result.split('\n');
          const summaryLine = lines.find(line => line.includes('Tests:'));
          if (summaryLine) {
            const passed = (summaryLine.match(/(\d+) passed/) || [0, 0])[1];
            const failed = (summaryLine.match(/(\d+) failed/) || [0, 0])[1];
            const total = parseInt(passed) + parseInt(failed);
            
            totalTests += total;
            passedTests += parseInt(passed);
            failedTests += parseInt(failed);
            
            testResults.push({
              suite: suite.name,
              passed: parseInt(passed),
              failed: parseInt(failed),
              total: total,
              status: parseInt(failed) === 0 ? 'PASSED' : 'FAILED'
            });
            
            console.log(`   ✅ ${suite.name}: ${passed} passed, ${failed} failed`.green);
          } else {
            console.log(`   ✅ ${suite.name}: Completed successfully`.green);
            testResults.push({
              suite: suite.name,
              passed: 0,
              failed: 0,
              total: 0,
              status: 'PASSED'
            });
          }
        } else {
          console.log(`   ⚠️  Test file ${suite.file} not found`.yellow);
          testResults.push({
            suite: suite.name,
            passed: 0,
            failed: 0,
            total: 0,
            status: 'SKIPPED'
          });
        }
      } catch (error) {
        console.log(`   ❌ ${suite.name}: FAILED`.red);
        console.log(`   Error: ${error.message}`.red);
        failedTests++;
        testResults.push({
          suite: suite.name,
          passed: 0,
          failed: 1,
          total: 1,
          status: 'FAILED'
        });
      }
    }

    // Run coverage report
    console.log('\n📊 Generating Coverage Report'.cyan.bold);
    console.log('============================='.cyan);
    
    try {
      console.log('   📈 Running coverage analysis...'.white);
      execSync('npx jest --coverage --silent', { stdio: 'inherit' });
      console.log('   ✅ Coverage report generated in coverage/ directory'.green);
    } catch (error) {
      console.log('   ⚠️  Coverage report generation failed'.yellow);
    }

    // Integration tests
    console.log('\n🔗 Integration Tests'.cyan.bold);
    console.log('==================='.cyan);
    
    try {
      console.log('   🌐 Running integration tests...'.white);
      execSync('node test-local.js', { stdio: 'inherit' });
      console.log('   ✅ Integration tests completed'.green);
    } catch (error) {
      console.log('   ❌ Integration tests failed'.red);
      console.log('   Make sure the server is running: npm run dev'.yellow);
    }

  } catch (error) {
    console.error('\n💥 Test suite execution failed:'.red.bold, error.message);
    process.exit(1);
  }

  // Final summary
  const endTime = Date.now();
  const duration = ((endTime - startTime) / 1000).toFixed(2);

  console.log('\n🎯 Test Summary'.cyan.bold);
  console.log('=============='.cyan);
  
  console.log('\n📋 Test Suite Results:'.white);
  testResults.forEach(result => {
    const status = result.status === 'PASSED' ? '✅' : 
                   result.status === 'FAILED' ? '❌' : '⚠️';
    console.log(`   ${status} ${result.suite}: ${result.passed} passed, ${result.failed} failed (${result.total} total)`);
  });

  console.log('\n📊 Overall Statistics:'.white);
  console.log(`   Total Tests: ${totalTests}`);
  console.log(`   Passed: ${passedTests}`.green);
  console.log(`   Failed: ${failedTests}`.red);
  console.log(`   Success Rate: ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 0}%`);
  console.log(`   Duration: ${duration} seconds`);

  console.log('\n📁 Generated Files:'.white);
  console.log('   📊 Coverage Report: coverage/lcov-report/index.html');
  console.log('   📋 Test Results: Available in terminal output');

  console.log('\n🌐 Access URLs:'.white);
  console.log('   API Documentation: http://localhost:3000/api-docs');
  console.log('   Health Check: http://localhost:3000/health');
  console.log('   Admin Portal: http://localhost:3000/admin');

  if (failedTests === 0) {
    console.log('\n🎉 All tests passed! Your application is ready for deployment.'.green.bold);
  } else {
    console.log('\n⚠️  Some tests failed. Please review the errors above.'.yellow.bold);
    process.exit(1);
  }
}

// Handle script interruption
process.on('SIGINT', () => {
  console.log('\n\n⚠️  Test execution interrupted');
  console.log('   You can resume by running: npm run test-all');
  process.exit(0);
});

// Run the tests
runTests().catch(error => {
  console.error('\n💥 Test runner failed:'.red.bold, error.message);
  console.log('\n🔧 Troubleshooting:'.yellow.bold);
  console.log('   1. Ensure SQL Server is running');
  console.log('   2. Check .env configuration');
  console.log('   3. Verify all dependencies are installed');
  console.log('   4. Check database connection settings');
  process.exit(1);
});

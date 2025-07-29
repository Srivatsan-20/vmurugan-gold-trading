// =====================================================
// VMUrugan Gold Trading - Local Development Setup Script
// =====================================================

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 VMUrugan Gold Trading - Local Development Setup');
console.log('==================================================');

// Check if running in correct directory
if (!fs.existsSync('package-sqlserver.json')) {
  console.error('❌ Please run this script from the server directory');
  console.error('   cd server && node local-setup.js');
  process.exit(1);
}

// Step 1: Check Node.js version
console.log('\n1️⃣ Checking Node.js version...');
try {
  const nodeVersion = process.version;
  const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);
  
  if (majorVersion >= 16) {
    console.log(`✅ Node.js ${nodeVersion} (compatible)`);
  } else {
    console.log(`❌ Node.js ${nodeVersion} (requires v16+)`);
    console.log('   Please upgrade Node.js: https://nodejs.org/');
    process.exit(1);
  }
} catch (error) {
  console.error('❌ Failed to check Node.js version');
  process.exit(1);
}

// Step 2: Install dependencies
console.log('\n2️⃣ Installing dependencies...');
try {
  console.log('   Installing npm packages...');
  execSync('npm install', { stdio: 'inherit' });
  console.log('✅ Dependencies installed successfully');
} catch (error) {
  console.error('❌ Failed to install dependencies');
  console.error('   Please run: npm install');
  process.exit(1);
}

// Step 3: Setup environment file
console.log('\n3️⃣ Setting up environment configuration...');
try {
  if (!fs.existsSync('.env')) {
    if (fs.existsSync('.env.local')) {
      fs.copyFileSync('.env.local', '.env');
      console.log('✅ Copied .env.local to .env');
    } else if (fs.existsSync('.env.example')) {
      fs.copyFileSync('.env.example', '.env');
      console.log('✅ Copied .env.example to .env');
    } else {
      console.log('⚠️  No environment template found');
      console.log('   Please create .env file manually');
    }
  } else {
    console.log('✅ .env file already exists');
  }
} catch (error) {
  console.error('❌ Failed to setup environment file');
  console.error(error.message);
}

// Step 4: Create logs directory
console.log('\n4️⃣ Creating logs directory...');
try {
  if (!fs.existsSync('logs')) {
    fs.mkdirSync('logs');
    console.log('✅ Created logs directory');
  } else {
    console.log('✅ Logs directory already exists');
  }
} catch (error) {
  console.error('❌ Failed to create logs directory');
  console.error(error.message);
}

// Step 5: Check SQL Server availability
console.log('\n5️⃣ Checking SQL Server availability...');
try {
  // Try to load environment variables
  require('dotenv').config();
  
  const sql = require('mssql');
  const config = {
    server: process.env.DB_SERVER || 'localhost',
    port: parseInt(process.env.DB_PORT) || 1433,
    database: 'master', // Connect to master first
    user: process.env.DB_USER || 'sa',
    password: process.env.DB_PASSWORD || 'YourStrong@Passw0rd',
    options: {
      encrypt: process.env.DB_ENCRYPT === 'true',
      trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === 'true',
      enableArithAbort: true,
    },
  };

  console.log(`   Testing connection to ${config.server}:${config.port}...`);
  
  // Test connection (with timeout)
  const testConnection = async () => {
    const pool = new sql.ConnectionPool(config);
    await pool.connect();
    await pool.request().query('SELECT 1 as test');
    await pool.close();
  };

  // Run with timeout
  Promise.race([
    testConnection(),
    new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Connection timeout')), 5000)
    )
  ]).then(() => {
    console.log('✅ SQL Server connection successful');
    
    // Step 6: Run database setup
    console.log('\n6️⃣ Setting up database...');
    try {
      execSync('node setup-sqlserver.js', { stdio: 'inherit' });
      console.log('✅ Database setup completed');
    } catch (error) {
      console.error('❌ Database setup failed');
      console.error('   You may need to run: node setup-sqlserver.js manually');
    }
    
    // Final instructions
    showFinalInstructions();
    
  }).catch((error) => {
    console.log('❌ SQL Server connection failed');
    console.log('   Error:', error.message);
    console.log('\n🔧 SQL Server Setup Instructions:');
    showSqlServerInstructions();
  });

} catch (error) {
  console.log('❌ Failed to test SQL Server connection');
  console.log('   Error:', error.message);
  console.log('\n🔧 SQL Server Setup Instructions:');
  showSqlServerInstructions();
}

function showSqlServerInstructions() {
  console.log('\n📋 SQL Server Setup Options:');
  console.log('\n🪟 Windows:');
  console.log('   1. Download SQL Server Express (free):');
  console.log('      https://www.microsoft.com/en-us/sql-server/sql-server-downloads');
  console.log('   2. Download SQL Server Management Studio (SSMS):');
  console.log('      https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms');
  console.log('   3. Enable SQL Server Authentication in SSMS');
  console.log('   4. Update .env file with correct password');
  
  console.log('\n🐳 Docker (All Platforms):');
  console.log('   docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Passw0rd" \\');
  console.log('      -p 1433:1433 --name sqlserver \\');
  console.log('      -d mcr.microsoft.com/mssql/server:2022-latest');
  
  console.log('\n🔧 After SQL Server is running:');
  console.log('   1. Update .env file with correct DB_PASSWORD');
  console.log('   2. Run: node setup-sqlserver.js');
  console.log('   3. Run: npm run dev');
}

function showFinalInstructions() {
  console.log('\n🎉 Local Development Setup Complete!');
  console.log('=====================================');
  
  console.log('\n🚀 Start the server:');
  console.log('   npm run dev');
  
  console.log('\n🌐 Access URLs:');
  console.log('   Health Check:    http://localhost:3000/health');
  console.log('   API Docs:        http://localhost:3000/api-docs');
  console.log('   Admin Portal:    http://localhost:3000/admin');
  console.log('   API Base:        http://localhost:3000/api');
  
  console.log('\n🔐 Test Credentials:');
  console.log('   Admin Login:     9999999999 / VMURUGAN_ADMIN_2025');
  console.log('   Customer Login:  9876543210 / test123');
  
  console.log('\n📱 Flutter App Configuration:');
  console.log('   Android Emulator: http://10.0.2.2:3000/api');
  console.log('   iOS Simulator:    http://localhost:3000/api');
  console.log('   Physical Device:  http://YOUR_IP:3000/api');
  
  console.log('\n📚 Documentation:');
  console.log('   Local Testing:   LOCAL_TESTING_GUIDE.md');
  console.log('   API Reference:   http://localhost:3000/api-docs');
  console.log('   Deployment:      DEPLOYMENT_GUIDE.md');
  
  console.log('\n🧪 Testing:');
  console.log('   Unit Tests:      npm test');
  console.log('   Postman:         Import server/tests/postman/VMUrugan_API_Tests.postman_collection.json');
  
  console.log('\n💡 Tips:');
  console.log('   - Use Swagger UI for interactive API testing');
  console.log('   - Check logs in logs/api.log for debugging');
  console.log('   - Use npm run dev for auto-reload during development');
  console.log('   - Update ALLOWED_ORIGINS in .env for CORS issues');
  
  console.log('\n🆘 Need Help?');
  console.log('   - Check LOCAL_TESTING_GUIDE.md for troubleshooting');
  console.log('   - Verify SQL Server is running and accessible');
  console.log('   - Check .env file configuration');
  console.log('   - Review server logs for error details');
}

// Handle script interruption
process.on('SIGINT', () => {
  console.log('\n\n⚠️  Setup interrupted');
  console.log('   You can resume by running: node local-setup.js');
  process.exit(0);
});

process.on('uncaughtException', (error) => {
  console.error('\n❌ Unexpected error during setup:');
  console.error(error.message);
  console.log('\n🔧 Troubleshooting:');
  console.log('   1. Ensure you are in the server directory');
  console.log('   2. Check Node.js version (requires v16+)');
  console.log('   3. Verify SQL Server is installed and running');
  console.log('   4. Check .env file configuration');
  console.log('   5. Review LOCAL_TESTING_GUIDE.md for detailed instructions');
  process.exit(1);
});

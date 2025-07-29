// =====================================================
// SQL Server Connection Test
// =====================================================

const sql = require('mssql');
require('dotenv').config();

async function testConnection() {
  console.log('🔍 Testing SQL Server Connection...');
  console.log('=====================================');

  // Test different connection configurations
  const configs = [
    {
      name: 'Windows Auth - localhost',
      config: {
        server: 'localhost',
        database: 'master',
        options: {
          encrypt: false,
          trustServerCertificate: true,
          enableArithAbort: true,
          integratedSecurity: true,
        },
      }
    },
    {
      name: 'Windows Auth - (local)',
      config: {
        server: '(local)',
        database: 'master',
        options: {
          encrypt: false,
          trustServerCertificate: true,
          enableArithAbort: true,
          integratedSecurity: true,
        },
      }
    },
    {
      name: 'Windows Auth - .\\MSSQLSERVER',
      config: {
        server: '.\\MSSQLSERVER',
        database: 'master',
        options: {
          encrypt: false,
          trustServerCertificate: true,
          enableArithAbort: true,
          integratedSecurity: true,
        },
      }
    },
    {
      name: 'TCP/IP - localhost:1433',
      config: {
        server: 'localhost',
        port: 1433,
        database: 'master',
        options: {
          encrypt: false,
          trustServerCertificate: true,
          enableArithAbort: true,
          integratedSecurity: true,
        },
      }
    }
  ];

  for (const testConfig of configs) {
    console.log(`\n🧪 Testing: ${testConfig.name}`);
    console.log('-----------------------------------');
    
    try {
      const pool = new sql.ConnectionPool(testConfig.config);
      await pool.connect();
      
      const result = await pool.request().query('SELECT @@VERSION as version, @@SERVERNAME as server_name');
      console.log('✅ Connection successful!');
      console.log(`   Server: ${result.recordset[0].server_name}`);
      console.log(`   Version: ${result.recordset[0].version.split('\n')[0]}`);
      
      await pool.close();
      
      // If this config works, save it
      console.log('\n🎯 Working configuration found!');
      console.log('Update your .env file with:');
      console.log(`DB_SERVER=${testConfig.config.server}`);
      if (testConfig.config.port) {
        console.log(`DB_PORT=${testConfig.config.port}`);
      } else {
        console.log('DB_PORT=');
      }
      console.log('DB_INTEGRATED_SECURITY=true');
      console.log('DB_ENCRYPT=false');
      console.log('DB_TRUST_SERVER_CERTIFICATE=true');
      
      return testConfig.config;
      
    } catch (error) {
      console.log('❌ Connection failed:');
      console.log(`   Error: ${error.message}`);
    }
  }
  
  console.log('\n💡 Troubleshooting Tips:');
  console.log('========================');
  console.log('1. Make sure SQL Server is running:');
  console.log('   Get-Service | Where-Object {$_.Name -like "*SQL*"}');
  console.log('');
  console.log('2. Check SQL Server Configuration Manager:');
  console.log('   - Enable TCP/IP protocol');
  console.log('   - Enable Named Pipes protocol');
  console.log('   - Restart SQL Server service');
  console.log('');
  console.log('3. Try connecting with SSMS using:');
  console.log('   - Server: localhost');
  console.log('   - Authentication: Windows Authentication');
  console.log('');
  console.log('4. If using SQL Server Express, try:');
  console.log('   - Server: localhost\\SQLEXPRESS');
  console.log('   - Or: .\\SQLEXPRESS');
}

// Run the test
testConnection().catch(error => {
  console.error('\n💥 Test failed:', error.message);
  process.exit(1);
});

// =====================================================
// SQL Server SQL Authentication Test
// =====================================================

const sql = require('mssql');
require('dotenv').config();

async function testSQLAuth() {
  console.log('🔍 Testing SQL Server with SQL Authentication...');
  console.log('================================================');

  const config = {
    server: 'localhost',
    port: 1433,
    database: 'master',
    user: 'sa',
    password: 'YourStrong@Passw0rd',
    options: {
      encrypt: false,
      trustServerCertificate: true,
      enableArithAbort: true,
    },
  };

  console.log('Configuration:');
  console.log(`  Server: ${config.server}:${config.port}`);
  console.log(`  User: ${config.user}`);
  console.log(`  Database: ${config.database}`);
  console.log(`  Encrypt: ${config.options.encrypt}`);
  console.log(`  Trust Certificate: ${config.options.trustServerCertificate}`);

  try {
    console.log('\n🔌 Connecting to SQL Server...');
    const pool = new sql.ConnectionPool(config);
    await pool.connect();
    
    console.log('✅ Connection successful!');
    
    console.log('\n🧪 Testing query...');
    const result = await pool.request().query('SELECT @@VERSION as version, @@SERVERNAME as server_name, DB_NAME() as database_name');
    
    console.log('✅ Query successful!');
    console.log(`   Server: ${result.recordset[0].server_name}`);
    console.log(`   Database: ${result.recordset[0].database_name}`);
    console.log(`   Version: ${result.recordset[0].version.split('\n')[0]}`);
    
    await pool.close();
    console.log('\n🎉 SQL Authentication is working correctly!');
    
    return true;
    
  } catch (error) {
    console.log('\n❌ Connection failed:');
    console.log(`   Error Code: ${error.code}`);
    console.log(`   Error Message: ${error.message}`);
    
    if (error.code === 'ELOGIN') {
      console.log('\n🔧 Login Error Troubleshooting:');
      console.log('   1. Check if SA account is enabled in SSMS');
      console.log('   2. Verify Mixed Mode Authentication is enabled');
      console.log('   3. Confirm the password is correct');
      console.log('   4. Restart SQL Server after making changes');
    }
    
    return false;
  }
}

// Run the test
testSQLAuth().then(success => {
  if (success) {
    console.log('\n✅ Ready to start the application!');
    process.exit(0);
  } else {
    console.log('\n❌ Please fix the SQL Server configuration first.');
    process.exit(1);
  }
}).catch(error => {
  console.error('\n💥 Test failed:', error.message);
  process.exit(1);
});

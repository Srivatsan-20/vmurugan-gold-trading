// =====================================================
// VMUrugan Gold Trading - Clean Mock Data Script
// Removes all test/mock data from database
// =====================================================

const sql = require('mssql');
require('dotenv').config();

async function cleanMockData() {
  let pool;
  
  try {
    console.log('🧹 Starting mock data cleanup...\n');

    // Connect to database
    pool = await sql.connect({
      server: process.env.DB_SERVER || 'localhost',
      database: process.env.DB_NAME || 'VMUruganGoldTrading',
      user: process.env.DB_USER || 'sa',
      password: process.env.DB_PASSWORD,
      options: {
        encrypt: false,
        trustServerCertificate: true
      }
    });

    console.log('✅ Connected to database');

    // 1. Delete all transactions (they reference customers)
    console.log('\n1️⃣ Cleaning transactions...');
    const transactionsResult = await pool.request().query('DELETE FROM transactions');
    console.log(`   ✅ Deleted ${transactionsResult.rowsAffected[0]} transactions`);

    // 2. Delete all schemes (they reference customers)
    console.log('\n2️⃣ Cleaning schemes...');
    const schemesResult = await pool.request().query('DELETE FROM schemes');
    console.log(`   ✅ Deleted ${schemesResult.rowsAffected[0]} schemes`);

    // 3. Delete all scheme payments (they reference schemes)
    console.log('\n3️⃣ Cleaning scheme payments...');
    const paymentsResult = await pool.request().query('DELETE FROM scheme_payments');
    console.log(`   ✅ Deleted ${paymentsResult.rowsAffected[0]} scheme payments`);

    // 4. Delete all customers except admin-related ones
    console.log('\n4️⃣ Cleaning customers...');
    const customersResult = await pool.request().query(`
      DELETE FROM customers 
      WHERE phone != '9999999999'
    `);
    console.log(`   ✅ Deleted ${customersResult.rowsAffected[0]} test customers`);

    // 5. Delete all sessions first (to avoid foreign key constraints)
    console.log('\n5️⃣ Cleaning sessions...');
    const sessionsResult = await pool.request().query('DELETE FROM sessions');
    console.log(`   ✅ Deleted ${sessionsResult.rowsAffected[0]} sessions`);

    // 6. Delete all test users (keep only admin)
    console.log('\n6️⃣ Cleaning users...');
    const usersResult = await pool.request().query(`
      DELETE FROM users
      WHERE phone != '9999999999' AND role != 'admin'
    `);
    console.log(`   ✅ Deleted ${usersResult.rowsAffected[0]} test users`);

    // 7. Clean analytics events (optional - keep some for system health)
    console.log('\n7️⃣ Cleaning analytics...');
    const analyticsResult = await pool.request().query(`
      DELETE FROM analytics
      WHERE event_name LIKE '%test%' OR event_name LIKE '%demo%' OR event_name LIKE '%mock%'
    `);
    console.log(`   ✅ Deleted ${analyticsResult.rowsAffected[0]} test analytics events`);

    // 8. Note: Customer IDs are auto-generated, no counter reset needed
    console.log('\n8️⃣ Customer ID generation will start fresh automatically');

    // 8. Show final state
    console.log('\n📊 Final database state:');
    
    const finalUsers = await pool.request().query('SELECT COUNT(*) as count FROM users');
    console.log(`   👥 Users remaining: ${finalUsers.recordset[0].count}`);
    
    const finalCustomers = await pool.request().query('SELECT COUNT(*) as count FROM customers');
    console.log(`   🏪 Customers remaining: ${finalCustomers.recordset[0].count}`);
    
    const finalTransactions = await pool.request().query('SELECT COUNT(*) as count FROM transactions');
    console.log(`   💳 Transactions remaining: ${finalTransactions.recordset[0].count}`);
    
    const finalSchemes = await pool.request().query('SELECT COUNT(*) as count FROM schemes');
    console.log(`   💰 Schemes remaining: ${finalSchemes.recordset[0].count}`);

    // Show remaining users
    const remainingUsers = await pool.request().query('SELECT phone, name, role FROM users');
    console.log('\n🔐 Remaining users:');
    remainingUsers.recordset.forEach(u => {
      console.log(`   - ${u.phone} (${u.name}) - ${u.role}`);
    });

    console.log('\n🎉 Mock data cleanup completed successfully!');
    console.log('✅ Database is now clean and ready for production use');
    console.log('🔑 Admin login: 9999999999 / VMURUGAN_ADMIN_2025');

  } catch (error) {
    console.error('\n❌ Error during cleanup:', error.message);
    throw error;
  } finally {
    if (pool) {
      await pool.close();
      console.log('\n🔌 Database connection closed');
    }
  }
}

// Run the cleanup
if (require.main === module) {
  cleanMockData()
    .then(() => {
      console.log('\n✅ Cleanup script completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Cleanup script failed:', error.message);
      process.exit(1);
    });
}

module.exports = { cleanMockData };

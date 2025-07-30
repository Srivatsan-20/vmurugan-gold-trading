// =====================================================
// Create Admin User with Proper Password Hash
// =====================================================

const bcrypt = require('bcrypt');
const sql = require('mssql');
require('dotenv').config();

async function createAdminUser() {
  console.log('🔐 Creating admin user with proper password hash...');
  
  try {
    // Hash the admin password
    const adminPassword = process.env.ADMIN_DEFAULT_PASSWORD || 'VMURUGAN_ADMIN_2025';
    const passwordHash = await bcrypt.hash(adminPassword, 10);
    
    console.log(`   Password: ${adminPassword}`);
    console.log(`   Hash: ${passwordHash.substring(0, 20)}...`);
    
    // Connect to database
    const config = {
      server: process.env.DB_SERVER || 'localhost',
      port: parseInt(process.env.DB_PORT) || 1433,
      database: process.env.DB_NAME || 'VMUruganGoldTrading',
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      options: {
        encrypt: process.env.DB_ENCRYPT === 'true',
        trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === 'true',
        enableArithAbort: true,
      },
    };
    
    const pool = new sql.ConnectionPool(config);
    await pool.connect();
    
    // Insert admin user
    await pool.request()
      .input('phone', sql.NVarChar, '9999999999')
      .input('email', sql.NVarChar, 'admin@vmurugan.com')
      .input('passwordHash', sql.NVarChar, passwordHash)
      .input('name', sql.NVarChar, 'VMUrugan Admin')
      .query(`
        INSERT INTO users (phone, email, password_hash, name, role, is_active)
        VALUES (@phone, @email, @passwordHash, @name, 'admin', 1)
      `);
    
    console.log('✅ Admin user created successfully');
    console.log('');
    console.log('🎯 Login Credentials:');
    console.log('   Admin: 9999999999 / VMURUGAN_ADMIN_2025');
    
    await pool.close();
    
  } catch (error) {
    console.error('❌ Failed to create admin user:', error.message);
    process.exit(1);
  }
}

createAdminUser();

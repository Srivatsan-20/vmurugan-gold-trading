// =====================================================
// VMUrugan Gold Trading - SQL Server Setup Script
// =====================================================

const sql = require('mssql');
const bcrypt = require('bcryptjs');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const dbConfig = {
  server: process.env.DB_SERVER || 'localhost',
  port: parseInt(process.env.DB_PORT) || 1433,
  database: 'master', // Connect to master first to create database
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  options: {
    encrypt: process.env.DB_ENCRYPT === 'true',
    trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === 'true',
    enableArithAbort: true,
  },
};

const targetDbConfig = {
  ...dbConfig,
  database: process.env.DB_NAME || 'VMUruganGoldTrading'
};

async function setupDatabase() {
  let pool;
  
  try {
    console.log('🔄 Starting VMUrugan Gold Trading Database Setup...');
    console.log(`📊 Server: ${dbConfig.server}:${dbConfig.port}`);
    console.log(`🗄️  Target Database: ${targetDbConfig.database}`);

    // Connect to master database
    console.log('\n1️⃣ Connecting to SQL Server...');
    pool = await sql.connect(dbConfig);
    console.log('✅ Connected to SQL Server');

    // Check if database exists
    console.log('\n2️⃣ Checking if database exists...');
    const dbCheckResult = await pool.request()
      .input('dbName', sql.NVarChar, targetDbConfig.database)
      .query(`
        SELECT database_id 
        FROM sys.databases 
        WHERE name = @dbName
      `);

    if (dbCheckResult.recordset.length === 0) {
      console.log(`📝 Creating database: ${targetDbConfig.database}`);
      await pool.request()
        .query(`CREATE DATABASE [${targetDbConfig.database}]`);
      console.log('✅ Database created successfully');
    } else {
      console.log('✅ Database already exists');
    }

    // Close connection to master
    await pool.close();

    // Connect to target database
    console.log('\n3️⃣ Connecting to target database...');
    pool = await sql.connect(targetDbConfig);
    console.log('✅ Connected to target database');

    // Read and execute schema script
    console.log('\n4️⃣ Creating database schema...');
    const schemaPath = path.join(__dirname, '..', 'sql_server_schema.sql');
    
    if (!fs.existsSync(schemaPath)) {
      throw new Error(`Schema file not found: ${schemaPath}`);
    }

    const schemaScript = fs.readFileSync(schemaPath, 'utf8');
    
    // Split script by GO statements and execute each batch
    const batches = schemaScript
      .split(/\r?\nGO\r?\n/gi)
      .filter(batch => batch.trim().length > 0)
      .map(batch => batch.trim());

    for (let i = 0; i < batches.length; i++) {
      const batch = batches[i];
      if (batch.length > 0) {
        try {
          console.log(`   Executing batch ${i + 1}/${batches.length}...`);
          await pool.request().query(batch);
        } catch (error) {
          // Skip errors for objects that already exist
          if (!error.message.includes('already exists') && 
              !error.message.includes('There is already an object')) {
            console.warn(`   Warning in batch ${i + 1}: ${error.message}`);
          }
        }
      }
    }
    console.log('✅ Database schema created successfully');

    // Create admin user
    console.log('\n5️⃣ Creating admin user...');
    const adminPassword = process.env.ADMIN_DEFAULT_PASSWORD || 'VMURUGAN_ADMIN_2025';
    const hashedPassword = await bcrypt.hash(adminPassword, 12);

    // Check if admin user exists
    const adminCheckResult = await pool.request()
      .input('phone', sql.NVarChar, '9999999999')
      .query('SELECT user_id FROM users WHERE phone = @phone');

    if (adminCheckResult.recordset.length === 0) {
      // Create admin user
      const adminResult = await pool.request()
        .input('phone', sql.NVarChar, '9999999999')
        .input('email', sql.NVarChar, 'admin@vmurugan.com')
        .input('passwordHash', sql.NVarChar, hashedPassword)
        .input('name', sql.NVarChar, 'VMUrugan Admin')
        .input('role', sql.NVarChar, 'admin')
        .query(`
          INSERT INTO users (phone, email, password_hash, name, role, email_verified, phone_verified)
          OUTPUT INSERTED.user_id
          VALUES (@phone, @email, @passwordHash, @name, @role, 1, 1)
        `);

      const adminUserId = adminResult.recordset[0].user_id;

      // Create admin customer record
      await pool.request()
        .input('customerId', sql.NVarChar, 'VM000000')
        .input('userId', sql.UniqueIdentifier, adminUserId)
        .input('phone', sql.NVarChar, '9999999999')
        .input('name', sql.NVarChar, 'VMUrugan Admin')
        .input('email', sql.NVarChar, 'admin@vmurugan.com')
        .input('address', sql.NVarChar, 'VMUrugan Gold Trading Office')
        .input('panCard', sql.NVarChar, 'ADMIN1234A')
        .input('businessId', sql.NVarChar, process.env.BUSINESS_ID || 'VMURUGAN_001')
        .query(`
          INSERT INTO customers (
            customer_id, user_id, phone, name, email, address, pan_card, business_id
          ) VALUES (
            @customerId, @userId, @phone, @name, @email, @address, @panCard, @businessId
          )
        `);

      console.log('✅ Admin user created successfully');
      console.log(`   📱 Phone: 9999999999`);
      console.log(`   🔑 Password: ${adminPassword}`);
    } else {
      console.log('✅ Admin user already exists');
    }

    // Create test customer
    console.log('\n6️⃣ Creating test customer...');
    const testPassword = 'test123';
    const testHashedPassword = await bcrypt.hash(testPassword, 12);

    const testCheckResult = await pool.request()
      .input('phone', sql.NVarChar, '9876543210')
      .query('SELECT user_id FROM users WHERE phone = @phone');

    if (testCheckResult.recordset.length === 0) {
      // Create test user
      const testResult = await pool.request()
        .input('phone', sql.NVarChar, '9876543210')
        .input('email', sql.NVarChar, 'test@vmurugan.com')
        .input('passwordHash', sql.NVarChar, testHashedPassword)
        .input('name', sql.NVarChar, 'Test Customer')
        .input('role', sql.NVarChar, 'customer')
        .query(`
          INSERT INTO users (phone, email, password_hash, name, role, email_verified, phone_verified)
          OUTPUT INSERTED.user_id
          VALUES (@phone, @email, @passwordHash, @name, @role, 1, 1)
        `);

      const testUserId = testResult.recordset[0].user_id;

      // Generate customer ID
      const counterResult = await pool.request()
        .input('BusinessId', sql.NVarChar, process.env.BUSINESS_ID || 'VMURUGAN_001')
        .output('CustomerId', sql.NVarChar)
        .execute('sp_GenerateCustomerId');

      const customerId = counterResult.output.CustomerId;

      // Create test customer record
      await pool.request()
        .input('customerId', sql.NVarChar, customerId)
        .input('userId', sql.UniqueIdentifier, testUserId)
        .input('phone', sql.NVarChar, '9876543210')
        .input('name', sql.NVarChar, 'Test Customer')
        .input('email', sql.NVarChar, 'test@vmurugan.com')
        .input('address', sql.NVarChar, 'Test Address, Chennai, Tamil Nadu')
        .input('panCard', sql.NVarChar, 'ABCDE1234F')
        .input('businessId', sql.NVarChar, process.env.BUSINESS_ID || 'VMURUGAN_001')
        .query(`
          INSERT INTO customers (
            customer_id, user_id, phone, name, email, address, pan_card, business_id
          ) VALUES (
            @customerId, @userId, @phone, @name, @email, @address, @panCard, @businessId
          )
        `);

      console.log('✅ Test customer created successfully');
      console.log(`   📱 Phone: 9876543210`);
      console.log(`   🔑 Password: ${testPassword}`);
      console.log(`   🆔 Customer ID: ${customerId}`);
    } else {
      console.log('✅ Test customer already exists');
    }

    // Insert sample gold price
    console.log('\n7️⃣ Inserting sample gold price...');
    await pool.request()
      .input('goldType', sql.NVarChar, '22K')
      .input('pricePerGram', sql.Decimal(10, 2), 6500.00)
      .input('source', sql.NVarChar, 'metals.live')
      .input('changeAmount', sql.Decimal(10, 2), 25.00)
      .input('changePercentage', sql.Decimal(5, 2), 0.38)
      .input('trend', sql.NVarChar, 'UP')
      .query(`
        INSERT INTO price_history (gold_type, price_per_gram, source, change_amount, change_percentage, trend)
        VALUES (@goldType, @pricePerGram, @source, @changeAmount, @changePercentage, @trend)
      `);
    console.log('✅ Sample gold price inserted');

    console.log('\n🎉 Database setup completed successfully!');
    console.log('\n📋 Setup Summary:');
    console.log(`   🗄️  Database: ${targetDbConfig.database}`);
    console.log(`   📊 Tables: 9 tables created`);
    console.log(`   👤 Admin User: 9999999999 / ${adminPassword}`);
    console.log(`   🧪 Test User: 9876543210 / ${testPassword}`);
    console.log(`   💰 Sample Gold Price: ₹6,500/gram (22K)`);
    console.log('\n🚀 You can now start the server with: npm run dev');

  } catch (error) {
    console.error('\n❌ Database setup failed:', error);
    console.error('\n🔧 Troubleshooting:');
    console.error('   1. Check SQL Server is running');
    console.error('   2. Verify connection details in .env file');
    console.error('   3. Ensure user has database creation permissions');
    console.error('   4. Check firewall settings');
    process.exit(1);
  } finally {
    if (pool) {
      await pool.close();
    }
  }
}

// Check if .env file exists
const envPath = path.join(__dirname, '.env');
if (!fs.existsSync(envPath)) {
  console.log('⚠️  .env file not found. Creating from .env.example...');
  const examplePath = path.join(__dirname, '.env.example');
  if (fs.existsSync(examplePath)) {
    fs.copyFileSync(examplePath, envPath);
    console.log('✅ .env file created. Please update it with your SQL Server details.');
    console.log('📝 Required settings:');
    console.log('   - DB_SERVER (SQL Server hostname/IP)');
    console.log('   - DB_USER (SQL Server username)');
    console.log('   - DB_PASSWORD (SQL Server password)');
    console.log('   - JWT_SECRET (Random secret key)');
    console.log('\n🔄 Run this script again after updating .env file.');
    process.exit(0);
  } else {
    console.error('❌ .env.example file not found. Please create .env file manually.');
    process.exit(1);
  }
}

// Run setup
setupDatabase();

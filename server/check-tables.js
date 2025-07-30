const sql = require('mssql');
require('dotenv').config();

async function checkTables() {
  try {
    const pool = await sql.connect({
      server: process.env.DB_SERVER || 'localhost',
      database: process.env.DB_NAME || 'VMUruganGoldTrading',
      user: process.env.DB_USER || 'sa',
      password: process.env.DB_PASSWORD,
      options: {
        encrypt: false,
        trustServerCertificate: true
      }
    });

    const tables = await pool.request().query(`
      SELECT TABLE_NAME 
      FROM INFORMATION_SCHEMA.TABLES 
      WHERE TABLE_TYPE = 'BASE TABLE'
    `);
    
    console.log('Database tables:');
    tables.recordset.forEach(t => {
      console.log('  -', t.TABLE_NAME);
    });

    await pool.close();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkTables();

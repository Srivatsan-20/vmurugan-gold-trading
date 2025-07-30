const sql = require('mssql');
require('dotenv').config();

async function checkAnalyticsTable() {
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

    // Check analytics table structure
    const columns = await pool.request().query(`
      SELECT COLUMN_NAME, DATA_TYPE 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_NAME = 'analytics'
    `);
    
    console.log('Analytics table columns:');
    columns.recordset.forEach(c => {
      console.log('  -', c.COLUMN_NAME, c.DATA_TYPE);
    });

    await pool.close();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkAnalyticsTable();

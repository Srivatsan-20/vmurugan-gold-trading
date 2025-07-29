// =====================================================
// VMUrugan Gold Trading - Admin Routes
// =====================================================

const express = require('express');
const sql = require('mssql');
const { body, validationResult, param, query } = require('express-validator');

const router = express.Router();

// =====================================================
// ADMIN DASHBOARD ENDPOINTS
// =====================================================

/**
 * @swagger
 * /api/admin/dashboard:
 *   get:
 *     summary: Get admin dashboard statistics
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard statistics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     totalCustomers:
 *                       type: integer
 *                       example: 150
 *                     totalTransactions:
 *                       type: integer
 *                       example: 1250
 *                     totalGoldSold:
 *                       type: number
 *                       example: 125.5
 *                     totalRevenue:
 *                       type: number
 *                       example: 850000.00
 *                     activeSchemes:
 *                       type: integer
 *                       example: 45
 *                     monthlyStats:
 *                       type: object
 *                       properties:
 *                         newCustomers:
 *                           type: integer
 *                         transactions:
 *                           type: integer
 *                         revenue:
 *                           type: number
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Admin access required
 *       500:
 *         description: Internal server error
 */
// Get dashboard statistics
router.get('/dashboard', async (req, res) => {
  try {
    const pool = req.app.locals.pool;
    const businessId = process.env.BUSINESS_ID || 'VMURUGAN_001';

    // Get business statistics
    const statsResult = await pool.request()
      .input('businessId', sql.NVarChar, businessId)
      .query(`
        SELECT 
          COUNT(DISTINCT c.customer_id) as total_customers,
          COUNT(DISTINCT t.transaction_id) as total_transactions,
          COALESCE(SUM(CASE WHEN t.status = 'SUCCESS' THEN t.amount ELSE 0 END), 0) as total_revenue,
          COALESCE(SUM(CASE WHEN t.status = 'SUCCESS' THEN t.gold_grams ELSE 0 END), 0) as total_gold_sold,
          COUNT(DISTINCT s.scheme_id) as total_schemes,
          COUNT(DISTINCT CASE WHEN s.status = 'active' THEN s.scheme_id END) as active_schemes
        FROM customers c
        LEFT JOIN transactions t ON c.customer_id = t.customer_id AND t.business_id = @businessId
        LEFT JOIN schemes s ON c.customer_id = s.customer_id AND s.business_id = @businessId
        WHERE c.business_id = @businessId
      `);

    // Get recent transactions
    const recentTransactionsResult = await pool.request()
      .input('businessId', sql.NVarChar, businessId)
      .query(`
        SELECT TOP 20 *
        FROM transactions 
        WHERE business_id = @businessId
        ORDER BY timestamp DESC
      `);

    // Get top customers by investment
    const topCustomersResult = await pool.request()
      .input('businessId', sql.NVarChar, businessId)
      .query(`
        SELECT TOP 10 customer_id, name, phone, total_invested, total_gold, transaction_count
        FROM customers 
        WHERE business_id = @businessId
        ORDER BY total_invested DESC
      `);

    // Get monthly revenue trend (last 12 months)
    const monthlyRevenueResult = await pool.request()
      .input('businessId', sql.NVarChar, businessId)
      .query(`
        SELECT 
          FORMAT(timestamp, 'yyyy-MM') as month,
          SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END) as revenue,
          COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) as transactions
        FROM transactions
        WHERE business_id = @businessId
        AND timestamp >= DATEADD(month, -12, GETUTCDATE())
        GROUP BY FORMAT(timestamp, 'yyyy-MM')
        ORDER BY month DESC
      `);

    // Get today's statistics
    const todayStatsResult = await pool.request()
      .input('businessId', sql.NVarChar, businessId)
      .query(`
        SELECT 
          COUNT(DISTINCT customer_id) as new_customers_today,
          COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) as successful_transactions_today,
          COALESCE(SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END), 0) as revenue_today
        FROM transactions
        WHERE business_id = @businessId
        AND CAST(timestamp AS DATE) = CAST(GETUTCDATE() AS DATE)
      `);

    res.json({
      success: true,
      data: {
        stats: {
          ...statsResult.recordset[0],
          ...todayStatsResult.recordset[0]
        },
        recent_transactions: recentTransactionsResult.recordset,
        top_customers: topCustomersResult.recordset,
        monthly_revenue: monthlyRevenueResult.recordset
      }
    });

  } catch (error) {
    console.error('Get dashboard data error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get dashboard data',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get all customers with pagination
router.get('/customers', [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('search').optional().isLength({ min: 1 }).withMessage('Search term must not be empty')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { page = 1, limit = 20, search, sortBy = 'registration_date', sortOrder = 'DESC' } = req.query;
    const pool = req.app.locals.pool;
    const businessId = process.env.BUSINESS_ID || 'VMURUGAN_001';

    let whereClause = 'WHERE c.business_id = @businessId';
    const request = pool.request().input('businessId', sql.NVarChar, businessId);

    if (search) {
      whereClause += ' AND (c.name LIKE @search OR c.phone LIKE @search OR c.email LIKE @search OR c.customer_id LIKE @search)';
      request.input('search', sql.NVarChar, `%${search}%`);
    }

    const offset = (page - 1) * limit;
    request.input('offset', sql.Int, offset);
    request.input('limit', sql.Int, parseInt(limit));

    // Validate sortBy to prevent SQL injection
    const allowedSortFields = ['registration_date', 'name', 'total_invested', 'total_gold', 'transaction_count'];
    const validSortBy = allowedSortFields.includes(sortBy) ? sortBy : 'registration_date';
    const validSortOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const result = await request.query(`
      SELECT c.*, u.email as user_email, u.last_login_at
      FROM customers c
      LEFT JOIN users u ON c.user_id = u.user_id
      ${whereClause}
      ORDER BY c.${validSortBy} ${validSortOrder}
      OFFSET @offset ROWS
      FETCH NEXT @limit ROWS ONLY
    `);

    // Get total count
    const countResult = await pool.request()
      .input('businessId', sql.NVarChar, businessId)
      .query(`SELECT COUNT(*) as total FROM customers c ${whereClause}`);

    res.json({
      success: true,
      data: {
        customers: result.recordset,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: countResult.recordset[0].total,
          pages: Math.ceil(countResult.recordset[0].total / limit)
        }
      }
    });

  } catch (error) {
    console.error('Get customers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get customers',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get all transactions with pagination and filters
router.get('/transactions', [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('status').optional().isIn(['PENDING', 'SUCCESS', 'FAILED', 'CANCELLED']).withMessage('Invalid status'),
  query('type').optional().isIn(['BUY', 'SELL', 'SCHEME_PAYMENT']).withMessage('Invalid type'),
  query('customerId').optional().isLength({ min: 1 }).withMessage('Customer ID must not be empty')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { 
      page = 1, 
      limit = 20, 
      status, 
      type, 
      customerId, 
      startDate, 
      endDate,
      sortBy = 'timestamp',
      sortOrder = 'DESC'
    } = req.query;
    
    const pool = req.app.locals.pool;
    const businessId = process.env.BUSINESS_ID || 'VMURUGAN_001';

    let whereClause = 'WHERE business_id = @businessId';
    const request = pool.request().input('businessId', sql.NVarChar, businessId);

    if (status) {
      whereClause += ' AND status = @status';
      request.input('status', sql.NVarChar, status);
    }

    if (type) {
      whereClause += ' AND type = @type';
      request.input('type', sql.NVarChar, type);
    }

    if (customerId) {
      whereClause += ' AND customer_id = @customerId';
      request.input('customerId', sql.NVarChar, customerId);
    }

    if (startDate) {
      whereClause += ' AND timestamp >= @startDate';
      request.input('startDate', sql.DateTime2, new Date(startDate));
    }

    if (endDate) {
      whereClause += ' AND timestamp <= @endDate';
      request.input('endDate', sql.DateTime2, new Date(endDate));
    }

    const offset = (page - 1) * limit;
    request.input('offset', sql.Int, offset);
    request.input('limit', sql.Int, parseInt(limit));

    // Validate sortBy to prevent SQL injection
    const allowedSortFields = ['timestamp', 'amount', 'gold_grams', 'status', 'type'];
    const validSortBy = allowedSortFields.includes(sortBy) ? sortBy : 'timestamp';
    const validSortOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const result = await request.query(`
      SELECT *
      FROM transactions
      ${whereClause}
      ORDER BY ${validSortBy} ${validSortOrder}
      OFFSET @offset ROWS
      FETCH NEXT @limit ROWS ONLY
    `);

    // Get total count and sum
    const statsResult = await pool.request()
      .input('businessId', sql.NVarChar, businessId)
      .query(`
        SELECT 
          COUNT(*) as total,
          COALESCE(SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END), 0) as total_amount,
          COALESCE(SUM(CASE WHEN status = 'SUCCESS' THEN gold_grams ELSE 0 END), 0) as total_gold
        FROM transactions 
        ${whereClause}
      `);

    res.json({
      success: true,
      data: {
        transactions: result.recordset,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: statsResult.recordset[0].total,
          pages: Math.ceil(statsResult.recordset[0].total / limit)
        },
        summary: {
          total_amount: statsResult.recordset[0].total_amount,
          total_gold: statsResult.recordset[0].total_gold
        }
      }
    });

  } catch (error) {
    console.error('Get transactions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get transactions',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get all schemes with pagination
router.get('/schemes', [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('status').optional().isIn(['active', 'completed', 'cancelled']).withMessage('Invalid status'),
  query('customerId').optional().isLength({ min: 1 }).withMessage('Customer ID must not be empty')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { page = 1, limit = 20, status, customerId } = req.query;
    const pool = req.app.locals.pool;
    const businessId = process.env.BUSINESS_ID || 'VMURUGAN_001';

    let whereClause = 'WHERE business_id = @businessId';
    const request = pool.request().input('businessId', sql.NVarChar, businessId);

    if (status) {
      whereClause += ' AND status = @status';
      request.input('status', sql.NVarChar, status);
    }

    if (customerId) {
      whereClause += ' AND customer_id = @customerId';
      request.input('customerId', sql.NVarChar, customerId);
    }

    const offset = (page - 1) * limit;
    request.input('offset', sql.Int, offset);
    request.input('limit', sql.Int, parseInt(limit));

    const result = await request.query(`
      SELECT *
      FROM schemes
      ${whereClause}
      ORDER BY created_date DESC
      OFFSET @offset ROWS
      FETCH NEXT @limit ROWS ONLY
    `);

    // Get total count
    const countResult = await pool.request()
      .input('businessId', sql.NVarChar, businessId)
      .query(`SELECT COUNT(*) as total FROM schemes ${whereClause}`);

    res.json({
      success: true,
      data: {
        schemes: result.recordset,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: countResult.recordset[0].total,
          pages: Math.ceil(countResult.recordset[0].total / limit)
        }
      }
    });

  } catch (error) {
    console.error('Get schemes error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get schemes',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Export data for backup
router.get('/export', async (req, res) => {
  try {
    const pool = req.app.locals.pool;
    const businessId = process.env.BUSINESS_ID || 'VMURUGAN_001';

    // Get all data
    const [customers, transactions, schemes, analytics] = await Promise.all([
      pool.request()
        .input('businessId', sql.NVarChar, businessId)
        .query('SELECT * FROM customers WHERE business_id = @businessId'),
      
      pool.request()
        .input('businessId', sql.NVarChar, businessId)
        .query('SELECT * FROM transactions WHERE business_id = @businessId'),
      
      pool.request()
        .input('businessId', sql.NVarChar, businessId)
        .query('SELECT * FROM schemes WHERE business_id = @businessId'),
      
      pool.request()
        .input('businessId', sql.NVarChar, businessId)
        .query('SELECT * FROM analytics WHERE business_id = @businessId')
    ]);

    res.json({
      success: true,
      data: {
        customers: customers.recordset,
        transactions: transactions.recordset,
        schemes: schemes.recordset,
        analytics: analytics.recordset,
        export_date: new Date().toISOString(),
        business_id: businessId
      }
    });

  } catch (error) {
    console.error('Export data error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to export data',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;

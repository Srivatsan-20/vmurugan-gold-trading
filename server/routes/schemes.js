// =====================================================
// VMUrugan Gold Trading - Schemes Routes
// =====================================================

const express = require('express');
const sql = require('mssql');
const { body, validationResult, param } = require('express-validator');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();

// =====================================================
// SCHEMES ENDPOINTS
// =====================================================

/**
 * @swagger
 * /api/schemes:
 *   post:
 *     summary: Create a new gold scheme
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - customerId
 *               - schemeType
 *               - monthlyAmount
 *               - durationMonths
 *               - startDate
 *             properties:
 *               customerId:
 *                 type: string
 *                 description: Customer ID
 *                 example: VM000001
 *               schemeType:
 *                 type: string
 *                 description: Type of gold scheme
 *                 example: Monthly Gold Savings
 *               monthlyAmount:
 *                 type: number
 *                 minimum: 100
 *                 description: Monthly payment amount
 *                 example: 5000.00
 *               durationMonths:
 *                 type: integer
 *                 minimum: 6
 *                 maximum: 120
 *                 description: Scheme duration in months
 *                 example: 12
 *               startDate:
 *                 type: string
 *                 format: date
 *                 description: Scheme start date
 *                 example: 2025-08-01
 *     responses:
 *       201:
 *         description: Scheme created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Scheme created successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     schemeId:
 *                       type: string
 *                       example: SCH_1234567890_abcd1234
 *                     customerId:
 *                       type: string
 *                       example: VM000001
 *                     monthlyAmount:
 *                       type: number
 *                       example: 5000.00
 *                     durationMonths:
 *                       type: integer
 *                       example: 12
 *                     status:
 *                       type: string
 *                       example: active
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Internal server error
 */
// Create new scheme
router.post('/', [
  body('customerId').notEmpty().withMessage('Customer ID is required'),
  body('schemeType').notEmpty().withMessage('Scheme type is required'),
  body('monthlyAmount').isFloat({ min: 100 }).withMessage('Monthly amount must be at least ₹100'),
  body('durationMonths').isInt({ min: 6, max: 120 }).withMessage('Duration must be between 6 and 120 months'),
  body('startDate').isISO8601().withMessage('Invalid start date format')
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
      customerId,
      schemeType,
      monthlyAmount,
      durationMonths,
      startDate
    } = req.body;

    const pool = req.app.locals.pool;
    const schemeId = `SCH_${Date.now()}_${uuidv4().substring(0, 8)}`;

    // Get customer details
    const customerResult = await pool.request()
      .input('customerId', sql.NVarChar, customerId)
      .query('SELECT customer_id, phone, name FROM customers WHERE customer_id = @customerId');

    if (customerResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    const customer = customerResult.recordset[0];

    // Calculate end date
    const start = new Date(startDate);
    const end = new Date(start);
    end.setMonth(end.getMonth() + durationMonths);

    // Insert scheme
    await pool.request()
      .input('schemeId', sql.NVarChar, schemeId)
      .input('customerId', sql.NVarChar, customerId)
      .input('customerPhone', sql.NVarChar, customer.phone)
      .input('customerName', sql.NVarChar, customer.name)
      .input('schemeType', sql.NVarChar, schemeType)
      .input('monthlyAmount', sql.Decimal(10, 2), monthlyAmount)
      .input('durationMonths', sql.Int, durationMonths)
      .input('startDate', sql.Date, start)
      .input('endDate', sql.Date, end)
      .input('remainingMonths', sql.Int, durationMonths)
      .input('businessId', sql.NVarChar, process.env.BUSINESS_ID || 'VMURUGAN_001')
      .query(`
        INSERT INTO schemes (
          scheme_id, customer_id, customer_phone, customer_name, scheme_type,
          monthly_amount, duration_months, start_date, end_date, remaining_months,
          business_id
        ) VALUES (
          @schemeId, @customerId, @customerPhone, @customerName, @schemeType,
          @monthlyAmount, @durationMonths, @startDate, @endDate, @remainingMonths,
          @businessId
        )
      `);

    res.status(201).json({
      success: true,
      message: 'Scheme created successfully',
      data: {
        schemeId,
        customerId,
        schemeType,
        monthlyAmount,
        durationMonths,
        startDate: start,
        endDate: end,
        status: 'active'
      }
    });

  } catch (error) {
    console.error('Create scheme error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create scheme',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get customer schemes
router.get('/customer/:customerId', [
  param('customerId').notEmpty().withMessage('Customer ID is required')
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

    const { customerId } = req.params;
    const { status } = req.query;
    const pool = req.app.locals.pool;

    let whereClause = 'WHERE customer_id = @customerId';
    const request = pool.request().input('customerId', sql.NVarChar, customerId);

    if (status) {
      whereClause += ' AND status = @status';
      request.input('status', sql.NVarChar, status);
    }

    const result = await request.query(`
      SELECT *
      FROM schemes
      ${whereClause}
      ORDER BY created_date DESC
    `);

    res.json({
      success: true,
      data: result.recordset
    });

  } catch (error) {
    console.error('Get customer schemes error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get schemes',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Update scheme payment
router.post('/:schemeId/payment', [
  param('schemeId').notEmpty().withMessage('Scheme ID is required'),
  body('amount').isFloat({ min: 0.01 }).withMessage('Amount must be greater than 0'),
  body('goldGrams').isFloat({ min: 0.001 }).withMessage('Gold grams must be greater than 0'),
  body('goldPricePerGram').isFloat({ min: 0.01 }).withMessage('Gold price must be greater than 0'),
  body('paymentMethod').isIn(['UPI', 'CARD', 'NET_BANKING', 'CASH']).withMessage('Invalid payment method')
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

    const { schemeId } = req.params;
    const { amount, goldGrams, goldPricePerGram, paymentMethod, gatewayTransactionId } = req.body;
    const pool = req.app.locals.pool;

    // Get scheme details
    const schemeResult = await pool.request()
      .input('schemeId', sql.NVarChar, schemeId)
      .query('SELECT * FROM schemes WHERE scheme_id = @schemeId AND status = \'active\'');

    if (schemeResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Active scheme not found'
      });
    }

    const scheme = schemeResult.recordset[0];

    // Start transaction
    const transaction = new sql.Transaction(pool);
    await transaction.begin();

    try {
      // Create transaction record
      const transactionId = `TXN_SCH_${Date.now()}_${uuidv4().substring(0, 8)}`;
      
      await transaction.request()
        .input('transactionId', sql.NVarChar, transactionId)
        .input('customerId', sql.NVarChar, scheme.customer_id)
        .input('customerPhone', sql.NVarChar, scheme.customer_phone)
        .input('customerName', sql.NVarChar, scheme.customer_name)
        .input('type', sql.NVarChar, 'SCHEME_PAYMENT')
        .input('amount', sql.Decimal(15, 2), amount)
        .input('goldGrams', sql.Decimal(10, 4), goldGrams)
        .input('goldPricePerGram', sql.Decimal(10, 2), goldPricePerGram)
        .input('paymentMethod', sql.NVarChar, paymentMethod)
        .input('status', sql.NVarChar, 'SUCCESS')
        .input('gatewayTransactionId', sql.NVarChar, gatewayTransactionId || null)
        .input('notes', sql.NVarChar, `Scheme payment for ${schemeId}`)
        .input('businessId', sql.NVarChar, process.env.BUSINESS_ID || 'VMURUGAN_001')
        .input('completedAt', sql.DateTime2, new Date())
        .query(`
          INSERT INTO transactions (
            transaction_id, customer_id, customer_phone, customer_name, type, amount,
            gold_grams, gold_price_per_gram, payment_method, status, gateway_transaction_id,
            notes, business_id, completed_at
          ) VALUES (
            @transactionId, @customerId, @customerPhone, @customerName, @type, @amount,
            @goldGrams, @goldPricePerGram, @paymentMethod, @status, @gatewayTransactionId,
            @notes, @businessId, @completedAt
          )
        `);

      // Update scheme progress
      const newPaidMonths = scheme.paid_months + 1;
      const newRemainingMonths = scheme.remaining_months - 1;
      const newGoldAccumulated = parseFloat(scheme.gold_accumulated) + parseFloat(goldGrams);
      const newTotalPaid = parseFloat(scheme.total_paid) + parseFloat(amount);
      const newStatus = newRemainingMonths <= 0 ? 'completed' : 'active';

      await transaction.request()
        .input('schemeId', sql.NVarChar, schemeId)
        .input('paidMonths', sql.Int, newPaidMonths)
        .input('remainingMonths', sql.Int, newRemainingMonths)
        .input('goldAccumulated', sql.Decimal(10, 4), newGoldAccumulated)
        .input('totalPaid', sql.Decimal(15, 2), newTotalPaid)
        .input('status', sql.NVarChar, newStatus)
        .query(`
          UPDATE schemes 
          SET paid_months = @paidMonths,
              remaining_months = @remainingMonths,
              gold_accumulated = @goldAccumulated,
              total_paid = @totalPaid,
              status = @status,
              updated_at = GETUTCDATE()
          WHERE scheme_id = @schemeId
        `);

      // Update customer stats
      await transaction.request()
        .input('customerId', sql.NVarChar, scheme.customer_id)
        .input('amount', sql.Decimal(15, 2), amount)
        .input('goldGrams', sql.Decimal(10, 4), goldGrams)
        .query(`
          UPDATE customers 
          SET total_invested = total_invested + @amount,
              total_gold = total_gold + @goldGrams,
              transaction_count = transaction_count + 1,
              last_transaction = GETUTCDATE(),
              updated_at = GETUTCDATE()
          WHERE customer_id = @customerId
        `);

      await transaction.commit();

      res.json({
        success: true,
        message: 'Scheme payment processed successfully',
        data: {
          transactionId,
          schemeId,
          amount,
          goldGrams,
          paidMonths: newPaidMonths,
          remainingMonths: newRemainingMonths,
          goldAccumulated: newGoldAccumulated,
          status: newStatus
        }
      });

    } catch (error) {
      await transaction.rollback();
      throw error;
    }

  } catch (error) {
    console.error('Scheme payment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to process scheme payment',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get scheme by ID
router.get('/:schemeId', [
  param('schemeId').notEmpty().withMessage('Scheme ID is required')
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

    const { schemeId } = req.params;
    const pool = req.app.locals.pool;

    const result = await pool.request()
      .input('schemeId', sql.NVarChar, schemeId)
      .query('SELECT * FROM schemes WHERE scheme_id = @schemeId');

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Scheme not found'
      });
    }

    res.json({
      success: true,
      data: result.recordset[0]
    });

  } catch (error) {
    console.error('Get scheme error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get scheme',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Cancel scheme
router.put('/:schemeId/cancel', [
  param('schemeId').notEmpty().withMessage('Scheme ID is required')
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

    const { schemeId } = req.params;
    const { reason } = req.body;
    const pool = req.app.locals.pool;

    const result = await pool.request()
      .input('schemeId', sql.NVarChar, schemeId)
      .input('reason', sql.NVarChar, reason || 'Customer requested cancellation')
      .query(`
        UPDATE schemes 
        SET status = 'cancelled',
            updated_at = GETUTCDATE()
        OUTPUT INSERTED.scheme_id, INSERTED.customer_id, INSERTED.status
        WHERE scheme_id = @schemeId AND status = 'active'
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Active scheme not found'
      });
    }

    res.json({
      success: true,
      message: 'Scheme cancelled successfully',
      data: result.recordset[0]
    });

  } catch (error) {
    console.error('Cancel scheme error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cancel scheme',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;

// =====================================================
// VMUrugan Gold Trading - Transaction Routes
// =====================================================

const express = require('express');
const sql = require('mssql');
const { body, validationResult, param } = require('express-validator');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();

// =====================================================
// TRANSACTION ENDPOINTS
// =====================================================

/**
 * @swagger
 * /api/transactions:
 *   post:
 *     summary: Create a new transaction
 *     tags: [Transactions]
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
 *               - type
 *               - amount
 *               - goldGrams
 *               - goldPricePerGram
 *               - paymentMethod
 *             properties:
 *               customerId:
 *                 type: string
 *                 description: Customer ID
 *                 example: VM000001
 *               type:
 *                 type: string
 *                 enum: [BUY, SELL, SCHEME_PAYMENT]
 *                 description: Transaction type
 *                 example: BUY
 *               amount:
 *                 type: number
 *                 minimum: 0.01
 *                 description: Transaction amount
 *                 example: 10000.00
 *               goldGrams:
 *                 type: number
 *                 minimum: 0.001
 *                 description: Gold quantity in grams
 *                 example: 1.5
 *               goldPricePerGram:
 *                 type: number
 *                 minimum: 0.01
 *                 description: Gold price per gram
 *                 example: 6666.67
 *               paymentMethod:
 *                 type: string
 *                 enum: [UPI, CARD, NET_BANKING, CASH]
 *                 description: Payment method
 *                 example: UPI
 *               gatewayTransactionId:
 *                 type: string
 *                 description: Payment gateway transaction ID
 *                 example: TXN_GATEWAY_123456
 *               notes:
 *                 type: string
 *                 description: Additional notes
 *                 example: Gold purchase for investment
 *     responses:
 *       201:
 *         description: Transaction created successfully
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
 *                   example: Transaction created successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     transactionId:
 *                       type: string
 *                       example: TXN_1234567890_abcd1234
 *                     customerId:
 *                       type: string
 *                       example: VM000001
 *                     type:
 *                       type: string
 *                       example: BUY
 *                     amount:
 *                       type: number
 *                       example: 10000.00
 *                     goldGrams:
 *                       type: number
 *                       example: 1.5
 *                     status:
 *                       type: string
 *                       example: PENDING
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Internal server error
 */
// Create new transaction
router.post('/', [
  body('customerId').notEmpty().withMessage('Customer ID is required'),
  body('type').isIn(['BUY', 'SELL', 'SCHEME_PAYMENT']).withMessage('Invalid transaction type'),
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

    const {
      customerId,
      type,
      amount,
      goldGrams,
      goldPricePerGram,
      paymentMethod,
      gatewayTransactionId,
      gatewayOrderId,
      deviceInfo,
      location,
      notes
    } = req.body;

    const pool = req.app.locals.pool;
    const transactionId = `TXN_${Date.now()}_${uuidv4().substring(0, 8)}`;

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

    // Calculate fees (example: 1% transaction fee + 18% GST)
    const transactionFee = amount * 0.01;
    const gst = transactionFee * 0.18;
    const totalFees = transactionFee + gst;

    // Start transaction
    const transaction = new sql.Transaction(pool);
    await transaction.begin();

    try {
      // Insert transaction
      await transaction.request()
        .input('transactionId', sql.NVarChar, transactionId)
        .input('customerId', sql.NVarChar, customerId)
        .input('customerPhone', sql.NVarChar, customer.phone)
        .input('customerName', sql.NVarChar, customer.name)
        .input('type', sql.NVarChar, type)
        .input('amount', sql.Decimal(15, 2), amount)
        .input('goldGrams', sql.Decimal(10, 4), goldGrams)
        .input('goldPricePerGram', sql.Decimal(10, 2), goldPricePerGram)
        .input('paymentMethod', sql.NVarChar, paymentMethod)
        .input('status', sql.NVarChar, 'PENDING')
        .input('gatewayTransactionId', sql.NVarChar, gatewayTransactionId || null)
        .input('gatewayOrderId', sql.NVarChar, gatewayOrderId || null)
        .input('deviceInfo', sql.NVarChar, deviceInfo || null)
        .input('location', sql.NVarChar, location || null)
        .input('notes', sql.NVarChar, notes || null)
        .input('businessId', sql.NVarChar, process.env.BUSINESS_ID || 'VMURUGAN_001')
        .input('transactionFee', sql.Decimal(10, 2), transactionFee)
        .input('gst', sql.Decimal(10, 2), gst)
        .input('totalFees', sql.Decimal(10, 2), totalFees)
        .query(`
          INSERT INTO transactions (
            transaction_id, customer_id, customer_phone, customer_name, type, amount,
            gold_grams, gold_price_per_gram, payment_method, status, gateway_transaction_id,
            gateway_order_id, device_info, location, notes, business_id,
            transaction_fee, gst, total_fees
          ) VALUES (
            @transactionId, @customerId, @customerPhone, @customerName, @type, @amount,
            @goldGrams, @goldPricePerGram, @paymentMethod, @status, @gatewayTransactionId,
            @gatewayOrderId, @deviceInfo, @location, @notes, @businessId,
            @transactionFee, @gst, @totalFees
          )
        `);

      await transaction.commit();

      res.status(201).json({
        success: true,
        message: 'Transaction created successfully',
        data: {
          transactionId,
          customerId,
          type,
          amount,
          goldGrams,
          status: 'PENDING',
          fees: {
            transactionFee,
            gst,
            totalFees
          }
        }
      });

    } catch (error) {
      await transaction.rollback();
      throw error;
    }

  } catch (error) {
    console.error('Create transaction error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create transaction',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Update transaction status
router.put('/:transactionId/status', [
  param('transactionId').notEmpty().withMessage('Transaction ID is required'),
  body('status').isIn(['PENDING', 'SUCCESS', 'FAILED', 'CANCELLED']).withMessage('Invalid status')
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

    const { transactionId } = req.params;
    const { status, gatewayTransactionId } = req.body;
    const pool = req.app.locals.pool;

    // Start transaction
    const transaction = new sql.Transaction(pool);
    await transaction.begin();

    try {
      // Update transaction status
      const updateResult = await transaction.request()
        .input('transactionId', sql.NVarChar, transactionId)
        .input('status', sql.NVarChar, status)
        .input('gatewayTransactionId', sql.NVarChar, gatewayTransactionId || null)
        .input('completedAt', sql.DateTime2, status === 'SUCCESS' ? new Date() : null)
        .query(`
          UPDATE transactions 
          SET status = @status,
              gateway_transaction_id = COALESCE(@gatewayTransactionId, gateway_transaction_id),
              completed_at = @completedAt,
              updated_at = GETUTCDATE()
          OUTPUT INSERTED.customer_id, INSERTED.type, INSERTED.amount, INSERTED.gold_grams
          WHERE transaction_id = @transactionId
        `);

      if (updateResult.recordset.length === 0) {
        await transaction.rollback();
        return res.status(404).json({
          success: false,
          message: 'Transaction not found'
        });
      }

      const updatedTransaction = updateResult.recordset[0];

      // If transaction is successful and it's a BUY, update customer stats
      if (status === 'SUCCESS' && updatedTransaction.type === 'BUY') {
        await transaction.request()
          .input('customerId', sql.NVarChar, updatedTransaction.customer_id)
          .input('amount', sql.Decimal(15, 2), updatedTransaction.amount)
          .input('goldGrams', sql.Decimal(10, 4), updatedTransaction.gold_grams)
          .query(`
            UPDATE customers 
            SET total_invested = total_invested + @amount,
                total_gold = total_gold + @goldGrams,
                transaction_count = transaction_count + 1,
                last_transaction = GETUTCDATE(),
                updated_at = GETUTCDATE()
            WHERE customer_id = @customerId
          `);
      }

      await transaction.commit();

      res.json({
        success: true,
        message: 'Transaction status updated successfully',
        data: {
          transactionId,
          status,
          completedAt: status === 'SUCCESS' ? new Date() : null
        }
      });

    } catch (error) {
      await transaction.rollback();
      throw error;
    }

  } catch (error) {
    console.error('Update transaction status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update transaction status',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @swagger
 * /api/transactions/customer/{customerId}:
 *   get:
 *     summary: Get customer transactions
 *     tags: [Transactions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: customerId
 *         required: true
 *         schema:
 *           type: string
 *         description: Customer ID
 *         example: VM000001
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 10
 *         description: Number of transactions per page
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [PENDING, SUCCESS, FAILED, CANCELLED]
 *         description: Filter by transaction status
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [BUY, SELL, SCHEME_PAYMENT]
 *         description: Filter by transaction type
 *     responses:
 *       200:
 *         description: Customer transactions retrieved successfully
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
 *                     transactions:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           transaction_id:
 *                             type: string
 *                           type:
 *                             type: string
 *                           amount:
 *                             type: number
 *                           gold_grams:
 *                             type: number
 *                           status:
 *                             type: string
 *                           created_at:
 *                             type: string
 *                             format: date-time
 *                     pagination:
 *                       type: object
 *                       properties:
 *                         page:
 *                           type: integer
 *                         limit:
 *                           type: integer
 *                         total:
 *                           type: integer
 *                         pages:
 *                           type: integer
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Customer not found
 */
// Get customer transactions
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
    const { page = 1, limit = 20, status, type } = req.query;
    const pool = req.app.locals.pool;

    let whereClause = 'WHERE customer_id = @customerId';
    const request = pool.request().input('customerId', sql.NVarChar, customerId);

    if (status) {
      whereClause += ' AND status = @status';
      request.input('status', sql.NVarChar, status);
    }

    if (type) {
      whereClause += ' AND type = @type';
      request.input('type', sql.NVarChar, type);
    }

    const offset = (page - 1) * limit;
    request.input('offset', sql.Int, offset);
    request.input('limit', sql.Int, parseInt(limit));

    const result = await request.query(`
      SELECT *
      FROM transactions
      ${whereClause}
      ORDER BY timestamp DESC
      OFFSET @offset ROWS
      FETCH NEXT @limit ROWS ONLY
    `);

    // Get total count
    const countResult = await pool.request()
      .input('customerId', sql.NVarChar, customerId)
      .query(`SELECT COUNT(*) as total FROM transactions WHERE customer_id = @customerId`);

    res.json({
      success: true,
      data: {
        transactions: result.recordset,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: countResult.recordset[0].total,
          pages: Math.ceil(countResult.recordset[0].total / limit)
        }
      }
    });

  } catch (error) {
    console.error('Get customer transactions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get transactions',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get transaction by ID
router.get('/:transactionId', [
  param('transactionId').notEmpty().withMessage('Transaction ID is required')
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

    const { transactionId } = req.params;
    const pool = req.app.locals.pool;

    const result = await pool.request()
      .input('transactionId', sql.NVarChar, transactionId)
      .query('SELECT * FROM transactions WHERE transaction_id = @transactionId');

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }

    res.json({
      success: true,
      data: result.recordset[0]
    });

  } catch (error) {
    console.error('Get transaction error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get transaction',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;

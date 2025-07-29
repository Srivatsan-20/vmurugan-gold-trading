// =====================================================
// VMUrugan Gold Trading - Transaction Tests
// =====================================================

const request = require('supertest');
const app = require('../server-sqlserver');

describe('Transaction Endpoints', () => {
  let authToken;
  let customerId;
  let testTransactionId;

  const testUser = {
    phone: '9876543998',
    email: 'test.transaction@vmurugan.com',
    password: 'testpass123',
    name: 'Test Transaction User',
    address: 'Test Address, Chennai, Tamil Nadu',
    panCard: 'ABCDE9998F'
  };

  const testTransaction = {
    type: 'BUY',
    amount: 10000.00,
    goldGrams: 1.5,
    goldPricePerGram: 6666.67,
    paymentMethod: 'UPI',
    gatewayTransactionId: 'TEST_TXN_123456',
    deviceInfo: 'Test Device',
    location: 'Chennai, Tamil Nadu',
    notes: 'Test transaction'
  };

  beforeAll(async () => {
    // Register and login test user
    const registerResponse = await request(app)
      .post('/api/auth/register')
      .send(testUser);

    customerId = registerResponse.body.data.customerId;
    authToken = registerResponse.body.data.accessToken;
  });

  describe('POST /api/transactions', () => {
    it('should create a new transaction successfully', async () => {
      const response = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testTransaction,
          customerId
        })
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('transactionId');
      expect(response.body.data.customerId).toBe(customerId);
      expect(response.body.data.type).toBe(testTransaction.type);
      expect(response.body.data.amount).toBe(testTransaction.amount);
      expect(response.body.data.status).toBe('PENDING');

      testTransactionId = response.body.data.transactionId;
    });

    it('should reject transaction without authentication', async () => {
      const response = await request(app)
        .post('/api/transactions')
        .send({
          ...testTransaction,
          customerId
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });

    it('should reject transaction with invalid customer ID', async () => {
      const response = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testTransaction,
          customerId: 'INVALID_ID'
        })
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Customer not found');
    });

    it('should reject transaction with invalid amount', async () => {
      const response = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testTransaction,
          customerId,
          amount: -100
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject transaction with invalid gold grams', async () => {
      const response = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testTransaction,
          customerId,
          goldGrams: 0
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject transaction with invalid payment method', async () => {
      const response = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testTransaction,
          customerId,
          paymentMethod: 'INVALID_METHOD'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject transaction with invalid type', async () => {
      const response = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testTransaction,
          customerId,
          type: 'INVALID_TYPE'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });
  });

  describe('PUT /api/transactions/:transactionId/status', () => {
    it('should update transaction status to SUCCESS', async () => {
      const response = await request(app)
        .put(`/api/transactions/${testTransactionId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'SUCCESS',
          gatewayTransactionId: 'GATEWAY_SUCCESS_123'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('SUCCESS');
      expect(response.body.data.transactionId).toBe(testTransactionId);
    });

    it('should update transaction status to FAILED', async () => {
      // Create another transaction for testing FAILED status
      const createResponse = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testTransaction,
          customerId,
          amount: 5000
        });

      const failedTransactionId = createResponse.body.data.transactionId;

      const response = await request(app)
        .put(`/api/transactions/${failedTransactionId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'FAILED'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('FAILED');
    });

    it('should reject status update with invalid transaction ID', async () => {
      const response = await request(app)
        .put('/api/transactions/INVALID_ID/status')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'SUCCESS'
        })
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('not found');
    });

    it('should reject status update with invalid status', async () => {
      const response = await request(app)
        .put(`/api/transactions/${testTransactionId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'INVALID_STATUS'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject status update without authentication', async () => {
      const response = await request(app)
        .put(`/api/transactions/${testTransactionId}/status`)
        .send({
          status: 'SUCCESS'
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  describe('GET /api/transactions/customer/:customerId', () => {
    it('should get customer transactions', async () => {
      const response = await request(app)
        .get(`/api/transactions/customer/${customerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('transactions');
      expect(response.body.data).toHaveProperty('pagination');
      expect(Array.isArray(response.body.data.transactions)).toBe(true);
      expect(response.body.data.transactions.length).toBeGreaterThan(0);
    });

    it('should get customer transactions with pagination', async () => {
      const response = await request(app)
        .get(`/api/transactions/customer/${customerId}?page=1&limit=5`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.pagination.page).toBe(1);
      expect(response.body.data.pagination.limit).toBe(5);
    });

    it('should filter transactions by status', async () => {
      const response = await request(app)
        .get(`/api/transactions/customer/${customerId}?status=SUCCESS`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.transactions.forEach(transaction => {
        expect(transaction.status).toBe('SUCCESS');
      });
    });

    it('should filter transactions by type', async () => {
      const response = await request(app)
        .get(`/api/transactions/customer/${customerId}?type=BUY`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.transactions.forEach(transaction => {
        expect(transaction.type).toBe('BUY');
      });
    });

    it('should reject request with invalid customer ID', async () => {
      const response = await request(app)
        .get('/api/transactions/customer/INVALID_ID')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject request without authentication', async () => {
      const response = await request(app)
        .get(`/api/transactions/customer/${customerId}`)
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  describe('GET /api/transactions/:transactionId', () => {
    it('should get transaction by ID', async () => {
      const response = await request(app)
        .get(`/api/transactions/${testTransactionId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.transaction_id).toBe(testTransactionId);
      expect(response.body.data).toHaveProperty('customer_id');
      expect(response.body.data).toHaveProperty('type');
      expect(response.body.data).toHaveProperty('amount');
      expect(response.body.data).toHaveProperty('status');
    });

    it('should return 404 for non-existing transaction', async () => {
      const response = await request(app)
        .get('/api/transactions/NON_EXISTING_ID')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('not found');
    });

    it('should reject request without authentication', async () => {
      const response = await request(app)
        .get(`/api/transactions/${testTransactionId}`)
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  // Test customer stats update after successful transaction
  describe('Customer Stats Update', () => {
    it('should update customer stats after successful BUY transaction', async () => {
      // Get customer profile before
      const beforeResponse = await request(app)
        .get('/api/customers/profile')
        .set('Authorization', `Bearer ${authToken}`);

      const beforeStats = beforeResponse.body.data;

      // Create and complete a BUY transaction
      const createResponse = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testTransaction,
          customerId,
          amount: 1000,
          goldGrams: 0.15
        });

      const newTransactionId = createResponse.body.data.transactionId;

      await request(app)
        .put(`/api/transactions/${newTransactionId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ status: 'SUCCESS' });

      // Get customer profile after
      const afterResponse = await request(app)
        .get('/api/customers/profile')
        .set('Authorization', `Bearer ${authToken}`);

      const afterStats = afterResponse.body.data;

      // Verify stats were updated
      expect(afterStats.total_invested).toBeGreaterThan(beforeStats.total_invested);
      expect(afterStats.total_gold).toBeGreaterThan(beforeStats.total_gold);
      expect(afterStats.transaction_count).toBeGreaterThan(beforeStats.transaction_count);
    });
  });

  afterAll(async () => {
    console.log('Transaction tests completed');
  });
});

// =====================================================
// VMUrugan Gold Trading - Customer Tests
// =====================================================

const request = require('supertest');
const app = require('../server-sqlserver');

describe('Customer Endpoints', () => {
  let authToken;
  let customerId;
  let userId;

  const testUser = {
    phone: '9876543995',
    email: 'test.customer@vmurugan.com',
    password: 'testpass123',
    name: 'Test Customer User',
    address: 'Test Address, Chennai, Tamil Nadu',
    panCard: 'ABCDE9995F'
  };

  beforeAll(async () => {
    // Register and login test user
    const registerResponse = await request(app)
      .post('/api/auth/register')
      .send(testUser);

    customerId = registerResponse.body.data.customerId;
    userId = registerResponse.body.data.userId;
    authToken = registerResponse.body.data.accessToken;
  });

  describe('GET /api/customers/profile', () => {
    it('should get customer profile with valid token', async () => {
      const response = await request(app)
        .get('/api/customers/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('customer_id');
      expect(response.body.data).toHaveProperty('user_id');
      expect(response.body.data).toHaveProperty('phone');
      expect(response.body.data).toHaveProperty('name');
      expect(response.body.data).toHaveProperty('email');
      expect(response.body.data).toHaveProperty('address');
      expect(response.body.data).toHaveProperty('pan_card');
      expect(response.body.data).toHaveProperty('total_invested');
      expect(response.body.data).toHaveProperty('total_gold');
      expect(response.body.data).toHaveProperty('transaction_count');
      expect(response.body.data).toHaveProperty('registration_date');

      expect(response.body.data.customer_id).toBe(customerId);
      expect(response.body.data.phone).toBe(testUser.phone);
      expect(response.body.data.name).toBe(testUser.name);
      expect(response.body.data.email).toBe(testUser.email);
    });

    it('should reject profile request without token', async () => {
      const response = await request(app)
        .get('/api/customers/profile')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });

    it('should reject profile request with invalid token', async () => {
      const response = await request(app)
        .get('/api/customers/profile')
        .set('Authorization', 'Bearer invalid-token')
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid token');
    });
  });

  describe('GET /api/customers/validate/:phone', () => {
    it('should validate existing customer', async () => {
      const response = await request(app)
        .get(`/api/customers/validate/${testUser.phone}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('customer_id');
      expect(response.body.data).toHaveProperty('name');
      expect(response.body.data).toHaveProperty('phone');
      expect(response.body.data).toHaveProperty('email');
      expect(response.body.data).toHaveProperty('total_invested');
      expect(response.body.data).toHaveProperty('total_gold');

      expect(response.body.data.phone).toBe(testUser.phone);
      expect(response.body.data.customer_id).toBe(customerId);
    });

    it('should return 404 for non-existing customer', async () => {
      const response = await request(app)
        .get('/api/customers/validate/9999999998')
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('not found');
    });

    it('should reject invalid phone format', async () => {
      const response = await request(app)
        .get('/api/customers/validate/123')
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject phone with invalid characters', async () => {
      const response = await request(app)
        .get('/api/customers/validate/98765abcde')
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject phone starting with invalid digit', async () => {
      const response = await request(app)
        .get('/api/customers/validate/1234567890')
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });
  });

  describe('PUT /api/customers/profile', () => {
    it('should update customer profile', async () => {
      const updateData = {
        name: 'Updated Test Customer',
        email: 'updated.test@vmurugan.com',
        address: 'Updated Address, Chennai, Tamil Nadu'
      };

      const response = await request(app)
        .put('/api/customers/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(updateData.name);
      expect(response.body.data.email).toBe(updateData.email);
      expect(response.body.data.address).toBe(updateData.address);
    });

    it('should reject update with invalid email', async () => {
      const response = await request(app)
        .put('/api/customers/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          email: 'invalid-email'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject update with short name', async () => {
      const response = await request(app)
        .put('/api/customers/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'A'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject update without authentication', async () => {
      const response = await request(app)
        .put('/api/customers/profile')
        .send({
          name: 'Updated Name'
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  describe('GET /api/customers/portfolio', () => {
    beforeAll(async () => {
      // Create some transactions to build portfolio
      await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          customerId: customerId,
          type: 'BUY',
          amount: 10000.00,
          goldGrams: 1.5,
          goldPricePerGram: 6666.67,
          paymentMethod: 'UPI'
        });

      // Update transaction to SUCCESS to affect portfolio
      const transactionsResponse = await request(app)
        .get(`/api/transactions/customer/${customerId}`)
        .set('Authorization', `Bearer ${authToken}`);

      if (transactionsResponse.body.data.transactions.length > 0) {
        const transactionId = transactionsResponse.body.data.transactions[0].transaction_id;
        await request(app)
          .put(`/api/transactions/${transactionId}/status`)
          .set('Authorization', `Bearer ${authToken}`)
          .send({ status: 'SUCCESS' });
      }
    });

    it('should get customer portfolio', async () => {
      const response = await request(app)
        .get('/api/customers/portfolio')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('customer_id');
      expect(response.body.data).toHaveProperty('total_invested');
      expect(response.body.data).toHaveProperty('total_gold');
      expect(response.body.data).toHaveProperty('current_value');
      expect(response.body.data).toHaveProperty('profit_loss');
      expect(response.body.data).toHaveProperty('profit_loss_percentage');
      expect(response.body.data).toHaveProperty('transactions_summary');
      expect(response.body.data).toHaveProperty('schemes_summary');

      expect(typeof response.body.data.total_invested).toBe('number');
      expect(typeof response.body.data.total_gold).toBe('number');
      expect(typeof response.body.data.current_value).toBe('number');
    });

    it('should reject portfolio request without authentication', async () => {
      const response = await request(app)
        .get('/api/customers/portfolio')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  describe('GET /api/customers/statements', () => {
    it('should get customer statements', async () => {
      const response = await request(app)
        .get('/api/customers/statements')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('customer_info');
      expect(response.body.data).toHaveProperty('transactions');
      expect(response.body.data).toHaveProperty('schemes');
      expect(response.body.data).toHaveProperty('summary');
      expect(response.body.data).toHaveProperty('statement_date');

      expect(Array.isArray(response.body.data.transactions)).toBe(true);
      expect(Array.isArray(response.body.data.schemes)).toBe(true);
    });

    it('should filter statements by date range', async () => {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - 30);
      const endDate = new Date();

      const response = await request(app)
        .get(`/api/customers/statements?startDate=${startDate.toISOString()}&endDate=${endDate.toISOString()}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('transactions');
      expect(response.body.data).toHaveProperty('date_range');
    });

    it('should reject statements request without authentication', async () => {
      const response = await request(app)
        .get('/api/customers/statements')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  describe('POST /api/customers/kyc', () => {
    it('should update KYC information', async () => {
      const kycData = {
        panCard: 'ABCDE9995F',
        aadharCard: '123456789012',
        bankAccount: '1234567890',
        ifscCode: 'SBIN0001234',
        bankName: 'State Bank of India'
      };

      const response = await request(app)
        .post('/api/customers/kyc')
        .set('Authorization', `Bearer ${authToken}`)
        .send(kycData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('kyc_status');
      expect(response.body.data.kyc_status).toBe('verified');
    });

    it('should reject invalid PAN card format', async () => {
      const response = await request(app)
        .post('/api/customers/kyc')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          panCard: 'INVALID_PAN'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject invalid Aadhar card format', async () => {
      const response = await request(app)
        .post('/api/customers/kyc')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          aadharCard: '123'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject KYC update without authentication', async () => {
      const response = await request(app)
        .post('/api/customers/kyc')
        .send({
          panCard: 'ABCDE1234F'
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  afterAll(async () => {
    console.log('Customer tests completed');
  });
});

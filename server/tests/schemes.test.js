// =====================================================
// VMUrugan Gold Trading - Schemes Tests
// =====================================================

const request = require('supertest');
const app = require('../server-sqlserver');

describe('Scheme Endpoints', () => {
  let authToken;
  let customerId;
  let testSchemeId;

  const testUser = {
    phone: '9876543997',
    email: 'test.scheme@vmurugan.com',
    password: 'testpass123',
    name: 'Test Scheme User',
    address: 'Test Address, Chennai, Tamil Nadu',
    panCard: 'ABCDE9997F'
  };

  const testScheme = {
    schemeType: 'monthly_sip',
    monthlyAmount: 5000.00,
    durationMonths: 12,
    startDate: '2025-08-01T00:00:00.000Z'
  };

  beforeAll(async () => {
    // Register and login test user
    const registerResponse = await request(app)
      .post('/api/auth/register')
      .send(testUser);

    customerId = registerResponse.body.data.customerId;
    authToken = registerResponse.body.data.accessToken;
  });

  describe('POST /api/schemes', () => {
    it('should create a new scheme successfully', async () => {
      const response = await request(app)
        .post('/api/schemes')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testScheme,
          customerId
        })
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('schemeId');
      expect(response.body.data.customerId).toBe(customerId);
      expect(response.body.data.schemeType).toBe(testScheme.schemeType);
      expect(response.body.data.monthlyAmount).toBe(testScheme.monthlyAmount);
      expect(response.body.data.durationMonths).toBe(testScheme.durationMonths);
      expect(response.body.data.status).toBe('active');

      testSchemeId = response.body.data.schemeId;
    });

    it('should reject scheme creation without authentication', async () => {
      const response = await request(app)
        .post('/api/schemes')
        .send({
          ...testScheme,
          customerId
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });

    it('should reject scheme with invalid customer ID', async () => {
      const response = await request(app)
        .post('/api/schemes')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testScheme,
          customerId: 'INVALID_ID'
        })
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Customer not found');
    });

    it('should reject scheme with invalid monthly amount', async () => {
      const response = await request(app)
        .post('/api/schemes')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testScheme,
          customerId,
          monthlyAmount: 50 // Below minimum of 100
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject scheme with invalid duration', async () => {
      const response = await request(app)
        .post('/api/schemes')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testScheme,
          customerId,
          durationMonths: 3 // Below minimum of 6
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject scheme with invalid start date', async () => {
      const response = await request(app)
        .post('/api/schemes')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testScheme,
          customerId,
          startDate: 'invalid-date'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });
  });

  describe('GET /api/schemes/customer/:customerId', () => {
    it('should get customer schemes', async () => {
      const response = await request(app)
        .get(`/api/schemes/customer/${customerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
      
      const scheme = response.body.data[0];
      expect(scheme).toHaveProperty('scheme_id');
      expect(scheme).toHaveProperty('customer_id');
      expect(scheme).toHaveProperty('scheme_type');
      expect(scheme).toHaveProperty('monthly_amount');
      expect(scheme).toHaveProperty('status');
    });

    it('should filter schemes by status', async () => {
      const response = await request(app)
        .get(`/api/schemes/customer/${customerId}?status=active`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.forEach(scheme => {
        expect(scheme.status).toBe('active');
      });
    });

    it('should reject request with invalid customer ID', async () => {
      const response = await request(app)
        .get('/api/schemes/customer/INVALID_ID')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject request without authentication', async () => {
      const response = await request(app)
        .get(`/api/schemes/customer/${customerId}`)
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  describe('POST /api/schemes/:schemeId/payment', () => {
    it('should process scheme payment successfully', async () => {
      const paymentData = {
        amount: 5000.00,
        goldGrams: 0.75,
        goldPricePerGram: 6666.67,
        paymentMethod: 'UPI',
        gatewayTransactionId: 'SCHEME_TEST_123'
      };

      const response = await request(app)
        .post(`/api/schemes/${testSchemeId}/payment`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(paymentData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('transactionId');
      expect(response.body.data).toHaveProperty('schemeId');
      expect(response.body.data.amount).toBe(paymentData.amount);
      expect(response.body.data.goldGrams).toBe(paymentData.goldGrams);
      expect(response.body.data.paidMonths).toBe(1);
      expect(response.body.data.remainingMonths).toBe(11);
    });

    it('should reject payment with invalid scheme ID', async () => {
      const response = await request(app)
        .post('/api/schemes/INVALID_ID/payment')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 5000.00,
          goldGrams: 0.75,
          goldPricePerGram: 6666.67,
          paymentMethod: 'UPI'
        })
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('not found');
    });

    it('should reject payment with invalid amount', async () => {
      const response = await request(app)
        .post(`/api/schemes/${testSchemeId}/payment`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 0,
          goldGrams: 0.75,
          goldPricePerGram: 6666.67,
          paymentMethod: 'UPI'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject payment with invalid payment method', async () => {
      const response = await request(app)
        .post(`/api/schemes/${testSchemeId}/payment`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 5000.00,
          goldGrams: 0.75,
          goldPricePerGram: 6666.67,
          paymentMethod: 'INVALID_METHOD'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject payment without authentication', async () => {
      const response = await request(app)
        .post(`/api/schemes/${testSchemeId}/payment`)
        .send({
          amount: 5000.00,
          goldGrams: 0.75,
          goldPricePerGram: 6666.67,
          paymentMethod: 'UPI'
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  describe('GET /api/schemes/:schemeId', () => {
    it('should get scheme by ID', async () => {
      const response = await request(app)
        .get(`/api/schemes/${testSchemeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.scheme_id).toBe(testSchemeId);
      expect(response.body.data).toHaveProperty('customer_id');
      expect(response.body.data).toHaveProperty('scheme_type');
      expect(response.body.data).toHaveProperty('monthly_amount');
      expect(response.body.data).toHaveProperty('status');
    });

    it('should return 404 for non-existing scheme', async () => {
      const response = await request(app)
        .get('/api/schemes/NON_EXISTING_ID')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('not found');
    });

    it('should reject request without authentication', async () => {
      const response = await request(app)
        .get(`/api/schemes/${testSchemeId}`)
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  describe('PUT /api/schemes/:schemeId/cancel', () => {
    let cancelSchemeId;

    beforeAll(async () => {
      // Create a scheme to cancel
      const response = await request(app)
        .post('/api/schemes')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          ...testScheme,
          customerId,
          monthlyAmount: 3000
        });
      cancelSchemeId = response.body.data.schemeId;
    });

    it('should cancel scheme successfully', async () => {
      const response = await request(app)
        .put(`/api/schemes/${cancelSchemeId}/cancel`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          reason: 'Customer requested cancellation'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('cancelled');
      expect(response.body.data.scheme_id).toBe(cancelSchemeId);
    });

    it('should reject cancellation of non-existing scheme', async () => {
      const response = await request(app)
        .put('/api/schemes/NON_EXISTING_ID/cancel')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          reason: 'Test cancellation'
        })
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('not found');
    });

    it('should reject cancellation without authentication', async () => {
      const response = await request(app)
        .put(`/api/schemes/${testSchemeId}/cancel`)
        .send({
          reason: 'Test cancellation'
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  afterAll(async () => {
    console.log('Scheme tests completed');
  });
});

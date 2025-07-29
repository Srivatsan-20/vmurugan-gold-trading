// =====================================================
// VMUrugan Gold Trading - Admin Tests
// =====================================================

const request = require('supertest');
const app = require('../server-sqlserver');

describe('Admin Endpoints', () => {
  let adminToken;
  let customerToken;
  let customerId;

  const testCustomer = {
    phone: '9876543996',
    email: 'test.admin@vmurugan.com',
    password: 'testpass123',
    name: 'Test Admin Customer',
    address: 'Test Address, Chennai, Tamil Nadu',
    panCard: 'ABCDE9996F'
  };

  beforeAll(async () => {
    // Login as admin
    const adminResponse = await request(app)
      .post('/api/auth/login')
      .send({
        phone: '9999999999',
        password: process.env.ADMIN_DEFAULT_PASSWORD || 'VMURUGAN_ADMIN_2025'
      });

    adminToken = adminResponse.body.data.accessToken;

    // Create a test customer for admin operations
    const customerResponse = await request(app)
      .post('/api/auth/register')
      .send(testCustomer);

    customerId = customerResponse.body.data.customerId;
    customerToken = customerResponse.body.data.accessToken;
  });

  describe('GET /api/admin/dashboard', () => {
    it('should get admin dashboard data with admin token', async () => {
      const response = await request(app)
        .get('/api/admin/dashboard')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('stats');
      
      const stats = response.body.data.stats;
      expect(stats).toHaveProperty('total_customers');
      expect(stats).toHaveProperty('total_transactions');
      expect(stats).toHaveProperty('total_revenue');
      expect(stats).toHaveProperty('total_gold_sold');
      expect(stats).toHaveProperty('active_schemes');
      expect(stats).toHaveProperty('revenue_today');

      expect(typeof stats.total_customers).toBe('number');
      expect(typeof stats.total_transactions).toBe('number');
      expect(typeof stats.total_revenue).toBe('number');
    });

    it('should reject dashboard access with customer token', async () => {
      const response = await request(app)
        .get('/api/admin/dashboard')
        .set('Authorization', `Bearer ${customerToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Admin access required');
    });

    it('should reject dashboard access without token', async () => {
      const response = await request(app)
        .get('/api/admin/dashboard')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  describe('GET /api/admin/customers', () => {
    it('should get all customers with pagination', async () => {
      const response = await request(app)
        .get('/api/admin/customers?page=1&limit=10')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('customers');
      expect(response.body.data).toHaveProperty('pagination');
      
      expect(Array.isArray(response.body.data.customers)).toBe(true);
      expect(response.body.data.pagination).toHaveProperty('page');
      expect(response.body.data.pagination).toHaveProperty('limit');
      expect(response.body.data.pagination).toHaveProperty('total');
      expect(response.body.data.pagination).toHaveProperty('pages');

      if (response.body.data.customers.length > 0) {
        const customer = response.body.data.customers[0];
        expect(customer).toHaveProperty('customer_id');
        expect(customer).toHaveProperty('name');
        expect(customer).toHaveProperty('phone');
        expect(customer).toHaveProperty('email');
        expect(customer).toHaveProperty('total_invested');
        expect(customer).toHaveProperty('total_gold');
        expect(customer).toHaveProperty('transaction_count');
      }
    });

    it('should search customers by name/phone', async () => {
      const response = await request(app)
        .get(`/api/admin/customers?search=${testCustomer.name}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data.customers)).toBe(true);
    });

    it('should sort customers by different fields', async () => {
      const response = await request(app)
        .get('/api/admin/customers?sortBy=total_invested&sortOrder=DESC')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data.customers)).toBe(true);
    });

    it('should validate pagination parameters', async () => {
      const response = await request(app)
        .get('/api/admin/customers?page=0&limit=200')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject customer access with customer token', async () => {
      const response = await request(app)
        .get('/api/admin/customers')
        .set('Authorization', `Bearer ${customerToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Admin access required');
    });
  });

  describe('GET /api/admin/transactions', () => {
    beforeAll(async () => {
      // Create a test transaction for admin to view
      await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          customerId: customerId,
          type: 'BUY',
          amount: 5000.00,
          goldGrams: 0.75,
          goldPricePerGram: 6666.67,
          paymentMethod: 'UPI',
          notes: 'Admin test transaction'
        });
    });

    it('should get all transactions with pagination', async () => {
      const response = await request(app)
        .get('/api/admin/transactions?page=1&limit=10')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('transactions');
      expect(response.body.data).toHaveProperty('pagination');
      expect(response.body.data).toHaveProperty('summary');
      
      expect(Array.isArray(response.body.data.transactions)).toBe(true);
      expect(response.body.data.summary).toHaveProperty('total_amount');
      expect(response.body.data.summary).toHaveProperty('total_gold');

      if (response.body.data.transactions.length > 0) {
        const transaction = response.body.data.transactions[0];
        expect(transaction).toHaveProperty('transaction_id');
        expect(transaction).toHaveProperty('customer_id');
        expect(transaction).toHaveProperty('type');
        expect(transaction).toHaveProperty('amount');
        expect(transaction).toHaveProperty('status');
      }
    });

    it('should filter transactions by status', async () => {
      const response = await request(app)
        .get('/api/admin/transactions?status=PENDING')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.transactions.forEach(transaction => {
        expect(transaction.status).toBe('PENDING');
      });
    });

    it('should filter transactions by type', async () => {
      const response = await request(app)
        .get('/api/admin/transactions?type=BUY')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.transactions.forEach(transaction => {
        expect(transaction.type).toBe('BUY');
      });
    });

    it('should filter transactions by customer ID', async () => {
      const response = await request(app)
        .get(`/api/admin/transactions?customerId=${customerId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.transactions.forEach(transaction => {
        expect(transaction.customer_id).toBe(customerId);
      });
    });

    it('should filter transactions by date range', async () => {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - 1);
      const endDate = new Date();
      endDate.setDate(endDate.getDate() + 1);

      const response = await request(app)
        .get(`/api/admin/transactions?startDate=${startDate.toISOString()}&endDate=${endDate.toISOString()}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data.transactions)).toBe(true);
    });

    it('should validate filter parameters', async () => {
      const response = await request(app)
        .get('/api/admin/transactions?status=INVALID_STATUS')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject transaction access with customer token', async () => {
      const response = await request(app)
        .get('/api/admin/transactions')
        .set('Authorization', `Bearer ${customerToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Admin access required');
    });
  });

  describe('GET /api/admin/schemes', () => {
    beforeAll(async () => {
      // Create a test scheme for admin to view
      await request(app)
        .post('/api/schemes')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          customerId: customerId,
          schemeType: 'monthly_sip',
          monthlyAmount: 3000.00,
          durationMonths: 12,
          startDate: new Date().toISOString()
        });
    });

    it('should get all schemes with pagination', async () => {
      const response = await request(app)
        .get('/api/admin/schemes?page=1&limit=10')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('schemes');
      expect(response.body.data).toHaveProperty('pagination');
      
      expect(Array.isArray(response.body.data.schemes)).toBe(true);

      if (response.body.data.schemes.length > 0) {
        const scheme = response.body.data.schemes[0];
        expect(scheme).toHaveProperty('scheme_id');
        expect(scheme).toHaveProperty('customer_id');
        expect(scheme).toHaveProperty('scheme_type');
        expect(scheme).toHaveProperty('monthly_amount');
        expect(scheme).toHaveProperty('status');
      }
    });

    it('should filter schemes by status', async () => {
      const response = await request(app)
        .get('/api/admin/schemes?status=active')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.schemes.forEach(scheme => {
        expect(scheme.status).toBe('active');
      });
    });

    it('should filter schemes by customer ID', async () => {
      const response = await request(app)
        .get(`/api/admin/schemes?customerId=${customerId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.schemes.forEach(scheme => {
        expect(scheme.customer_id).toBe(customerId);
      });
    });

    it('should validate filter parameters', async () => {
      const response = await request(app)
        .get('/api/admin/schemes?status=invalid_status')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject scheme access with customer token', async () => {
      const response = await request(app)
        .get('/api/admin/schemes')
        .set('Authorization', `Bearer ${customerToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Admin access required');
    });
  });

  describe('GET /api/admin/export', () => {
    it('should export all data for backup', async () => {
      const response = await request(app)
        .get('/api/admin/export')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('customers');
      expect(response.body.data).toHaveProperty('transactions');
      expect(response.body.data).toHaveProperty('schemes');
      expect(response.body.data).toHaveProperty('analytics');
      expect(response.body.data).toHaveProperty('export_date');
      expect(response.body.data).toHaveProperty('business_id');

      expect(Array.isArray(response.body.data.customers)).toBe(true);
      expect(Array.isArray(response.body.data.transactions)).toBe(true);
      expect(Array.isArray(response.body.data.schemes)).toBe(true);
      expect(Array.isArray(response.body.data.analytics)).toBe(true);
    });

    it('should reject export with customer token', async () => {
      const response = await request(app)
        .get('/api/admin/export')
        .set('Authorization', `Bearer ${customerToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Admin access required');
    });

    it('should reject export without authentication', async () => {
      const response = await request(app)
        .get('/api/admin/export')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  afterAll(async () => {
    console.log('Admin tests completed');
  });
});

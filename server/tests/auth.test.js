// =====================================================
// VMUrugan Gold Trading - Authentication Tests
// =====================================================

const request = require('supertest');
const app = require('../server-sqlserver');

describe('Authentication Endpoints', () => {
  let testUserId;
  let testCustomerId;
  let authToken;

  const testUser = {
    phone: '9876543999',
    email: 'test.auth@vmurugan.com',
    password: 'testpass123',
    name: 'Test Auth User',
    address: 'Test Address, Chennai, Tamil Nadu',
    panCard: 'ABCDE9999F'
  };

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('userId');
      expect(response.body.data).toHaveProperty('customerId');
      expect(response.body.data).toHaveProperty('accessToken');
      expect(response.body.data.phone).toBe(testUser.phone);
      expect(response.body.data.email).toBe(testUser.email);

      testUserId = response.body.data.userId;
      testCustomerId = response.body.data.customerId;
      authToken = response.body.data.accessToken;
    });

    it('should reject registration with invalid phone number', async () => {
      const invalidUser = { ...testUser, phone: '123' };
      
      const response = await request(app)
        .post('/api/auth/register')
        .send(invalidUser)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject registration with invalid email', async () => {
      const invalidUser = { ...testUser, email: 'invalid-email' };
      
      const response = await request(app)
        .post('/api/auth/register')
        .send(invalidUser)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject registration with short password', async () => {
      const invalidUser = { ...testUser, password: '123' };
      
      const response = await request(app)
        .post('/api/auth/register')
        .send(invalidUser)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject registration with invalid PAN card', async () => {
      const invalidUser = { ...testUser, panCard: 'INVALID' };
      
      const response = await request(app)
        .post('/api/auth/register')
        .send(invalidUser)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject duplicate registration', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(409);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('already exists');
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login with valid credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          phone: testUser.phone,
          password: testUser.password
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('accessToken');
      expect(response.body.data).toHaveProperty('refreshToken');
      expect(response.body.data.phone).toBe(testUser.phone);
      expect(response.body.data.role).toBe('customer');

      authToken = response.body.data.accessToken;
    });

    it('should reject login with invalid phone', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          phone: '9999999998',
          password: testUser.password
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid');
    });

    it('should reject login with invalid password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          phone: testUser.phone,
          password: 'wrongpassword'
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid');
    });

    it('should reject login with invalid phone format', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          phone: '123',
          password: testUser.password
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });
  });

  describe('POST /api/auth/logout', () => {
    it('should logout successfully with valid token', async () => {
      const response = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('Logged out');
    });

    it('should reject logout without token', async () => {
      const response = await request(app)
        .post('/api/auth/logout')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });

    it('should reject logout with invalid token', async () => {
      const response = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', 'Bearer invalid-token')
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid token');
    });
  });

  describe('GET /api/customers/validate/:phone', () => {
    beforeAll(async () => {
      // Login again to get fresh token
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          phone: testUser.phone,
          password: testUser.password
        });
      authToken = loginResponse.body.data.accessToken;
    });

    it('should validate existing customer', async () => {
      const response = await request(app)
        .get(`/api/customers/validate/${testUser.phone}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('customer_id');
      expect(response.body.data.phone).toBe(testUser.phone);
    });

    it('should return 404 for non-existing customer', async () => {
      const response = await request(app)
        .get('/api/customers/validate/9999999997')
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
  });

  describe('GET /api/customers/profile', () => {
    it('should get customer profile with valid token', async () => {
      const response = await request(app)
        .get('/api/customers/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('customer_id');
      expect(response.body.data).toHaveProperty('name');
      expect(response.body.data).toHaveProperty('phone');
      expect(response.body.data).toHaveProperty('email');
    });

    it('should reject profile request without token', async () => {
      const response = await request(app)
        .get('/api/customers/profile')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  // Admin authentication tests
  describe('Admin Authentication', () => {
    let adminToken;

    it('should login admin with valid credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          phone: '9999999999',
          password: process.env.ADMIN_DEFAULT_PASSWORD || 'VMURUGAN_ADMIN_2025'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.role).toBe('admin');
      adminToken = response.body.data.accessToken;
    });

    it('should access admin dashboard with admin token', async () => {
      const response = await request(app)
        .get('/api/admin/dashboard')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('stats');
    });

    it('should reject admin access with customer token', async () => {
      const response = await request(app)
        .get('/api/admin/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Admin access required');
    });
  });

  // Cleanup
  afterAll(async () => {
    // Clean up test data if needed
    // Note: In a real test environment, you might want to use a separate test database
    console.log('Authentication tests completed');
  });
});

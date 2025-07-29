// =====================================================
// VMUrugan Gold Trading - Analytics Tests
// =====================================================

const request = require('supertest');
const app = require('../server-sqlserver');

describe('Analytics Endpoints', () => {
  let authToken;
  let adminToken;
  let customerId;

  const testUser = {
    phone: '9876543994',
    email: 'test.analytics@vmurugan.com',
    password: 'testpass123',
    name: 'Test Analytics User',
    address: 'Test Address, Chennai, Tamil Nadu',
    panCard: 'ABCDE9994F'
  };

  beforeAll(async () => {
    // Register and login test user
    const registerResponse = await request(app)
      .post('/api/auth/register')
      .send(testUser);

    customerId = registerResponse.body.data.customerId;
    authToken = registerResponse.body.data.accessToken;

    // Login as admin
    const adminResponse = await request(app)
      .post('/api/auth/login')
      .send({
        phone: '9999999999',
        password: process.env.ADMIN_DEFAULT_PASSWORD || 'VMURUGAN_ADMIN_2025'
      });

    adminToken = adminResponse.body.data.accessToken;
  });

  describe('POST /api/analytics', () => {
    it('should log analytics event successfully', async () => {
      const analyticsData = {
        event: 'user_login',
        data: {
          user_id: customerId,
          timestamp: new Date().toISOString(),
          device: 'mobile',
          platform: 'android',
          app_version: '2.0.0'
        }
      };

      const response = await request(app)
        .post('/api/analytics')
        .set('Authorization', `Bearer ${authToken}`)
        .send(analyticsData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('logged');
    });

    it('should log transaction analytics event', async () => {
      const analyticsData = {
        event: 'transaction_initiated',
        data: {
          customer_id: customerId,
          transaction_type: 'BUY',
          amount: 5000.00,
          gold_grams: 0.75,
          payment_method: 'UPI',
          timestamp: new Date().toISOString()
        }
      };

      const response = await request(app)
        .post('/api/analytics')
        .set('Authorization', `Bearer ${authToken}`)
        .send(analyticsData)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should log scheme analytics event', async () => {
      const analyticsData = {
        event: 'scheme_created',
        data: {
          customer_id: customerId,
          scheme_type: 'monthly_sip',
          monthly_amount: 3000.00,
          duration_months: 12,
          timestamp: new Date().toISOString()
        }
      };

      const response = await request(app)
        .post('/api/analytics')
        .set('Authorization', `Bearer ${authToken}`)
        .send(analyticsData)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should reject analytics without event name', async () => {
      const response = await request(app)
        .post('/api/analytics')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          data: { test: 'data' }
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject analytics with invalid event name', async () => {
      const response = await request(app)
        .post('/api/analytics')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          event: '',
          data: { test: 'data' }
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject analytics without data', async () => {
      const response = await request(app)
        .post('/api/analytics')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          event: 'test_event'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject analytics without authentication', async () => {
      const response = await request(app)
        .post('/api/analytics')
        .send({
          event: 'test_event',
          data: { test: 'data' }
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  describe('GET /api/analytics/events', () => {
    it('should get analytics events for admin', async () => {
      const response = await request(app)
        .get('/api/analytics/events')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('events');
      expect(response.body.data).toHaveProperty('pagination');
      expect(Array.isArray(response.body.data.events)).toBe(true);

      if (response.body.data.events.length > 0) {
        const event = response.body.data.events[0];
        expect(event).toHaveProperty('event_id');
        expect(event).toHaveProperty('event_name');
        expect(event).toHaveProperty('event_data');
        expect(event).toHaveProperty('timestamp');
      }
    });

    it('should filter events by event name', async () => {
      const response = await request(app)
        .get('/api/analytics/events?event=user_login')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.events.forEach(event => {
        expect(event.event_name).toBe('user_login');
      });
    });

    it('should filter events by date range', async () => {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - 1);
      const endDate = new Date();

      const response = await request(app)
        .get(`/api/analytics/events?startDate=${startDate.toISOString()}&endDate=${endDate.toISOString()}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data.events)).toBe(true);
    });

    it('should reject events access with customer token', async () => {
      const response = await request(app)
        .get('/api/analytics/events')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Admin access required');
    });

    it('should reject events access without authentication', async () => {
      const response = await request(app)
        .get('/api/analytics/events')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });
  });

  describe('GET /api/analytics/summary', () => {
    it('should get analytics summary for admin', async () => {
      const response = await request(app)
        .get('/api/analytics/summary')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('total_events');
      expect(response.body.data).toHaveProperty('events_today');
      expect(response.body.data).toHaveProperty('events_this_week');
      expect(response.body.data).toHaveProperty('events_this_month');
      expect(response.body.data).toHaveProperty('top_events');
      expect(response.body.data).toHaveProperty('user_activity');

      expect(typeof response.body.data.total_events).toBe('number');
      expect(typeof response.body.data.events_today).toBe('number');
      expect(Array.isArray(response.body.data.top_events)).toBe(true);
    });

    it('should get analytics summary for specific date range', async () => {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - 7);
      const endDate = new Date();

      const response = await request(app)
        .get(`/api/analytics/summary?startDate=${startDate.toISOString()}&endDate=${endDate.toISOString()}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('date_range');
      expect(response.body.data.date_range).toHaveProperty('start_date');
      expect(response.body.data.date_range).toHaveProperty('end_date');
    });

    it('should reject summary access with customer token', async () => {
      const response = await request(app)
        .get('/api/analytics/summary')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Admin access required');
    });
  });

  describe('GET /api/analytics/reports', () => {
    it('should generate business analytics report', async () => {
      const response = await request(app)
        .get('/api/analytics/reports?type=business')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('report_type');
      expect(response.body.data).toHaveProperty('generated_at');
      expect(response.body.data).toHaveProperty('metrics');
      expect(response.body.data.report_type).toBe('business');
    });

    it('should generate customer analytics report', async () => {
      const response = await request(app)
        .get('/api/analytics/reports?type=customer')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.report_type).toBe('customer');
      expect(response.body.data).toHaveProperty('customer_metrics');
    });

    it('should generate transaction analytics report', async () => {
      const response = await request(app)
        .get('/api/analytics/reports?type=transaction')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.report_type).toBe('transaction');
      expect(response.body.data).toHaveProperty('transaction_metrics');
    });

    it('should reject invalid report type', async () => {
      const response = await request(app)
        .get('/api/analytics/reports?type=invalid')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject reports access with customer token', async () => {
      const response = await request(app)
        .get('/api/analytics/reports?type=business')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Admin access required');
    });
  });

  describe('DELETE /api/analytics/cleanup', () => {
    it('should cleanup old analytics data', async () => {
      const response = await request(app)
        .delete('/api/analytics/cleanup?days=90')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('deleted_count');
      expect(response.body.data).toHaveProperty('cleanup_date');
      expect(typeof response.body.data.deleted_count).toBe('number');
    });

    it('should reject cleanup with invalid days parameter', async () => {
      const response = await request(app)
        .delete('/api/analytics/cleanup?days=0')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should reject cleanup with customer token', async () => {
      const response = await request(app)
        .delete('/api/analytics/cleanup?days=90')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Admin access required');
    });
  });

  afterAll(async () => {
    console.log('Analytics tests completed');
  });
});

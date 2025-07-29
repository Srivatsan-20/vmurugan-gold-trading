// =====================================================
// VMUrugan Gold Trading - Swagger API Documentation
// =====================================================

const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'VMUrugan Gold Trading API',
      version: '2.0.0',
      description: 'Complete RESTful API for VMUrugan Gold Trading Platform - On-Premises Backend',
      contact: {
        name: 'VMUrugan Gold Trading',
        email: 'admin@vmurugan.com',
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT',
      },
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Local Development Server',
      },
      {
        url: 'https://api.vmurugan.com',
        description: 'Production Server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'JWT Authorization header using the Bearer scheme. Example: "Authorization: Bearer {token}"',
        },
      },
      schemas: {
        User: {
          type: 'object',
          required: ['phone', 'email', 'password', 'name'],
          properties: {
            user_id: {
              type: 'string',
              format: 'uuid',
              description: 'Unique user identifier',
            },
            phone: {
              type: 'string',
              pattern: '^[6-9]\\d{9}$',
              description: 'Indian mobile phone number',
              example: '9876543210',
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'User email address',
              example: 'user@vmurugan.com',
            },
            name: {
              type: 'string',
              minLength: 2,
              maxLength: 255,
              description: 'Full name of the user',
              example: 'John Doe',
            },
            role: {
              type: 'string',
              enum: ['customer', 'admin'],
              description: 'User role',
              example: 'customer',
            },
            is_active: {
              type: 'boolean',
              description: 'Whether the user account is active',
              example: true,
            },
            created_at: {
              type: 'string',
              format: 'date-time',
              description: 'Account creation timestamp',
            },
            last_login_at: {
              type: 'string',
              format: 'date-time',
              description: 'Last login timestamp',
            },
          },
        },
        Customer: {
          type: 'object',
          required: ['customer_id', 'phone', 'name', 'email', 'address', 'pan_card'],
          properties: {
            customer_id: {
              type: 'string',
              pattern: '^VM\\d{6}$',
              description: 'Unique customer identifier',
              example: 'VM000001',
            },
            user_id: {
              type: 'string',
              format: 'uuid',
              description: 'Associated user ID',
            },
            phone: {
              type: 'string',
              pattern: '^[6-9]\\d{9}$',
              description: 'Customer phone number',
              example: '9876543210',
            },
            name: {
              type: 'string',
              description: 'Customer full name',
              example: 'John Doe',
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'Customer email',
              example: 'john@example.com',
            },
            address: {
              type: 'string',
              minLength: 10,
              description: 'Customer address',
              example: '123 Main St, Chennai, Tamil Nadu',
            },
            pan_card: {
              type: 'string',
              pattern: '^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
              description: 'PAN card number',
              example: 'ABCDE1234F',
            },
            total_invested: {
              type: 'number',
              format: 'decimal',
              minimum: 0,
              description: 'Total amount invested',
              example: 50000.00,
            },
            total_gold: {
              type: 'number',
              format: 'decimal',
              minimum: 0,
              description: 'Total gold holdings in grams',
              example: 7.5,
            },
            transaction_count: {
              type: 'integer',
              minimum: 0,
              description: 'Number of transactions',
              example: 15,
            },
            registration_date: {
              type: 'string',
              format: 'date-time',
              description: 'Customer registration date',
            },
          },
        },
        Transaction: {
          type: 'object',
          required: ['transaction_id', 'customer_id', 'type', 'amount', 'gold_grams', 'gold_price_per_gram', 'payment_method', 'status'],
          properties: {
            transaction_id: {
              type: 'string',
              description: 'Unique transaction identifier',
              example: 'TXN_1690123456_abc123',
            },
            customer_id: {
              type: 'string',
              description: 'Customer identifier',
              example: 'VM000001',
            },
            customer_phone: {
              type: 'string',
              description: 'Customer phone number',
              example: '9876543210',
            },
            customer_name: {
              type: 'string',
              description: 'Customer name',
              example: 'John Doe',
            },
            type: {
              type: 'string',
              enum: ['BUY', 'SELL', 'SCHEME_PAYMENT'],
              description: 'Transaction type',
              example: 'BUY',
            },
            amount: {
              type: 'number',
              format: 'decimal',
              minimum: 0.01,
              description: 'Transaction amount in INR',
              example: 10000.00,
            },
            gold_grams: {
              type: 'number',
              format: 'decimal',
              minimum: 0.001,
              description: 'Gold quantity in grams',
              example: 1.5,
            },
            gold_price_per_gram: {
              type: 'number',
              format: 'decimal',
              minimum: 0.01,
              description: 'Gold price per gram in INR',
              example: 6666.67,
            },
            payment_method: {
              type: 'string',
              enum: ['UPI', 'CARD', 'NET_BANKING', 'CASH'],
              description: 'Payment method used',
              example: 'UPI',
            },
            status: {
              type: 'string',
              enum: ['PENDING', 'SUCCESS', 'FAILED', 'CANCELLED'],
              description: 'Transaction status',
              example: 'SUCCESS',
            },
            gateway_transaction_id: {
              type: 'string',
              description: 'Payment gateway transaction ID',
              example: 'GATEWAY_TXN_123456',
            },
            transaction_fee: {
              type: 'number',
              format: 'decimal',
              minimum: 0,
              description: 'Transaction fee',
              example: 100.00,
            },
            gst: {
              type: 'number',
              format: 'decimal',
              minimum: 0,
              description: 'GST amount',
              example: 18.00,
            },
            timestamp: {
              type: 'string',
              format: 'date-time',
              description: 'Transaction timestamp',
            },
            completed_at: {
              type: 'string',
              format: 'date-time',
              description: 'Transaction completion timestamp',
            },
          },
        },
        Scheme: {
          type: 'object',
          required: ['scheme_id', 'customer_id', 'scheme_type', 'monthly_amount', 'duration_months', 'start_date'],
          properties: {
            scheme_id: {
              type: 'string',
              description: 'Unique scheme identifier',
              example: 'SCH_1690123456_abc123',
            },
            customer_id: {
              type: 'string',
              description: 'Customer identifier',
              example: 'VM000001',
            },
            customer_phone: {
              type: 'string',
              description: 'Customer phone number',
              example: '9876543210',
            },
            customer_name: {
              type: 'string',
              description: 'Customer name',
              example: 'John Doe',
            },
            scheme_type: {
              type: 'string',
              description: 'Type of investment scheme',
              example: 'monthly_sip',
            },
            monthly_amount: {
              type: 'number',
              format: 'decimal',
              minimum: 100,
              description: 'Monthly investment amount',
              example: 5000.00,
            },
            duration_months: {
              type: 'integer',
              minimum: 6,
              maximum: 120,
              description: 'Scheme duration in months',
              example: 12,
            },
            start_date: {
              type: 'string',
              format: 'date',
              description: 'Scheme start date',
              example: '2025-08-01',
            },
            end_date: {
              type: 'string',
              format: 'date',
              description: 'Scheme end date',
              example: '2026-08-01',
            },
            paid_months: {
              type: 'integer',
              minimum: 0,
              description: 'Number of months paid',
              example: 3,
            },
            remaining_months: {
              type: 'integer',
              minimum: 0,
              description: 'Remaining months',
              example: 9,
            },
            gold_accumulated: {
              type: 'number',
              format: 'decimal',
              minimum: 0,
              description: 'Gold accumulated in grams',
              example: 2.25,
            },
            total_paid: {
              type: 'number',
              format: 'decimal',
              minimum: 0,
              description: 'Total amount paid',
              example: 15000.00,
            },
            status: {
              type: 'string',
              enum: ['active', 'completed', 'cancelled'],
              description: 'Scheme status',
              example: 'active',
            },
          },
        },
        ApiResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              description: 'Indicates if the request was successful',
              example: true,
            },
            message: {
              type: 'string',
              description: 'Response message',
              example: 'Operation completed successfully',
            },
            data: {
              type: 'object',
              description: 'Response data',
            },
            error_code: {
              type: 'string',
              description: 'Error code if applicable',
              example: 'VALIDATION_ERROR',
            },
            errors: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  field: {
                    type: 'string',
                    description: 'Field name with error',
                  },
                  message: {
                    type: 'string',
                    description: 'Error message',
                  },
                },
              },
              description: 'Validation errors if applicable',
            },
          },
        },
        LoginRequest: {
          type: 'object',
          required: ['phone', 'password'],
          properties: {
            phone: {
              type: 'string',
              pattern: '^[6-9]\\d{9}$',
              description: 'User phone number',
              example: '9876543210',
            },
            password: {
              type: 'string',
              minLength: 6,
              description: 'User password',
              example: 'password123',
            },
          },
        },
        RegisterRequest: {
          type: 'object',
          required: ['phone', 'email', 'password', 'name', 'address', 'panCard'],
          properties: {
            phone: {
              type: 'string',
              pattern: '^[6-9]\\d{9}$',
              description: 'User phone number',
              example: '9876543210',
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'User email address',
              example: 'user@example.com',
            },
            password: {
              type: 'string',
              minLength: 6,
              description: 'User password',
              example: 'password123',
            },
            name: {
              type: 'string',
              minLength: 2,
              description: 'Full name',
              example: 'John Doe',
            },
            address: {
              type: 'string',
              minLength: 10,
              description: 'Complete address',
              example: '123 Main St, Chennai, Tamil Nadu',
            },
            panCard: {
              type: 'string',
              pattern: '^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
              description: 'PAN card number',
              example: 'ABCDE1234F',
            },
            deviceId: {
              type: 'string',
              description: 'Device identifier (optional)',
              example: 'device-123',
            },
          },
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
  },
  apis: ['./server-sqlserver.js', './routes/*.js'], // paths to files containing OpenAPI definitions
};

const specs = swaggerJsdoc(options);

module.exports = {
  specs,
  swaggerUi,
};

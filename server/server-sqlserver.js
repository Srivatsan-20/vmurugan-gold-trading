// =====================================================
// VMUrugan Gold Trading Platform - SQL Server Backend API
// On-Premises Migration from Firebase
// =====================================================

const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const { body, validationResult, param } = require('express-validator');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { specs, swaggerUi } = require('./swagger');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// =====================================================
// MIDDLEWARE CONFIGURATION
// =====================================================

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

// CORS configuration - More permissive for development
app.use(cors({
  origin: true, // Allow all origins in development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
  exposedHeaders: ['Content-Length', 'X-Foo', 'X-Bar'],
  preflightContinue: false,
  optionsSuccessStatus: 200
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', limiter);

// General middleware
app.use(compression());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// =====================================================
// SQL SERVER DATABASE CONNECTION
// =====================================================

const dbConfig = {
  server: process.env.DB_SERVER || 'localhost',
  port: parseInt(process.env.DB_PORT) || 1433,
  database: process.env.DB_NAME || 'VMUruganGoldTrading',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  options: {
    encrypt: process.env.DB_ENCRYPT === 'true',
    trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === 'true',
    enableArithAbort: true,
    requestTimeout: 30000,
    connectionTimeout: 30000,
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
};

// Debug logging
console.log('🔍 Database Configuration:');
console.log(`   Server: ${dbConfig.server}:${dbConfig.port}`);
console.log(`   Database: ${dbConfig.database}`);
console.log(`   User: ${dbConfig.user}`);
console.log(`   Password: ${dbConfig.password ? '***' : 'NOT SET'}`);
console.log(`   Encrypt: ${dbConfig.options.encrypt}`);
console.log(`   Trust Certificate: ${dbConfig.options.trustServerCertificate}`);

let poolPromise;

const initializeDatabase = async () => {
  try {
    poolPromise = new sql.ConnectionPool(dbConfig);
    await poolPromise.connect();
    console.log('✅ Connected to SQL Server database');
    return poolPromise;
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    process.exit(1);
  }
};

// =====================================================
// AUTHENTICATION MIDDLEWARE
// =====================================================

const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Access token required'
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Check if session is still active
    const pool = await poolPromise;
    const result = await pool.request()
      .input('userId', sql.UniqueIdentifier, decoded.userId)
      .input('tokenHash', sql.NVarChar, token.substring(0, 50))
      .query(`
        SELECT s.*, u.role, u.is_active 
        FROM sessions s 
        JOIN users u ON s.user_id = u.user_id 
        WHERE s.user_id = @userId 
        AND s.token_hash = @tokenHash 
        AND s.is_active = 1 
        AND s.expires_at > GETUTCDATE()
      `);

    if (result.recordset.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }

    req.user = {
      userId: decoded.userId,
      phone: decoded.phone,
      role: result.recordset[0].role,
      sessionId: result.recordset[0].session_id
    };

    next();
  } catch (error) {
    console.error('Token verification error:', error);
    return res.status(403).json({
      success: false,
      message: 'Invalid token'
    });
  }
};

const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Admin access required'
    });
  }
  next();
};

// =====================================================
// UTILITY FUNCTIONS
// =====================================================

const generateCustomerId = async (poolOrTransaction) => {
  try {
    // Get the next customer number
    const result = await poolOrTransaction.request()
      .query(`
        SELECT COUNT(*) + 1 as next_number
        FROM customers
        WHERE customer_id LIKE 'VM%'
      `);

    const nextNumber = result.recordset[0].next_number;
    return `VM${nextNumber.toString().padStart(6, '0')}`;
  } catch (error) {
    console.error('Error generating customer ID:', error);
    // Fallback to timestamp-based ID
    const timestamp = Date.now();
    return `VM${timestamp.toString().slice(-6)}`;
  }
};

const hashPassword = async (password) => {
  const rounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
  return await bcrypt.hash(password, rounds);
};

const generateTokens = (user) => {
  const payload = {
    userId: user.user_id,
    phone: user.phone,
    role: user.role
  };

  const accessToken = jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '24h'
  });

  const refreshToken = jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
  });

  return { accessToken, refreshToken };
};

// =====================================================
// SWAGGER DOCUMENTATION
// =====================================================

// Swagger UI setup
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs, {
  explorer: true,
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'VMUrugan Gold Trading API Documentation',
  swaggerOptions: {
    persistAuthorization: true,
    displayRequestDuration: true,
    docExpansion: 'none',
    filter: true,
    showExtensions: true,
    showCommonExtensions: true,
  },
}));

// Redirect root to API docs
app.get('/', (req, res) => {
  res.redirect('/api-docs');
});

// =====================================================
// HEALTH CHECK ENDPOINT
// =====================================================

/**
 * @swagger
 * /health:
 *   get:
 *     summary: Health check endpoint
 *     description: Check the health status of the API and database connection
 *     tags: [Health]
 *     responses:
 *       200:
 *         description: Service is healthy
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: OK
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                 service:
 *                   type: string
 *                   example: VMUrugan Gold Trading API
 *                 version:
 *                   type: string
 *                   example: 2.0.0
 *                 database:
 *                   type: string
 *                   example: Connected
 *                 environment:
 *                   type: string
 *                   example: development
 *       503:
 *         description: Service is unhealthy
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: ERROR
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                 service:
 *                   type: string
 *                   example: VMUrugan Gold Trading API
 *                 database:
 *                   type: string
 *                   example: Disconnected
 *                 error:
 *                   type: string
 *                   example: Connection failed
 */
app.get('/health', async (req, res) => {
  try {
    const pool = await poolPromise;
    await pool.request().query('SELECT 1 as health_check');

    res.json({
      status: 'OK',
      timestamp: new Date().toISOString(),
      service: 'VMUrugan Gold Trading API',
      version: '2.0.0',
      database: 'Connected',
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    res.status(503).json({
      status: 'ERROR',
      timestamp: new Date().toISOString(),
      service: 'VMUrugan Gold Trading API',
      database: 'Disconnected',
      error: error.message
    });
  }
});

// =====================================================
// AUTHENTICATION ENDPOINTS
// =====================================================

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new customer
 *     description: Create a new customer account with authentication credentials
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/RegisterRequest'
 *     responses:
 *       201:
 *         description: User registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         userId:
 *                           type: string
 *                           format: uuid
 *                         customerId:
 *                           type: string
 *                           example: VM000001
 *                         phone:
 *                           type: string
 *                           example: "9876543210"
 *                         email:
 *                           type: string
 *                           example: user@example.com
 *                         name:
 *                           type: string
 *                           example: John Doe
 *                         accessToken:
 *                           type: string
 *                           description: JWT access token
 *                         refreshToken:
 *                           type: string
 *                           description: JWT refresh token
 *       400:
 *         description: Validation failed
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       409:
 *         description: User already exists
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       500:
 *         description: Registration failed
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 */
app.post('/api/auth/register', [
  body('phone')
    .isMobilePhone('en-IN')
    .withMessage('Invalid phone number')
    .matches(/^[6-9][0-9]{9}$/)
    .withMessage('Phone number must start with 6-9 and be 10 digits'),
  body('email')
    .isEmail()
    .withMessage('Invalid email address')
    .normalizeEmail(),
  body('password')
    .isLength({ min: 4, max: 4 })
    .withMessage('MPIN must be exactly 4 digits')
    .isNumeric()
    .withMessage('MPIN must contain only numbers')
    .custom((value) => {
      // Check for weak MPIN patterns
      if (/^(\d)\1{3}$/.test(value)) {
        throw new Error('MPIN cannot have all same digits (e.g., 1111)');
      }
      if (/^(0123|1234|2345|3456|4567|5678|6789|9876|8765|7654|6543|5432|4321|3210)$/.test(value)) {
        throw new Error('MPIN cannot be sequential numbers');
      }
      if (['0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999'].includes(value)) {
        throw new Error('MPIN is too common, please choose a different one');
      }
      return true;
    }),
  body('name')
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters')
    .matches(/^[a-zA-Z\s\.]+$/)
    .withMessage('Name can only contain letters, spaces, and dots')
    .trim(),
  body('address')
    .isLength({ min: 10, max: 500 })
    .withMessage('Address must be between 10 and 500 characters')
    .trim(),
  body('panCard')
    .matches(/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/)
    .withMessage('Invalid PAN card format (e.g., ABCDE1234F)')
    .toUpperCase()
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

    const { phone, email, password, name, address, panCard, deviceId } = req.body;
    const pool = await poolPromise;

    // Check if user already exists with more specific error messages
    const existingUser = await pool.request()
      .input('phone', sql.NVarChar, phone)
      .input('email', sql.NVarChar, email)
      .query('SELECT user_id, phone, email FROM users WHERE phone = @phone OR email = @email');

    if (existingUser.recordset.length > 0) {
      const existing = existingUser.recordset[0];
      let message = 'Registration failed: ';
      if (existing.phone === phone && existing.email === email) {
        message += 'Both phone number and email are already registered';
      } else if (existing.phone === phone) {
        message += 'Phone number is already registered';
      } else {
        message += 'Email address is already registered';
      }

      return res.status(409).json({
        success: false,
        message,
        errorCode: 'USER_EXISTS'
      });
    }

    // Hash password
    const passwordHash = await hashPassword(password);

    // Start transaction
    const transaction = new sql.Transaction(pool);
    await transaction.begin();

    try {
      // Create user
      const userResult = await transaction.request()
        .input('phone', sql.NVarChar, phone)
        .input('email', sql.NVarChar, email)
        .input('passwordHash', sql.NVarChar, passwordHash)
        .input('name', sql.NVarChar, name)
        .query(`
          INSERT INTO users (phone, email, mpin_hash, name, role)
          OUTPUT INSERTED.user_id
          VALUES (@phone, @email, @passwordHash, @name, 'customer')
        `);

      const userId = userResult.recordset[0].user_id;

      // Generate customer ID
      const customerId = await generateCustomerId(transaction);

      // Create customer record
      await transaction.request()
        .input('customerId', sql.NVarChar, customerId)
        .input('userId', sql.UniqueIdentifier, userId)
        .input('phone', sql.NVarChar, phone)
        .input('name', sql.NVarChar, name)
        .input('email', sql.NVarChar, email)
        .input('address', sql.NVarChar, address)
        .input('panCard', sql.NVarChar, panCard)
        .input('deviceId', sql.NVarChar, deviceId || null)
        .input('businessId', sql.NVarChar, process.env.BUSINESS_ID || 'VMURUGAN_001')
        .query(`
          INSERT INTO customers (
            customer_id, user_id, phone, name, email, address, pan_card, device_id, business_id
          ) VALUES (
            @customerId, @userId, @phone, @name, @email, @address, @panCard, @deviceId, @businessId
          )
        `);

      await transaction.commit();

      // Generate tokens
      const user = { user_id: userId, phone, role: 'customer' };
      const { accessToken, refreshToken } = generateTokens(user);

      // Create session
      const sessionId = `SES_${Date.now()}_${require('uuid').v4().substring(0, 8)}`;
      await pool.request()
        .input('sessionId', sql.NVarChar, sessionId)
        .input('userId', sql.UniqueIdentifier, userId)
        .input('accessToken', sql.NVarChar, accessToken)
        .input('tokenHash', sql.NVarChar, accessToken.substring(0, 50))
        .input('deviceInfo', sql.NVarChar, req.headers['user-agent'] || null)
        .input('ipAddress', sql.NVarChar, req.ip)
        .input('expiresAt', sql.DateTime2, new Date(Date.now() + 24 * 60 * 60 * 1000))
        .query(`
          INSERT INTO sessions (session_id, user_id, access_token, token_hash, device_info, ip_address, expires_at)
          VALUES (@sessionId, @userId, @accessToken, @tokenHash, @deviceInfo, @ipAddress, @expiresAt)
        `);

      // Log successful registration
      console.log(`✅ User registered successfully: ${customerId} (${phone})`);

      res.status(201).json({
        success: true,
        message: 'Registration completed successfully! Welcome to VMurugan Gold Trading.',
        data: {
          userId,
          customerId,
          phone,
          email,
          name,
          accessToken,
          refreshToken,
          registrationDate: new Date().toISOString(),
          nextSteps: [
            'Your account is now active',
            'You can start investing in digital gold',
            'Explore our investment schemes',
            'Track your portfolio in real-time'
          ]
        }
      });

    } catch (error) {
      await transaction.rollback();
      throw error;
    }

  } catch (error) {
    console.error('❌ Registration error:', error);

    // Determine appropriate error message and status code
    let statusCode = 500;
    let message = 'Registration failed due to server error';
    let errorCode = 'INTERNAL_ERROR';

    if (error.message.includes('duplicate key') || error.message.includes('UNIQUE constraint')) {
      statusCode = 409;
      message = 'User with this phone number or email already exists';
      errorCode = 'DUPLICATE_USER';
    } else if (error.message.includes('validation')) {
      statusCode = 400;
      message = 'Invalid registration data provided';
      errorCode = 'VALIDATION_ERROR';
    }

    res.status(statusCode).json({
      success: false,
      message,
      errorCode,
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user
 *     description: Authenticate user and return access tokens
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LoginRequest'
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         userId:
 *                           type: string
 *                           format: uuid
 *                         customerId:
 *                           type: string
 *                           example: VM000001
 *                         phone:
 *                           type: string
 *                           example: "9876543210"
 *                         email:
 *                           type: string
 *                           example: user@example.com
 *                         name:
 *                           type: string
 *                           example: John Doe
 *                         role:
 *                           type: string
 *                           enum: [customer, admin]
 *                           example: customer
 *                         accessToken:
 *                           type: string
 *                           description: JWT access token
 *                         refreshToken:
 *                           type: string
 *                           description: JWT refresh token
 *       400:
 *         description: Validation failed
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       401:
 *         description: Invalid credentials
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       500:
 *         description: Login failed
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 */
app.post('/api/auth/login', [
  body('phone')
    .isMobilePhone('en-IN')
    .withMessage('Invalid phone number')
    .matches(/^[6-9][0-9]{9}$/)
    .withMessage('Phone number must start with 6-9 and be 10 digits'),
  body('password')
    .isLength({ min: 4, max: 4 })
    .withMessage('MPIN must be exactly 4 digits')
    .isNumeric()
    .withMessage('MPIN must contain only numbers')
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

    const { phone, password } = req.body;
    const pool = await poolPromise;

    // Get user with customer data
    const result = await pool.request()
      .input('phone', sql.NVarChar, phone)
      .query(`
        SELECT u.*, c.customer_id, c.name as customer_name
        FROM users u
        LEFT JOIN customers c ON u.user_id = c.user_id
        WHERE u.phone = @phone AND u.is_active = 1
      `);

    if (result.recordset.length === 0) {
      console.log(`❌ Login failed: User not found for phone ${phone}`);
      return res.status(401).json({
        success: false,
        message: 'Phone number not registered or account is inactive',
        errorCode: 'USER_NOT_FOUND'
      });
    }

    const user = result.recordset[0];

    // Check if user account is active
    if (!user.is_active) {
      console.log(`❌ Login failed: Inactive account for phone ${phone}`);
      return res.status(401).json({
        success: false,
        message: 'Account is inactive. Please contact support.',
        errorCode: 'ACCOUNT_INACTIVE'
      });
    }

    // Verify MPIN
    const isValidPassword = await bcrypt.compare(password, user.mpin_hash);
    if (!isValidPassword) {
      console.log(`❌ Login failed: Invalid MPIN for phone ${phone}`);
      return res.status(401).json({
        success: false,
        message: 'Incorrect MPIN. Please try again.',
        errorCode: 'INVALID_MPIN'
      });
    }

    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(user);

    // Create session
    const sessionId = `SES_${Date.now()}_${require('uuid').v4().substring(0, 8)}`;
    await pool.request()
      .input('sessionId', sql.NVarChar, sessionId)
      .input('userId', sql.UniqueIdentifier, user.user_id)
      .input('accessToken', sql.NVarChar, accessToken)
      .input('tokenHash', sql.NVarChar, accessToken.substring(0, 50))
      .input('deviceInfo', sql.NVarChar, req.headers['user-agent'] || null)
      .input('ipAddress', sql.NVarChar, req.ip)
      .input('expiresAt', sql.DateTime2, new Date(Date.now() + 24 * 60 * 60 * 1000))
      .query(`
        INSERT INTO sessions (session_id, user_id, access_token, token_hash, device_info, ip_address, expires_at)
        VALUES (@sessionId, @userId, @accessToken, @tokenHash, @deviceInfo, @ipAddress, @expiresAt)
      `);

    // Update last login
    await pool.request()
      .input('userId', sql.UniqueIdentifier, user.user_id)
      .query('UPDATE users SET last_login_at = GETUTCDATE() WHERE user_id = @userId');

    // Log successful login
    console.log(`✅ Login successful: ${user.customer_id || 'N/A'} (${phone})`);

    res.json({
      success: true,
      message: 'Welcome back! Login successful.',
      data: {
        userId: user.user_id,
        customerId: user.customer_id,
        phone: user.phone,
        email: user.email,
        name: user.customer_name || user.name,
        role: user.role,
        accessToken,
        refreshToken,
        lastLogin: new Date().toISOString(),
        sessionId
      }
    });

  } catch (error) {
    console.error('❌ Login error:', error);

    let statusCode = 500;
    let message = 'Login failed due to server error';
    let errorCode = 'INTERNAL_ERROR';

    if (error.message.includes('connection') || error.message.includes('timeout')) {
      statusCode = 503;
      message = 'Service temporarily unavailable. Please try again.';
      errorCode = 'SERVICE_UNAVAILABLE';
    }

    res.status(statusCode).json({
      success: false,
      message,
      errorCode,
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     summary: Logout user
 *     description: Invalidate user session and logout
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Logged out successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       401:
 *         description: Authentication required
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       500:
 *         description: Logout failed
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 */
app.post('/api/auth/logout', authenticateToken, async (req, res) => {
  try {
    const pool = await poolPromise;

    // Deactivate session
    await pool.request()
      .input('sessionId', sql.UniqueIdentifier, req.user.sessionId)
      .query('UPDATE sessions SET is_active = 0 WHERE session_id = @sessionId');

    res.json({
      success: true,
      message: 'Logged out successfully'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Logout failed'
    });
  }
});

// =====================================================
// CUSTOMER ENDPOINTS
// =====================================================

/**
 * @swagger
 * /api/customers/profile:
 *   get:
 *     summary: Get customer profile
 *     description: Retrieve the authenticated customer's profile information
 *     tags: [Customers]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Profile retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Customer'
 *       401:
 *         description: Authentication required
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       404:
 *         description: Customer profile not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       500:
 *         description: Failed to get profile
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 */
app.get('/api/customers/profile', authenticateToken, async (req, res) => {
  try {
    const pool = await poolPromise;

    const result = await pool.request()
      .input('userId', sql.UniqueIdentifier, req.user.userId)
      .query(`
        SELECT c.*, u.email, u.phone, u.created_at as user_created_at
        FROM customers c
        JOIN users u ON c.user_id = u.user_id
        WHERE c.user_id = @userId
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer profile not found'
      });
    }

    res.json({
      success: true,
      data: result.recordset[0]
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get profile'
    });
  }
});

/**
 * @swagger
 * /api/customers/validate/{phone}:
 *   get:
 *     summary: Validate customer by phone
 *     description: Check if a customer exists with the given phone number
 *     tags: [Customers]
 *     parameters:
 *       - in: path
 *         name: phone
 *         required: true
 *         schema:
 *           type: string
 *           pattern: '^[6-9]\\d{9}$'
 *         description: Indian mobile phone number
 *         example: "9876543210"
 *     responses:
 *       200:
 *         description: Customer found
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         customer_id:
 *                           type: string
 *                           example: VM000001
 *                         name:
 *                           type: string
 *                           example: John Doe
 *                         phone:
 *                           type: string
 *                           example: "9876543210"
 *                         email:
 *                           type: string
 *                           example: john@example.com
 *                         total_invested:
 *                           type: number
 *                           example: 50000.00
 *                         total_gold:
 *                           type: number
 *                           example: 7.5
 *       400:
 *         description: Invalid phone number format
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       404:
 *         description: Customer not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       500:
 *         description: Validation failed
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 */
app.get('/api/customers/validate/:phone', [
  param('phone').isMobilePhone('en-IN').withMessage('Invalid phone number')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const { phone } = req.params;
    const pool = await poolPromise;

    const result = await pool.request()
      .input('phone', sql.NVarChar, phone)
      .query(`
        SELECT c.customer_id, c.name, c.phone, c.email, c.total_invested, c.total_gold
        FROM customers c
        WHERE c.phone = @phone
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    res.json({
      success: true,
      data: result.recordset[0]
    });

  } catch (error) {
    console.error('Customer validation error:', error);
    res.status(500).json({
      success: false,
      message: 'Validation failed'
    });
  }
});

// =====================================================
// ROUTES
// =====================================================

// Import route modules
const transactionRoutes = require('./routes/transactions');
const schemeRoutes = require('./routes/schemes');
const adminRoutes = require('./routes/admin');

// Make pool available to routes
app.use((req, res, next) => {
  req.app.locals.pool = poolPromise;
  next();
});

// Mount routes
app.use('/api/transactions', authenticateToken, transactionRoutes);
app.use('/api/schemes', authenticateToken, schemeRoutes);
app.use('/api/admin', authenticateToken, requireAdmin, adminRoutes);

// =====================================================
// ANALYTICS ENDPOINTS
// =====================================================

// Log analytics event
app.post('/api/analytics', authenticateToken, [
  body('event').notEmpty().withMessage('Event name is required'),
  body('data').isObject().withMessage('Data must be an object')
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

    const { event, data } = req.body;
    const pool = await poolPromise;

    await pool.request()
      .input('event', sql.NVarChar, event)
      .input('data', sql.NVarChar, JSON.stringify(data))
      .input('userId', sql.UniqueIdentifier, req.user.userId)
      .input('businessId', sql.NVarChar, process.env.BUSINESS_ID || 'VMURUGAN_001')
      .query(`
        INSERT INTO analytics (event, data, user_id, business_id)
        VALUES (@event, @data, @userId, @businessId)
      `);

    res.json({
      success: true,
      message: 'Analytics event logged successfully'
    });

  } catch (error) {
    console.error('Analytics logging error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to log analytics event'
    });
  }
});

// =====================================================
// GOLD PRICE ENDPOINTS
// =====================================================

/**
 * @swagger
 * /api/gold/price:
 *   get:
 *     summary: Get current gold price
 *     tags: [Gold Price]
 *     responses:
 *       200:
 *         description: Current gold price data
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     pricePerGram:
 *                       type: number
 *                     pricePerOunce:
 *                       type: number
 *                     currency:
 *                       type: string
 *                     timestamp:
 *                       type: string
 *                     changePercent:
 *                       type: number
 *                     changeAmount:
 *                       type: number
 *                     trend:
 *                       type: string
 *                     source:
 *                       type: string
 *       500:
 *         description: Server error
 */
app.get('/api/gold/price', async (req, res) => {
  try {
    console.log('Gold price request received');

    // Try to fetch from MJDTA website
    const goldPrice = await fetchGoldPriceFromMJDTA();

    if (goldPrice) {
      res.json({
        success: true,
        data: goldPrice
      });
    } else {
      // Fallback to mock data if MJDTA is unavailable
      const mockPrice = generateMockGoldPrice();
      res.json({
        success: true,
        data: mockPrice
      });
    }

  } catch (error) {
    console.error('Gold price fetch error:', error);

    // Return mock data on error
    const mockPrice = generateMockGoldPrice();
    res.json({
      success: true,
      data: mockPrice
    });
  }
});

// Helper function to fetch gold price from MJDTA
async function fetchGoldPriceFromMJDTA() {
  try {
    console.log('Fetching gold price from MJDTA...');

    const response = await axios.get('https://thejewellersassociation.org', {
      headers: {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
      },
      timeout: 5000
    });

    if (response.status === 200) {
      console.log('Successfully fetched MJDTA page');
      return parseGoldPriceFromHtml(response.data);
    }

    return null;
  } catch (error) {
    console.error('Error fetching from MJDTA:', error.message);
    return null;
  }
}

// Helper function to parse gold price from HTML
function parseGoldPriceFromHtml(htmlContent) {
  try {
    console.log('Parsing MJDTA HTML content...');

    let gold22KPrice = null;

    // Pattern 1: Look for "9285.00" or similar price patterns with ()
    const pricePattern = /(\d{4,5}\.?\d{0,2})\s*\(\)/g;
    const matches = [...htmlContent.matchAll(pricePattern)];

    for (const match of matches) {
      const priceStr = match[1];
      if (priceStr) {
        const price = parseFloat(priceStr);
        if (price && price > 5000 && price < 15000) {
          gold22KPrice = price;
          console.log(`Found gold price with pattern 1: ₹${price}`);
          break;
        }
      }
    }

    // Pattern 2: Look for "22Kt" followed by price
    if (!gold22KPrice) {
      const gold22Pattern = /22Kt.*?(\d{4,5}\.?\d{0,2})/g;
      const gold22Match = gold22Pattern.exec(htmlContent);
      if (gold22Match) {
        gold22KPrice = parseFloat(gold22Match[1]);
        console.log(`Found gold price with pattern 2: ₹${gold22KPrice}`);
      }
    }

    // Pattern 3: Look for direct price patterns
    if (!gold22KPrice) {
      const directPricePattern = /(\d{4,5}\.\d{2})/g;
      const directMatches = [...htmlContent.matchAll(directPricePattern)];
      for (const match of directMatches) {
        const priceStr = match[1];
        if (priceStr) {
          const price = parseFloat(priceStr);
          if (price && price > 7000 && price < 12000) {
            gold22KPrice = price;
            console.log(`Found gold price with pattern 3: ₹${price}`);
            break;
          }
        }
      }
    }

    if (!gold22KPrice) {
      console.log('Could not extract gold price from MJDTA HTML');
      console.log('HTML content preview:', htmlContent.substring(0, 500));
      return null;
    }

    // Calculate simulated change
    const changePercent = (Date.now() % 200 - 100) / 100.0; // ±1%
    const changeAmount = gold22KPrice * (changePercent / 100);

    let trend = 'stable';
    if (changePercent > 0.1) {
      trend = 'up';
    } else if (changePercent < -0.1) {
      trend = 'down';
    }

    console.log(`Successfully parsed gold price from MJDTA: ₹${gold22KPrice}/gram`);

    return {
      pricePerGram: gold22KPrice,
      pricePerOunce: gold22KPrice * 31.1035, // Convert to per ounce
      currency: 'INR',
      timestamp: new Date().toISOString(),
      changePercent: Math.round(changePercent * 100) / 100,
      changeAmount: Math.round(changeAmount * 100) / 100,
      trend: trend,
      source: 'MJDTA Live Data (Chennai) - 22K'
    };
  } catch (error) {
    console.error('Error parsing MJDTA HTML:', error);
    return null;
  }
}

// Helper function to generate mock gold price data
function generateMockGoldPrice() {
  const basePrice = 7200; // Base price around ₹7200/gram for 22K gold
  const variation = Math.random() * 200 - 100; // ±₹100 variation
  const pricePerGram = basePrice + variation;

  return {
    pricePerGram: Math.round(pricePerGram * 100) / 100,
    pricePerOunce: Math.round(pricePerGram * 31.1035 * 100) / 100,
    currency: 'INR',
    timestamp: new Date().toISOString(),
    changePercent: Math.round((Math.random() * 2 - 1) * 100) / 100,
    changeAmount: Math.round((Math.random() * 100 - 50) * 100) / 100,
    trend: Math.random() > 0.5 ? 'up' : 'down',
    source: 'Mock Data (MJDTA Unavailable)'
  };
}

// =====================================================
// ERROR HANDLING MIDDLEWARE
// =====================================================

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.originalUrl,
    method: req.method
  });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);

  // SQL Server specific error handling
  if (error.name === 'ConnectionError') {
    return res.status(503).json({
      success: false,
      message: 'Database connection error'
    });
  }

  if (error.name === 'RequestError') {
    return res.status(400).json({
      success: false,
      message: 'Database request error',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Invalid request'
    });
  }

  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// =====================================================
// SERVER INITIALIZATION
// =====================================================

const startServer = async () => {
  try {
    await initializeDatabase();

    app.listen(PORT, () => {
      console.log(`🚀 VMUrugan Gold Trading API running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🏥 Health Check: http://localhost:${PORT}/health`);
      console.log(`🔐 API Base URL: http://localhost:${PORT}/api`);
      console.log(`📋 Available Endpoints:`);
      console.log(`   POST /api/auth/register - User registration`);
      console.log(`   POST /api/auth/login - User login`);
      console.log(`   POST /api/auth/logout - User logout`);
      console.log(`   GET  /api/customers/profile - Get customer profile`);
      console.log(`   GET  /api/customers/validate/:phone - Validate customer`);
      console.log(`   POST /api/transactions - Create transaction`);
      console.log(`   GET  /api/transactions/customer/:customerId - Get customer transactions`);
      console.log(`   POST /api/schemes - Create scheme`);
      console.log(`   GET  /api/schemes/customer/:customerId - Get customer schemes`);
      console.log(`   GET  /api/admin/dashboard - Admin dashboard`);
      console.log(`   GET  /api/admin/customers - Admin customers list`);
      console.log(`   GET  /api/admin/transactions - Admin transactions list`);
      console.log(`   POST /api/analytics - Log analytics event`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Shutting down gracefully...');
  if (poolPromise) {
    await poolPromise.close();
  }
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  if (poolPromise) {
    await poolPromise.close();
  }
  process.exit(0);
});

startServer();

module.exports = app;

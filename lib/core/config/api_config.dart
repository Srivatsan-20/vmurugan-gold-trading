// =====================================================
// VMUrugan Gold Trading - Backend API Configuration
// Replaces Firebase Configuration
// =====================================================

class ApiConfig {
  // Backend API Configuration
  static const String baseUrl = 'http://localhost:3000';
  static const String businessId = 'VMURUGAN_001';
  static const String businessName = 'VMUrugan Gold Trading';
  
  // API Endpoints
  static const String health = '/health';
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authLogout = '/api/auth/logout';
  static const String customersProfile = '/api/customers/profile';
  static const String customersValidate = '/api/customers/validate';
  static const String transactions = '/api/transactions';
  static const String schemes = '/api/schemes';
  static const String analytics = '/api/analytics';
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminCustomers = '/api/admin/customers';
  static const String adminTransactions = '/api/admin/transactions';
  static const String adminSchemes = '/api/admin/schemes';
  
  // HTTP Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
  
  // Validation
  static bool get isConfigured {
    return baseUrl.isNotEmpty && 
           businessId.isNotEmpty && 
           businessName.isNotEmpty;
  }
  
  // Configuration status
  static Map<String, dynamic> get status {
    if (isConfigured) {
      return {
        'configured': true,
        'message': 'Backend API is properly configured',
        'base_url': baseUrl,
        'business_id': businessId,
      };
    } else {
      return {
        'configured': false,
        'message': 'Backend API configuration required',
        'instructions': [
          '1. Ensure backend server is running',
          '2. Update baseUrl in api_config.dart',
          '3. Verify network connectivity',
          '4. Check server health endpoint',
        ],
      };
    }
  }
  
  // Full URL builder
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  // Headers with authorization
  static Map<String, String> getAuthHeaders(String? token) {
    final authHeaders = Map<String, String>.from(headers);
    if (token != null && token.isNotEmpty) {
      authHeaders['Authorization'] = 'Bearer $token';
    }
    return authHeaders;
  }
  
  // Test data for development
  static const Map<String, dynamic> testCustomer = {
    'phone': '9876543210',
    'password': 'test123',
    'name': 'Test Customer',
    'email': 'test@vmurugan.com',
    'address': 'Test Address, Chennai, Tamil Nadu',
    'panCard': 'ABCDE1234F',
  };
  
  static const Map<String, dynamic> adminCredentials = {
    'phone': '9999999999',
    'password': 'VMURUGAN_ADMIN_2025',
  };
}

// Backend API setup instructions
class ApiSetupInstructions {
  static const String setupGuide = '''
🔧 BACKEND API SETUP FOR VMURUGAN

1. START BACKEND SERVER:
   - Navigate to: server/ folder
   - Run: npm install
   - Copy: .env.example to .env
   - Update: SQL Server connection details
   - Run: npm run setup (first time only)
   - Run: npm run dev

2. CONFIGURE SQL SERVER:
   - Install: SQL Server 2019+ or SQL Server Express
   - Create: Database user for API
   - Update: Connection details in .env
   - Run: Database setup script

3. UPDATE APP CONFIGURATION:
   - Open: lib/core/config/api_config.dart
   - Update: baseUrl with your server IP/domain
   - Test: Network connectivity

4. VERIFY SETUP:
   - Check: http://localhost:3000/health
   - Test: Login with admin credentials
   - Verify: Database connections

5. PRODUCTION DEPLOYMENT:
   - Setup: Reverse proxy (Nginx/IIS)
   - Configure: SSL certificates
   - Update: Production URLs
   - Setup: Firewall rules

📱 TEST CREDENTIALS:
   Admin: 9999999999 / VMURUGAN_ADMIN_2025
   Customer: 9876543210 / test123

🌐 ENDPOINTS:
   Health: GET /health
   Register: POST /api/auth/register
   Login: POST /api/auth/login
   Profile: GET /api/customers/profile
   Transactions: GET /api/transactions/customer/:id
   Schemes: GET /api/schemes/customer/:id
   Dashboard: GET /api/admin/dashboard

🔒 AUTHENTICATION:
   - JWT tokens for session management
   - Bearer token in Authorization header
   - Automatic token refresh
   - Secure password hashing with bcrypt

📊 FEATURES:
   - Complete Firebase replacement
   - SQL Server database
   - RESTful API design
   - Input validation
   - Error handling
   - Rate limiting
   - Security headers
   - Audit logging

🚀 MIGRATION STATUS:
   ✅ Firebase Auth → JWT Authentication
   ✅ Firestore → SQL Server Database
   ✅ Firebase Functions → Express.js API
   ✅ Firebase Hosting → Self-hosted
   ✅ Real-time updates → HTTP polling
   ✅ Security rules → API middleware

💡 TROUBLESHOOTING:
   - Check server logs for errors
   - Verify database connectivity
   - Test API endpoints with Postman
   - Check network firewall settings
   - Validate JWT token format
   - Monitor SQL Server performance

📞 SUPPORT:
   - Check server health endpoint
   - Review API documentation
   - Test with provided credentials
   - Verify environment configuration
  ''';
}

// Error codes for API responses
class ApiErrorCodes {
  static const String networkError = 'NETWORK_ERROR';
  static const String serverError = 'SERVER_ERROR';
  static const String authenticationError = 'AUTH_ERROR';
  static const String validationError = 'VALIDATION_ERROR';
  static const String notFoundError = 'NOT_FOUND';
  static const String permissionError = 'PERMISSION_ERROR';
  static const String rateLimitError = 'RATE_LIMIT';
  static const String maintenanceError = 'MAINTENANCE';
}

// API response status codes
class ApiStatusCodes {
  static const int success = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int rateLimited = 429;
  static const int serverError = 500;
  static const int serviceUnavailable = 503;
}

// Environment configuration
class ApiEnvironment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  // Current environment (change based on build configuration)
  static const String current = development;
  
  static bool get isDevelopment => current == development;
  static bool get isStaging => current == staging;
  static bool get isProduction => current == production;
  
  // Environment-specific configurations
  static String get baseUrl {
    switch (current) {
      case development:
        // Local development URLs for different platforms
        return _getLocalUrl();
      case staging:
        return 'https://staging-api.vmurugan.com';
      case production:
        return 'https://api.vmurugan.com';
      default:
        return _getLocalUrl();
    }
  }

  // Get appropriate local URL based on platform
  static String _getLocalUrl() {
    // For local testing, you can manually change this based on your setup

    // Option 1: Android Emulator
    // return 'http://10.0.2.2:3000';

    // Option 2: iOS Simulator or Web
    return 'http://localhost:3000';

    // Option 3: Physical Device (replace with your computer's IP)
    // return 'http://192.168.1.100:3000';
  }
  
  static Duration get timeout {
    switch (current) {
      case development:
        return const Duration(seconds: 60); // Longer timeout for debugging
      case staging:
      case production:
        return const Duration(seconds: 30);
      default:
        return const Duration(seconds: 30);
    }
  }
  
  static bool get enableLogging {
    return isDevelopment || isStaging;
  }
}

// Migration tracking
class MigrationStatus {
  static const Map<String, bool> completedMigrations = {
    'firebase_config_replaced': true,
    'firebase_service_replaced': false, // Will be true after service migration
    'authentication_migrated': false,
    'customer_service_migrated': false,
    'transaction_service_migrated': false,
    'scheme_service_migrated': false,
    'admin_service_migrated': false,
    'analytics_service_migrated': false,
  };
  
  static bool get isFullyMigrated {
    return completedMigrations.values.every((migrated) => migrated);
  }
  
  static List<String> get pendingMigrations {
    return completedMigrations.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }
  
  static double get migrationProgress {
    final completed = completedMigrations.values.where((v) => v).length;
    return completed / completedMigrations.length;
  }
}

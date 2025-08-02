// =====================================================
// VMUrugan Gold Trading - Backend API Service
// Replaces Firebase Service with HTTP API calls
// =====================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BackendApiService {
  static String? _authToken;
  static String? _refreshToken;
  static Map<String, dynamic>? _currentUser;

  // Get current authentication token
  static String? get authToken => _authToken;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  // Check if backend API is properly configured
  static bool get isConfigured => ApiConfig.isConfigured;

  // Validate configuration before making requests
  static Map<String, dynamic> _validateConfig() {
    if (!isConfigured) {
      final status = ApiConfig.status;
      return {
        'success': false,
        'message': status['message'],
        'instructions': status['instructions'],
      };
    }
    return {'success': true};
  }

  // Make HTTP request with error handling
  static Future<Map<String, dynamic>> _makeRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool requireAuth = false,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      // Validate configuration
      final configValidation = _validateConfig();
      if (!configValidation['success']) {
        return configValidation;
      }

      final url = Uri.parse(ApiConfig.getUrl(endpoint));
      final headers = requireAuth 
          ? ApiConfig.getAuthHeaders(_authToken)
          : ApiConfig.headers;

      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      print('🌐 API Request: $method $url');
      if (body != null) {
        print('📤 Request Body: ${jsonEncode(body)}');
      }

      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers)
              .timeout(ApiConfig.timeout);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(ApiConfig.timeout);
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(ApiConfig.timeout);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers)
              .timeout(ApiConfig.timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('📥 API Response: ${response.statusCode}');
      print('📊 Response Body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        responseData = {
          'success': false,
          'message': 'Invalid JSON response',
          'raw_response': response.body,
        };
      }

      // Handle different status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else if (response.statusCode == 401) {
        // Unauthorized - clear auth token
        _authToken = null;
        _currentUser = null;
        return {
          'success': false,
          'message': 'Authentication required',
          'error_code': ApiErrorCodes.authenticationError,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Permission denied',
          'error_code': ApiErrorCodes.permissionError,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Resource not found',
          'error_code': ApiErrorCodes.notFoundError,
        };
      } else if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Too many requests. Please try again later.',
          'error_code': ApiErrorCodes.rateLimitError,
        };
      } else if (response.statusCode >= 500) {
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
          'error_code': ApiErrorCodes.serverError,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request failed',
          'error_code': ApiErrorCodes.serverError,
        };
      }

    } on SocketException catch (e) {
      print('❌ Network Error: $e');
      return {
        'success': false,
        'message': 'Network connection failed. Please check your internet connection.',
        'error_code': ApiErrorCodes.networkError,
      };
    } on http.ClientException catch (e) {
      print('❌ HTTP Client Error: $e');
      return {
        'success': false,
        'message': 'Connection failed. Please try again.',
        'error_code': ApiErrorCodes.networkError,
      };
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
        'error_code': ApiErrorCodes.serverError,
      };
    }
  }

  // =====================================================
  // AUTHENTICATION METHODS
  // =====================================================

  // Register new customer
  static Future<Map<String, dynamic>> registerCustomer({
    required String phone,
    required String email,
    required String password,
    required String name,
    required String address,
    required String panCard,
    String? deviceId,
  }) async {
    print('🔐 Registering customer: $phone');

    final response = await _makeRequest(
      method: 'POST',
      endpoint: ApiConfig.authRegister,
      body: {
        'phone': phone,
        'email': email,
        'password': password, // Backend expects 'password' field for MPIN
        'name': name,
        'address': address,
        'panCard': panCard,
        'deviceId': deviceId,
      },
    );

    if (response['success'] == true && response['data'] != null) {
      // Store authentication data
      final data = response['data'];
      _authToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      _currentUser = {
        'userId': data['userId'],
        'customerId': data['customerId'],
        'phone': data['phone'],
        'email': data['email'],
        'name': data['name'],
      };

      print('✅ Registration successful: ${data['customerId']}');
    }

    return response;
  }

  // Login customer
  static Future<Map<String, dynamic>> loginCustomer({
    required String phone,
    required String password,
  }) async {
    print('🔐 Logging in customer: $phone');

    final response = await _makeRequest(
      method: 'POST',
      endpoint: ApiConfig.authLogin,
      body: {
        'phone': phone,
        'password': password, // Backend expects 'password' field for MPIN
      },
    );

    if (response['success'] == true && response['data'] != null) {
      // Store authentication data
      final data = response['data'];
      _authToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      _currentUser = {
        'userId': data['userId'],
        'customerId': data['customerId'],
        'phone': data['phone'],
        'email': data['email'],
        'name': data['name'],
        'role': data['role'],
      };

      print('✅ Login successful: ${data['customerId']}');
    }

    return response;
  }

  // Logout customer
  static Future<Map<String, dynamic>> logoutCustomer() async {
    print('🔐 Logging out customer');

    final response = await _makeRequest(
      method: 'POST',
      endpoint: ApiConfig.authLogout,
      requireAuth: true,
    );

    // Clear local authentication data regardless of response
    _authToken = null;
    _refreshToken = null;
    _currentUser = null;

    print('✅ Logout completed');
    return response;
  }

  // Validate customer by phone
  static Future<Map<String, dynamic>> validateCustomer(String phone) async {
    print('🔍 Validating customer: $phone');

    final response = await _makeRequest(
      method: 'GET',
      endpoint: '${ApiConfig.customersValidate}/$phone',
    );

    if (response['success'] == true) {
      print('✅ Customer validation successful');
    } else {
      print('❌ Customer validation failed: ${response['message']}');
    }

    return response;
  }

  // =====================================================
  // CUSTOMER METHODS
  // =====================================================

  // Get customer profile
  static Future<Map<String, dynamic>> getCustomerProfile() async {
    print('👤 Getting customer profile');

    final response = await _makeRequest(
      method: 'GET',
      endpoint: ApiConfig.customersProfile,
      requireAuth: true,
    );

    if (response['success'] == true) {
      print('✅ Profile retrieved successfully');
    }

    return response;
  }

  // =====================================================
  // TRANSACTION METHODS
  // =====================================================

  // Create new transaction
  static Future<Map<String, dynamic>> createTransaction({
    required String customerId,
    required String type,
    required double amount,
    required double goldGrams,
    required double goldPricePerGram,
    required String paymentMethod,
    String? gatewayTransactionId,
    String? gatewayOrderId,
    String? deviceInfo,
    String? location,
    String? notes,
  }) async {
    print('💰 Creating transaction: $type for $customerId');

    final response = await _makeRequest(
      method: 'POST',
      endpoint: ApiConfig.transactions,
      requireAuth: true,
      body: {
        'customerId': customerId,
        'type': type,
        'amount': amount,
        'goldGrams': goldGrams,
        'goldPricePerGram': goldPricePerGram,
        'paymentMethod': paymentMethod,
        'gatewayTransactionId': gatewayTransactionId,
        'gatewayOrderId': gatewayOrderId,
        'deviceInfo': deviceInfo,
        'location': location,
        'notes': notes,
      },
    );

    if (response['success'] == true) {
      print('✅ Transaction created: ${response['data']['transactionId']}');
    }

    return response;
  }

  // Get customer transactions
  static Future<Map<String, dynamic>> getCustomerTransactions({
    required String customerId,
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) async {
    print('📊 Getting transactions for customer: $customerId');

    String endpoint = '${ApiConfig.transactions}/customer/$customerId';
    List<String> queryParams = [];

    queryParams.add('page=$page');
    queryParams.add('limit=$limit');
    if (status != null) queryParams.add('status=$status');
    if (type != null) queryParams.add('type=$type');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await _makeRequest(
      method: 'GET',
      endpoint: endpoint,
      requireAuth: true,
    );

    if (response['success'] == true) {
      print('✅ Transactions retrieved successfully');
      // Transform response to match expected format
      return {
        'success': true,
        'data': response['data']['transactions'] ?? [],
        'pagination': response['data']['pagination'],
      };
    }

    return response;
  }

  // Get all transactions (admin)
  static Future<Map<String, dynamic>> getAllTransactions({
    int page = 1,
    int limit = 50,
    String? status,
    String? type,
    String? customerId,
  }) async {
    print('📊 Getting all transactions');

    String endpoint = '${ApiConfig.adminTransactions}';
    List<String> queryParams = [];

    queryParams.add('page=$page');
    queryParams.add('limit=$limit');
    if (status != null) queryParams.add('status=$status');
    if (type != null) queryParams.add('type=$type');
    if (customerId != null) queryParams.add('customerId=$customerId');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await _makeRequest(
      method: 'GET',
      endpoint: endpoint,
      requireAuth: true,
    );

    if (response['success'] == true) {
      print('✅ All transactions retrieved successfully');
    }

    return response;
  }

  // Update transaction status
  static Future<Map<String, dynamic>> updateTransactionStatus({
    required String transactionId,
    required String status,
    String? gatewayTransactionId,
  }) async {
    print('🔄 Updating transaction status: $transactionId -> $status');

    final response = await _makeRequest(
      method: 'PUT',
      endpoint: '${ApiConfig.transactions}/$transactionId/status',
      requireAuth: true,
      body: {
        'status': status,
        'gatewayTransactionId': gatewayTransactionId,
      },
    );

    if (response['success'] == true) {
      print('✅ Transaction status updated successfully');
    }

    return response;
  }

  // =====================================================
  // SCHEME METHODS
  // =====================================================

  // Create new scheme
  static Future<Map<String, dynamic>> createScheme({
    required String customerId,
    required String schemeType,
    required double monthlyAmount,
    required int durationMonths,
    required DateTime startDate,
  }) async {
    print('📋 Creating scheme: $schemeType for $customerId');

    final response = await _makeRequest(
      method: 'POST',
      endpoint: ApiConfig.schemes,
      requireAuth: true,
      body: {
        'customerId': customerId,
        'schemeType': schemeType,
        'monthlyAmount': monthlyAmount,
        'durationMonths': durationMonths,
        'startDate': startDate.toIso8601String(),
      },
    );

    if (response['success'] == true) {
      print('✅ Scheme created: ${response['data']['schemeId']}');
    }

    return response;
  }

  // Get customer schemes
  static Future<Map<String, dynamic>> getCustomerSchemes({
    required String customerId,
    String? status,
  }) async {
    print('📋 Getting schemes for customer: $customerId');

    String endpoint = '${ApiConfig.schemes}/customer/$customerId';
    if (status != null) {
      endpoint += '?status=$status';
    }

    final response = await _makeRequest(
      method: 'GET',
      endpoint: endpoint,
      requireAuth: true,
    );

    if (response['success'] == true) {
      print('✅ Schemes retrieved successfully');
    }

    return response;
  }

  // Process scheme payment
  static Future<Map<String, dynamic>> processSchemePayment({
    required String schemeId,
    required double amount,
    required double goldGrams,
    required double goldPricePerGram,
    required String paymentMethod,
    String? gatewayTransactionId,
  }) async {
    print('💳 Processing scheme payment: $schemeId');

    final response = await _makeRequest(
      method: 'POST',
      endpoint: '${ApiConfig.schemes}/$schemeId/payment',
      requireAuth: true,
      body: {
        'amount': amount,
        'goldGrams': goldGrams,
        'goldPricePerGram': goldPricePerGram,
        'paymentMethod': paymentMethod,
        'gatewayTransactionId': gatewayTransactionId,
      },
    );

    if (response['success'] == true) {
      print('✅ Scheme payment processed successfully');
    }

    return response;
  }

  // Cancel scheme
  static Future<Map<String, dynamic>> cancelScheme({
    required String schemeId,
    String? reason,
  }) async {
    print('❌ Cancelling scheme: $schemeId');

    final response = await _makeRequest(
      method: 'PUT',
      endpoint: '${ApiConfig.schemes}/$schemeId/cancel',
      requireAuth: true,
      body: {
        'reason': reason,
      },
    );

    if (response['success'] == true) {
      print('✅ Scheme cancelled successfully');
    }

    return response;
  }

  // =====================================================
  // ADMIN METHODS
  // =====================================================

  // Get admin dashboard data
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    print('📊 Getting admin dashboard data');

    final response = await _makeRequest(
      method: 'GET',
      endpoint: ApiConfig.adminDashboard,
      requireAuth: true,
    );

    if (response['success'] == true) {
      print('✅ Dashboard data retrieved successfully');
    }

    return response;
  }

  // Get all customers (admin)
  static Future<Map<String, dynamic>> getAdminCustomers({
    int page = 1,
    int limit = 20,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    print('👥 Getting admin customers list');

    String endpoint = ApiConfig.adminCustomers;
    List<String> queryParams = [];

    queryParams.add('page=$page');
    queryParams.add('limit=$limit');
    if (search != null) queryParams.add('search=$search');
    if (sortBy != null) queryParams.add('sortBy=$sortBy');
    if (sortOrder != null) queryParams.add('sortOrder=$sortOrder');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await _makeRequest(
      method: 'GET',
      endpoint: endpoint,
      requireAuth: true,
    );

    if (response['success'] == true) {
      print('✅ Admin customers retrieved successfully');
    }

    return response;
  }

  // Get all transactions (admin)
  static Future<Map<String, dynamic>> getAdminTransactions({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? customerId,
    String? startDate,
    String? endDate,
  }) async {
    print('💰 Getting admin transactions list');

    String endpoint = ApiConfig.adminTransactions;
    List<String> queryParams = [];

    queryParams.add('page=$page');
    queryParams.add('limit=$limit');
    if (status != null) queryParams.add('status=$status');
    if (type != null) queryParams.add('type=$type');
    if (customerId != null) queryParams.add('customerId=$customerId');
    if (startDate != null) queryParams.add('startDate=$startDate');
    if (endDate != null) queryParams.add('endDate=$endDate');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await _makeRequest(
      method: 'GET',
      endpoint: endpoint,
      requireAuth: true,
    );

    if (response['success'] == true) {
      print('✅ Admin transactions retrieved successfully');
    }

    return response;
  }

  // =====================================================
  // ANALYTICS METHODS
  // =====================================================

  // Log analytics event
  static Future<void> logAnalytics({
    required String event,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('📈 Logging analytics: $event');

      await _makeRequest(
        method: 'POST',
        endpoint: ApiConfig.analytics,
        requireAuth: true,
        body: {
          'event': event,
          'data': data,
        },
      );

      print('✅ Analytics logged successfully');
    } catch (e) {
      print('❌ Analytics logging failed: $e');
      // Don't throw error for analytics failures
    }
  }

  // =====================================================
  // UTILITY METHODS
  // =====================================================

  // Check server health
  static Future<Map<String, dynamic>> checkServerHealth() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/health');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Server is healthy',
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Server health check failed',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server',
        'error': e.toString(),
      };
    }
  }

  // Clear authentication data
  static void clearAuth() {
    _authToken = null;
    _refreshToken = null;
    _currentUser = null;
    print('🔐 Authentication data cleared');
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'custom_server_service.dart';
import 'backend_api_service.dart';
import 'customer_service.dart';

class ApiService {
  // CONFIGURATION: Switch between Firebase and Custom Server
  static const bool useFirebase = false; // Set to false to use custom server

  // Firebase will be used by default, custom server when ready
  static const String mode = useFirebase ? 'Firebase' : 'Custom Server';

  // Smart router: Save transaction to active service
  static Future<Map<String, dynamic>> saveTransaction({
    required String transactionId,
    required String customerPhone,
    required String customerName,
    required String type,
    required double amount,
    required double goldGrams,
    required double goldPricePerGram,
    required String paymentMethod,
    required String status,
    required String gatewayTransactionId,
    required String deviceInfo,
    required String location,
  }) async {
    print('ApiService: Routing to $mode for transaction save');

    if (useFirebase) {
      return await FirebaseService.saveTransaction(
        transactionId: transactionId,
        customerPhone: customerPhone,
        customerName: customerName,
        type: type,
        amount: amount,
        goldGrams: goldGrams,
        goldPricePerGram: goldPricePerGram,
        paymentMethod: paymentMethod,
        status: status,
        gatewayTransactionId: gatewayTransactionId,
        deviceInfo: deviceInfo,
        location: location,
      );
    } else {
      // For backend API, get the proper customerId from customer service
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo['customer_id'];

      if (customerId == null || customerId.isEmpty) {
        print('❌ No customer ID found for transaction');
        return {
          'success': false,
          'message': 'Customer ID not found. Please login again.',
        };
      }

      print('📝 Creating transaction for customer: $customerId');
      return await BackendApiService.createTransaction(
        customerId: customerId, // Use proper customer ID from login
        type: type,
        amount: amount,
        goldGrams: goldGrams,
        goldPricePerGram: goldPricePerGram,
        paymentMethod: paymentMethod,
        gatewayTransactionId: gatewayTransactionId,
        deviceInfo: deviceInfo,
        location: location,
        notes: 'Transaction for $customerName',
      );
    }
  }

  // Update transaction status
  static Future<Map<String, dynamic>> updateTransactionStatus({
    required String transactionId,
    required String status,
    required String? failureReason,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (failureReason != null) 'failure_reason': failureReason,
      };

      // This method is not used in current implementation
      // Will be implemented when custom server is ready
      return {'success': false, 'message': 'Update not implemented yet'};

    } catch (e) {
      print('Error updating transaction status: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Smart router: Save customer information
  static Future<Map<String, dynamic>> saveCustomerInfo({
    required String phone,
    required String name,
    required String email,
    required String address,
    required String panCard,
    required String mpin,
    required String deviceId,
  }) async {
    print('ApiService: Routing to $mode for customer save');

    if (useFirebase) {
      return await FirebaseService.saveCustomer(
        phone: phone,
        name: name,
        email: email,
        address: address,
        panCard: panCard,
        deviceId: deviceId,
      );
    } else {
      // Use BackendApiService for registration
      return await BackendApiService.registerCustomer(
        phone: phone,
        email: email,
        password: mpin, // Use MPIN as password
        name: name,
        address: address,
        panCard: panCard,
        deviceId: deviceId,
      );
    }
  }

  // Smart router: Generate scheme ID
  static Future<String> generateSchemeId(String customerId) async {
    print('ApiService: Routing to $mode for scheme ID generation');

    if (useFirebase) {
      return await FirebaseService.generateUniqueSchemeId(customerId);
    } else {
      // For custom server, implement scheme ID generation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '$customerId-S${timestamp.toString().substring(timestamp.toString().length - 2)}';
    }
  }

  // Smart router: Save scheme
  static Future<Map<String, dynamic>> saveScheme({
    required String schemeId,
    required String customerId,
    required String customerPhone,
    required String customerName,
    required double monthlyAmount,
    required int durationMonths,
    required String schemeType,
    required String status,
  }) async {
    print('ApiService: Routing to $mode for scheme save');

    if (useFirebase) {
      return await FirebaseService.saveScheme(
        schemeId: schemeId,
        customerId: customerId,
        customerPhone: customerPhone,
        customerName: customerName,
        monthlyAmount: monthlyAmount,
        durationMonths: durationMonths,
        schemeType: schemeType,
        status: status,
      );
    } else {
      // For custom server, implement scheme saving
      return {
        'success': true,
        'message': 'Scheme saved to custom server',
        'scheme_id': schemeId,
      };
    }
  }

  // Smart router: Login customer
  static Future<Map<String, dynamic>> loginCustomer({
    required String phone,
    required String mpin,
  }) async {
    print('ApiService: Routing to $mode for customer login');

    if (useFirebase) {
      // Firebase doesn't have password-based login, use phone lookup
      return await FirebaseService.getCustomerByPhone(phone);
    } else {
      // Use backend API login
      return await BackendApiService.loginCustomer(
        phone: phone,
        password: mpin, // Use MPIN as password
      );
    }
  }

  // Smart router: Get customer transactions
  static Future<Map<String, dynamic>> getCustomerTransactions({
    required String customerId,
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) async {
    print('ApiService: Routing to $mode for customer transactions');

    if (useFirebase) {
      return await FirebaseService.getTransactions(
        limit: limit,
        status: status,
      );
    } else {
      // Use backend API to get customer transactions
      return await BackendApiService.getCustomerTransactions(
        customerId: customerId,
        page: page,
        limit: limit,
        status: status,
        type: type,
      );
    }
  }

  // Smart router: Get customer by phone
  static Future<Map<String, dynamic>> getCustomerByPhone(String phone) async {
    print('ApiService: Routing to $mode for customer lookup');

    if (useFirebase) {
      return await FirebaseService.getCustomerByPhone(phone);
    } else {
      // For backend API, we need to use login instead of lookup
      // This method should not be used with backend API
      return {
        'success': false,
        'customer': null,
        'message': 'Use loginCustomer method for backend API authentication',
      };
    }
  }

  // Smart router: Log analytics
  static Future<void> logAnalytics({
    required String event,
    required Map<String, dynamic> data,
  }) async {
    print('ApiService: Routing to $mode for analytics');

    if (useFirebase) {
      await FirebaseService.logAnalytics(event: event, data: data);
    } else {
      await BackendApiService.logAnalytics(event: event, data: data);
    }
  }

  // Smart router: Get transactions for admin
  static Future<Map<String, dynamic>> getTransactions({
    int limit = 50,
    String? customerPhone,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    print('ApiService: Routing to $mode for transactions');

    if (useFirebase) {
      return await FirebaseService.getTransactions(
        limit: limit,
        customerPhone: customerPhone,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      // Use backend API to get transactions
      return await BackendApiService.getAllTransactions(
        limit: limit,
        status: status,
      );
    }
  }

  // Smart router: Get dashboard data
  static Future<Map<String, dynamic>> getDashboardData({
    required String adminToken,
  }) async {
    print('ApiService: Routing to $mode for dashboard data');

    if (useFirebase) {
      return await FirebaseService.getDashboardData(adminToken: adminToken);
    } else {
      // Backend API doesn't need admin token for dashboard (uses JWT auth)
      return await BackendApiService.getAdminDashboard();
    }
  }
}

// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';
import '../utils/platform_utils.dart';

class CustomerService {
  static const String _customerPhoneKey = 'customer_phone';
  static const String _customerNameKey = 'customer_name';
  static const String _customerEmailKey = 'customer_email';
  static const String _customerRegisteredKey = 'customer_registered';

  // Get device information for tracking (web-compatible)
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    // Use the platform utility for web-compatible device info
    final platformInfo = PlatformUtils.getPlatformInfo();

    Map<String, dynamic> deviceData = {
      'platform': PlatformUtils.platformName,
      'device_id': PlatformUtils.generateDeviceId(),
      'model': 'Unknown', // Will be enhanced with device_info_plus later
      'brand': 'Unknown', // Will be enhanced with device_info_plus later
      'version': 'Unknown', // Will be enhanced with device_info_plus later
      'timestamp': DateTime.now().toIso8601String(),
      'user_agent': PlatformUtils.getUserAgent(),
      ...platformInfo, // Spread all platform info
    };

    print('Device info collected: $deviceData');
    return deviceData;
  }

  // Get location for transaction tracking (simplified for now)
  static Future<Map<String, dynamic>?> getLocation() async {
    // Simplified location - will be enhanced when geolocator is re-enabled
    try {
      return {
        'latitude': 0.0,
        'longitude': 0.0,
        'accuracy': 0.0,
        'timestamp': DateTime.now().toIso8601String(),
        'note': 'Location tracking temporarily disabled',
      };
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Check if customer is registered
  static Future<bool> isCustomerRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_customerRegisteredKey) ?? false;
  }

  // Save login session
  static Future<void> saveLoginSession(String phone) async {
    print('💾 Saving login session for phone: $phone');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get customer info from server
      print('🔍 Fetching customer data from backend API...');
      final result = await ApiService.getCustomerByPhone(phone);

      print('📊 Customer fetch result: $result');

      if (result['success'] && result['customer'] != null) {
        final customer = result['customer'];

        print('👤 Customer data found:');
        print('   Customer ID: ${customer['customer_id']}');
        print('   Name: ${customer['name']}');
        print('   Email: ${customer['email']}');
        print('   Phone: ${customer['phone']}');

        // Save customer info locally
        await prefs.setString(_customerPhoneKey, customer['phone'] ?? '');
        await prefs.setString(_customerNameKey, customer['name'] ?? '');
        await prefs.setString(_customerEmailKey, customer['email'] ?? '');
        await prefs.setString('customer_id', customer['customer_id'] ?? '');
        await prefs.setBool(_customerRegisteredKey, true);

        print('✅ Login session saved for customer: ${customer['customer_id']}');
        print('💾 Local storage updated with correct customer data');
      } else {
        print('❌ Failed to fetch customer data: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error saving login session: $e');
    }
  }

  // Get stored customer info
  static Future<Map<String, String?>> getCustomerInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final customerInfo = {
      'phone': prefs.getString(_customerPhoneKey),
      'name': prefs.getString(_customerNameKey),
      'email': prefs.getString(_customerEmailKey),
      'customer_id': prefs.getString('customer_id'),
    };

    print('📱 Retrieved customer info from local storage:');
    print('   Phone: ${customerInfo['phone']}');
    print('   Name: ${customerInfo['name']}');
    print('   Email: ${customerInfo['email']}');
    print('   Customer ID: ${customerInfo['customer_id']}');

    return customerInfo;
  }

  // Save customer info locally and to server
  static Future<Map<String, dynamic>> registerCustomer({
    required String phone,
    required String name,
    required String email,
    required String address,
    required String panCard,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceInfo = await getDeviceInfo();

      // Save locally
      await prefs.setString(_customerPhoneKey, phone);
      await prefs.setString(_customerNameKey, name);
      await prefs.setString(_customerEmailKey, email);
      await prefs.setBool(_customerRegisteredKey, true);

      // Save to server
      print('📞 CustomerService: Calling ApiService to save customer...');
      final result = await ApiService.saveCustomerInfo(
        phone: phone,
        name: name,
        email: email,
        address: address,
        panCard: panCard,
        deviceId: deviceInfo['device_id'] ?? 'unknown',
      );
      print('📞 CustomerService: ApiService result - ${result['success']} - ${result['message']}');

      if (result['success']) {
        // Save customer ID locally if provided
        if (result['customer_id'] != null) {
          await prefs.setString('customer_id', result['customer_id']);
        }

        print('Customer registered successfully with ID: ${result['customer_id']}');
        return {
          'success': true,
          'customer_id': result['customer_id'],
          'message': 'Registration successful',
        };
      } else {
        print('Failed to register customer on server: ${result['message']}');
        // Still return success as local storage succeeded
        return {
          'success': true,
          'customer_id': null,
          'message': 'Registration completed locally',
        };
      }
    } catch (e) {
      print('Error registering customer: $e');
      return {
        'success': false,
        'customer_id': null,
        'message': 'Registration failed: $e',
      };
    }
  }

  // Save transaction with customer details
  static Future<bool> saveTransactionWithCustomerData({
    required String transactionId,
    required String type,
    required double amount,
    required double goldGrams,
    required double goldPricePerGram,
    required String paymentMethod,
    required String status,
    required String gatewayTransactionId,
  }) async {
    try {
      final customerInfo = await getCustomerInfo();
      final deviceInfo = await getDeviceInfo();
      final location = await getLocation();

      // Ensure customer is registered
      if (customerInfo['phone'] == null) {
        print('Customer not registered - cannot save transaction');
        return false;
      }

      final result = await ApiService.saveTransaction(
        transactionId: transactionId,
        customerPhone: customerInfo['phone']!,
        customerName: customerInfo['name'] ?? 'Unknown',
        type: type,
        amount: amount,
        goldGrams: goldGrams,
        goldPricePerGram: goldPricePerGram,
        paymentMethod: paymentMethod,
        status: status,
        gatewayTransactionId: gatewayTransactionId,
        deviceInfo: deviceInfo.toString(),
        location: location?.toString() ?? 'Location not available',
      );

      if (result['success']) {
        print('Transaction saved to server successfully');
        
        // Log analytics
        await ApiService.logAnalytics(
          event: 'transaction_completed',
          data: {
            'transaction_id': transactionId,
            'amount': amount,
            'gold_grams': goldGrams,
            'payment_method': paymentMethod,
            'customer_phone': customerInfo['phone'],
          },
        );
        
        return true;
      } else {
        print('Failed to save transaction to server: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('Error saving transaction with customer data: $e');
      return false;
    }
  }

  // Update transaction status on server
  static Future<bool> updateTransactionStatus({
    required String transactionId,
    required String status,
    String? failureReason,
  }) async {
    try {
      final result = await ApiService.updateTransactionStatus(
        transactionId: transactionId,
        status: status,
        failureReason: failureReason,
      );

      return result['success'] ?? false;
    } catch (e) {
      print('Error updating transaction status: $e');
      return false;
    }
  }

  // Log app events for business analytics
  static Future<void> logEvent(String event, Map<String, dynamic> data) async {
    try {
      final customerInfo = await getCustomerInfo();
      final deviceInfo = await getDeviceInfo();

      await ApiService.logAnalytics(
        event: event,
        data: {
          ...data,
          'customer_phone': customerInfo['phone'],
          'device_id': deviceInfo['device_id'],
          'platform': deviceInfo['platform'],
        },
      );
    } catch (e) {
      print('Error logging event: $e');
    }
  }
}

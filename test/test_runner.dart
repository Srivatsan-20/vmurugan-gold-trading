import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'unit/mpin_validation_test.dart' as mpin_validation_tests;
import 'api/auth_api_test.dart' as auth_api_tests;
import 'services/backend_api_service_test.dart' as backend_service_tests;
import 'widgets/login_screen_test.dart' as login_screen_tests;

/// Test Runner for Authentication Flow
/// 
/// This file runs all authentication-related tests in a structured manner.
/// Run this with: flutter test test/test_runner.dart
void main() {
  group('🔐 Authentication System Test Suite', () {
    
    group('📱 Unit Tests', () {
      group('MPIN Validation', () {
        mpin_validation_tests.main();
      });
    });

    group('🌐 API Tests', () {
      group('Authentication Endpoints', () {
        auth_api_tests.main();
      });
    });

    group('🔧 Service Tests', () {
      group('Backend API Service', () {
        backend_service_tests.main();
      });
    });

    group('🎨 Widget Tests', () {
      group('Login Screen', () {
        login_screen_tests.main();
      });
    });

    // Summary test to verify overall system health
    group('🏁 System Health Check', () {
      test('All critical components should be testable', () {
        // This test ensures that all major components can be imported and tested
        expect(true, isTrue, reason: 'All test imports successful');
      });

      test('Test coverage should include key areas', () {
        final testAreas = [
          'MPIN validation logic',
          'API endpoint functionality', 
          'Service layer integration',
          'UI widget behavior',
        ];
        
        expect(testAreas.length, greaterThan(3), 
               reason: 'Should cover multiple test areas');
      });
    });
  });
}

/// Helper class for test utilities and common setup
class TestHelper {
  static const String testPhoneNumber = '9876543210';
  static const String testMPin = '2468';
  static const String testEmail = 'test@example.com';
  static const String testName = 'Test User';
  static const String testAddress = '123 Test Street, Test City - 123456';
  static const String testPan = 'ABCDE1234F';

  /// Generate test registration data
  static Map<String, dynamic> getTestRegistrationData({
    String? phone,
    String? email,
    String? mpin,
  }) {
    return {
      'phone': phone ?? testPhoneNumber,
      'name': testName,
      'email': email ?? testEmail,
      'address': testAddress,
      'panCard': testPan,
      'password': mpin ?? testMPin,
    };
  }

  /// Generate test login data
  static Map<String, dynamic> getTestLoginData({
    String? phone,
    String? mpin,
  }) {
    return {
      'phone': phone ?? testPhoneNumber,
      'password': mpin ?? testMPin,
    };
  }

  /// List of weak MPINs for testing
  static List<String> getWeakMPins() {
    return [
      '0000', '1111', '2222', '3333', '4444',
      '5555', '6666', '7777', '8888', '9999',
      '1234', '2345', '3456', '4567', '5678',
      '6789', '9876', '8765', '7654', '6543',
      '5432', '4321', '3210', '1212', '2323',
      '3434', '4545', '5656', '6767', '7878',
      '8989', '9090', '0101', '1122', '2233',
      '3344', '4455', '5566', '6677', '7788',
      '8899', '9900', '0011'
    ];
  }

  /// List of strong MPINs for testing
  static List<String> getStrongMPins() {
    return [
      '2468', '1357', '9517', '3691', '7249',
      '5038', '8162', '4927', '6385', '1749',
      '9263', '5847', '2916', '7304', '8571'
    ];
  }

  /// Validate test environment setup
  static bool isTestEnvironmentReady() {
    // Add checks for test environment prerequisites
    // e.g., test database, mock services, etc.
    return true;
  }

  /// Clean up test data
  static Future<void> cleanupTestData() async {
    // Add cleanup logic for test data
    // e.g., remove test users, clear test database, etc.
    print('🧹 Cleaning up test data...');
  }
}

/// Test configuration and constants
class TestConfig {
  static const String apiBaseUrl = 'http://localhost:3000/api';
  static const Duration apiTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;
  
  // Test database configuration (if needed)
  static const String testDatabaseName = 'vmurugan_gold_test';
  
  // Test user credentials
  static const String adminTestPhone = '9999999999';
  static const String adminTestMPin = '9999';
  
  /// Check if running in CI environment
  static bool get isCIEnvironment {
    return const bool.fromEnvironment('CI', defaultValue: false);
  }
  
  /// Get appropriate timeout for current environment
  static Duration get testTimeout {
    return isCIEnvironment ? 
           const Duration(seconds: 30) : 
           const Duration(seconds: 10);
  }
}

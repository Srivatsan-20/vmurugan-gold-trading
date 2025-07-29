// =====================================================
// VMUrugan Gold Trading - Backend API Service Tests
// =====================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:vmurugan_gold_trading/core/services/backend_api_service.dart';
import 'package:vmurugan_gold_trading/core/config/api_config.dart';

// Generate mocks
@GenerateMocks([http.Client])
import 'backend_api_service_test.mocks.dart';

void main() {
  group('BackendApiService Tests', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      // You would need to inject the mock client into BackendApiService
      // This is a simplified example
    });

    group('Authentication Tests', () => {
      test('should register customer successfully', () async {
        // Arrange
        const responseBody = '''
        {
          "success": true,
          "data": {
            "userId": "test-user-id",
            "customerId": "VM000001",
            "phone": "9876543210",
            "email": "test@example.com",
            "name": "Test User",
            "accessToken": "test-token",
            "refreshToken": "refresh-token"
          }
        }
        ''';

        when(mockClient.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 201));

        // Act
        final result = await BackendApiService.registerCustomer(
          phone: '9876543210',
          email: 'test@example.com',
          password: 'password123',
          name: 'Test User',
          address: 'Test Address',
          panCard: 'ABCDE1234F',
        );

        // Assert
        expect(result['success'], true);
        expect(result['data']['customerId'], 'VM000001');
        expect(result['data']['phone'], '9876543210');
      });

      test('should handle registration failure', () async {
        // Arrange
        const responseBody = '''
        {
          "success": false,
          "message": "Phone number already exists",
          "error_code": "DUPLICATE_PHONE"
        }
        ''';

        when(mockClient.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 409));

        // Act
        final result = await BackendApiService.registerCustomer(
          phone: '9876543210',
          email: 'test@example.com',
          password: 'password123',
          name: 'Test User',
          address: 'Test Address',
          panCard: 'ABCDE1234F',
        );

        // Assert
        expect(result['success'], false);
        expect(result['message'], 'Phone number already exists');
        expect(result['error_code'], 'DUPLICATE_PHONE');
      });

      test('should login customer successfully', () async {
        // Arrange
        const responseBody = '''
        {
          "success": true,
          "data": {
            "userId": "test-user-id",
            "customerId": "VM000001",
            "phone": "9876543210",
            "email": "test@example.com",
            "name": "Test User",
            "role": "customer",
            "accessToken": "test-token",
            "refreshToken": "refresh-token"
          }
        }
        ''';

        when(mockClient.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/login'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await BackendApiService.loginCustomer(
          phone: '9876543210',
          password: 'password123',
        );

        // Assert
        expect(result['success'], true);
        expect(result['data']['role'], 'customer');
        expect(result['data']['accessToken'], 'test-token');
      });

      test('should handle login failure', () async {
        // Arrange
        const responseBody = '''
        {
          "success": false,
          "message": "Invalid credentials",
          "error_code": "INVALID_CREDENTIALS"
        }
        ''';

        when(mockClient.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/login'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 401));

        // Act
        final result = await BackendApiService.loginCustomer(
          phone: '9876543210',
          password: 'wrongpassword',
        );

        // Assert
        expect(result['success'], false);
        expect(result['message'], 'Invalid credentials');
      });
    });

    group('Customer Tests', () => {
      test('should validate customer successfully', () async {
        // Arrange
        const responseBody = '''
        {
          "success": true,
          "data": {
            "customer_id": "VM000001",
            "name": "Test User",
            "phone": "9876543210",
            "email": "test@example.com",
            "total_invested": 50000.0,
            "total_gold": 7.5
          }
        }
        ''';

        when(mockClient.get(
          Uri.parse('${ApiConfig.baseUrl}/customers/validate/9876543210'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await BackendApiService.validateCustomer('9876543210');

        // Assert
        expect(result['success'], true);
        expect(result['data']['customer_id'], 'VM000001');
        expect(result['data']['phone'], '9876543210');
      });

      test('should handle customer not found', () async {
        // Arrange
        const responseBody = '''
        {
          "success": false,
          "message": "Customer not found",
          "error_code": "CUSTOMER_NOT_FOUND"
        }
        ''';

        when(mockClient.get(
          Uri.parse('${ApiConfig.baseUrl}/customers/validate/9999999999'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(responseBody, 404));

        // Act
        final result = await BackendApiService.validateCustomer('9999999999');

        // Assert
        expect(result['success'], false);
        expect(result['message'], 'Customer not found');
      });
    });

    group('Transaction Tests', () => {
      test('should create transaction successfully', () async {
        // Arrange
        const responseBody = '''
        {
          "success": true,
          "data": {
            "transactionId": "TXN_123456",
            "customerId": "VM000001",
            "type": "BUY",
            "amount": 10000.0,
            "goldGrams": 1.5,
            "status": "PENDING"
          }
        }
        ''';

        when(mockClient.post(
          Uri.parse('${ApiConfig.baseUrl}/transactions'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 201));

        // Act
        final result = await BackendApiService.createTransaction(
          customerId: 'VM000001',
          type: 'BUY',
          amount: 10000.0,
          goldGrams: 1.5,
          goldPricePerGram: 6666.67,
          paymentMethod: 'UPI',
        );

        // Assert
        expect(result['success'], true);
        expect(result['data']['transactionId'], 'TXN_123456');
        expect(result['data']['type'], 'BUY');
        expect(result['data']['status'], 'PENDING');
      });

      test('should update transaction status successfully', () async {
        // Arrange
        const responseBody = '''
        {
          "success": true,
          "data": {
            "transactionId": "TXN_123456",
            "status": "SUCCESS",
            "completedAt": "2025-07-29T12:00:00.000Z"
          }
        }
        ''';

        when(mockClient.put(
          Uri.parse('${ApiConfig.baseUrl}/transactions/TXN_123456/status'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await BackendApiService.updateTransactionStatus(
          transactionId: 'TXN_123456',
          status: 'SUCCESS',
        );

        // Assert
        expect(result['success'], true);
        expect(result['data']['status'], 'SUCCESS');
      });
    });

    group('Scheme Tests', () => {
      test('should create scheme successfully', () async {
        // Arrange
        const responseBody = '''
        {
          "success": true,
          "data": {
            "schemeId": "SCH_123456",
            "customerId": "VM000001",
            "schemeType": "monthly_sip",
            "monthlyAmount": 5000.0,
            "durationMonths": 12,
            "status": "active"
          }
        }
        ''';

        when(mockClient.post(
          Uri.parse('${ApiConfig.baseUrl}/schemes'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 201));

        // Act
        final result = await BackendApiService.createScheme(
          customerId: 'VM000001',
          schemeType: 'monthly_sip',
          monthlyAmount: 5000.0,
          durationMonths: 12,
          startDate: DateTime.now(),
        );

        // Assert
        expect(result['success'], true);
        expect(result['data']['schemeId'], 'SCH_123456');
        expect(result['data']['status'], 'active');
      });
    });

    group('Error Handling Tests', () => {
      test('should handle network timeout', () async {
        // Arrange
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(Exception('Network timeout'));

        // Act & Assert
        expect(
          () => BackendApiService.loginCustomer(
            phone: '9876543210',
            password: 'password123',
          ),
          throwsException,
        );
      });

      test('should handle server error', () async {
        // Arrange
        const responseBody = '''
        {
          "success": false,
          "message": "Internal server error",
          "error_code": "INTERNAL_ERROR"
        }
        ''';

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 500));

        // Act
        final result = await BackendApiService.loginCustomer(
          phone: '9876543210',
          password: 'password123',
        );

        // Assert
        expect(result['success'], false);
        expect(result['message'], 'Internal server error');
      });
    });
  });
}

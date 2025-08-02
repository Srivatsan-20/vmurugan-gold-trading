import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// API Integration Tests for Authentication Endpoints
/// Tests the backend registration and login APIs
void main() {
  group('Authentication API Tests', () {
    // Update this URL to match your backend server
    const String baseUrl = 'http://localhost:3000/api/auth';
    
    // Test data
    final Map<String, dynamic> validRegistrationData = {
      'phone': '9876543210',
      'name': 'John Doe',
      'email': 'john.doe.test@example.com',
      'address': '123 Main Street, Test City, Test State - 123456',
      'panCard': 'ABCDE1234F',
      'password': '2468', // MPIN
    };

    final Map<String, dynamic> validLoginData = {
      'phone': '9876543210',
      'password': '2468', // MPIN
    };

    group('Registration API Tests', () {
      test('should register user with valid data', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(validRegistrationData),
        );

        expect(response.statusCode, anyOf([200, 201]));
        
        final responseData = json.decode(response.body);
        expect(responseData['success'], isTrue);
        expect(responseData['message'], contains('successful'));
        expect(responseData['data'], isNotNull);
        expect(responseData['data']['customerId'], isNotNull);
        expect(responseData['data']['accessToken'], isNotNull);
      });

      test('should reject registration with invalid phone number', () async {
        final invalidData = Map<String, dynamic>.from(validRegistrationData);
        invalidData['phone'] = '123456'; // Invalid phone

        final response = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(invalidData),
        );

        expect(response.statusCode, equals(400));
        
        final responseData = json.decode(response.body);
        expect(responseData['success'], isFalse);
        expect(responseData['message'], contains('Validation failed'));
      });

      test('should reject registration with weak MPIN', () async {
        final weakMpinData = Map<String, dynamic>.from(validRegistrationData);
        weakMpinData['password'] = '1234'; // Weak sequential MPIN
        weakMpinData['phone'] = '9876543211'; // Different phone to avoid conflict

        final response = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(weakMpinData),
        );

        expect(response.statusCode, equals(400));
        
        final responseData = json.decode(response.body);
        expect(responseData['success'], isFalse);
        expect(responseData['message'], contains('sequential'));
      });

      test('should reject registration with invalid email', () async {
        final invalidData = Map<String, dynamic>.from(validRegistrationData);
        invalidData['email'] = 'invalid-email';
        invalidData['phone'] = '9876543212'; // Different phone

        final response = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(invalidData),
        );

        expect(response.statusCode, equals(400));
        
        final responseData = json.decode(response.body);
        expect(responseData['success'], isFalse);
      });

      test('should reject registration with invalid PAN format', () async {
        final invalidData = Map<String, dynamic>.from(validRegistrationData);
        invalidData['panCard'] = 'INVALID123';
        invalidData['phone'] = '9876543213'; // Different phone

        final response = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(invalidData),
        );

        expect(response.statusCode, equals(400));
        
        final responseData = json.decode(response.body);
        expect(responseData['success'], isFalse);
      });

      test('should reject duplicate registration', () async {
        // First registration should succeed (if not already done)
        await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(validRegistrationData),
        );

        // Second registration with same data should fail
        final response = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(validRegistrationData),
        );

        expect(response.statusCode, equals(409));
        
        final responseData = json.decode(response.body);
        expect(responseData['success'], isFalse);
        expect(responseData['message'], contains('already exists'));
      });
    });

    group('Login API Tests', () {
      test('should login with valid credentials', () async {
        // Ensure user is registered first
        await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(validRegistrationData),
        );

        final response = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(validLoginData),
        );

        expect(response.statusCode, equals(200));
        
        final responseData = json.decode(response.body);
        expect(responseData['success'], isTrue);
        expect(responseData['message'], contains('successful'));
        expect(responseData['data'], isNotNull);
        expect(responseData['data']['accessToken'], isNotNull);
        expect(responseData['data']['customerId'], isNotNull);
      });

      test('should reject login with invalid phone number', () async {
        final invalidData = Map<String, dynamic>.from(validLoginData);
        invalidData['phone'] = '9999999999'; // Non-existent phone

        final response = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(invalidData),
        );

        expect(response.statusCode, equals(401));
        
        final responseData = json.decode(response.body);
        expect(responseData['success'], isFalse);
        expect(responseData['errorCode'], equals('USER_NOT_FOUND'));
      });

      test('should reject login with incorrect MPIN', () async {
        final invalidData = Map<String, dynamic>.from(validLoginData);
        invalidData['password'] = '0000'; // Wrong MPIN

        final response = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(invalidData),
        );

        expect(response.statusCode, equals(401));
        
        final responseData = json.decode(response.body);
        expect(responseData['success'], isFalse);
        expect(responseData['errorCode'], equals('INVALID_MPIN'));
      });

      test('should reject login with invalid phone format', () async {
        final invalidData = Map<String, dynamic>.from(validLoginData);
        invalidData['phone'] = '123456'; // Invalid format

        final response = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(invalidData),
        );

        expect(response.statusCode, equals(400));
        
        final responseData = json.decode(response.body);
        expect(responseData['success'], isFalse);
        expect(responseData['message'], contains('Validation failed'));
      });

      test('should reject login with invalid MPIN format', () async {
        final invalidData = Map<String, dynamic>.from(validLoginData);
        invalidData['password'] = '12a4'; // Non-numeric MPIN

        final response = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(invalidData),
        );

        expect(response.statusCode, equals(400));
        
        final responseData = json.decode(response.body);
        expect(responseData['success'], isFalse);
      });
    });

    group('API Response Format Tests', () {
      test('registration response should have correct structure', () async {
        final testData = Map<String, dynamic>.from(validRegistrationData);
        testData['phone'] = '9876543220'; // Unique phone
        testData['email'] = 'unique.test@example.com'; // Unique email

        final response = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(testData),
        );

        if (response.statusCode == 201) {
          final responseData = json.decode(response.body);
          
          // Check required fields
          expect(responseData, containsPair('success', isA<bool>()));
          expect(responseData, containsPair('message', isA<String>()));
          expect(responseData['data'], isA<Map>());
          
          final data = responseData['data'];
          expect(data, containsPair('userId', isA<String>()));
          expect(data, containsPair('customerId', isA<String>()));
          expect(data, containsPair('phone', isA<String>()));
          expect(data, containsPair('accessToken', isA<String>()));
        }
      });

      test('login response should have correct structure', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(validLoginData),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          
          // Check required fields
          expect(responseData, containsPair('success', true));
          expect(responseData, containsPair('message', isA<String>()));
          expect(responseData['data'], isA<Map>());
          
          final data = responseData['data'];
          expect(data, containsPair('userId', isA<String>()));
          expect(data, containsPair('customerId', isA<String>()));
          expect(data, containsPair('accessToken', isA<String>()));
          expect(data, containsPair('lastLogin', isA<String>()));
        }
      });
    });
  });
}

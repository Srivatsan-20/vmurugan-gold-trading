import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digi_gold/main.dart' as app;
import 'package:digi_gold/features/auth/screens/customer_registration_screen.dart';
import 'package:digi_gold/features/auth/screens/login_screen.dart';
import 'package:digi_gold/features/auth/widgets/mpin_input_widget.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    late SharedPreferences prefs;

    setUpAll(() async {
      // Clear any existing preferences
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    tearDown(() async {
      // Clean up after each test
      await prefs.clear();
    });

    testWidgets('Complete Registration Flow - Valid Data', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to registration screen
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Verify we're on the registration screen
      expect(find.byType(CustomerRegistrationScreen), findsOneWidget);
      expect(find.text('Customer Registration'), findsOneWidget);

      // Fill in the registration form
      await tester.enterText(find.byKey(const Key('phone_field')), '9876543210');
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('name_field')), 'John Doe');
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'john.doe@example.com');
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('address_field')), '123 Main Street, City, State - 123456');
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('pan_field')), 'ABCDE1234F');
      await tester.pumpAndSettle();

      // Proceed to MPIN creation
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify MPIN creation screen
      expect(find.text('Create Your MPIN'), findsOneWidget);
      expect(find.byType(MPinInputWidget), findsOneWidget);

      // Enter a strong MPIN
      await _enterMPin(tester, '2468');
      await tester.pumpAndSettle();

      // Verify MPIN confirmation screen
      expect(find.text('Confirm Your MPIN'), findsOneWidget);

      // Confirm MPIN
      await _enterMPin(tester, '2468');
      await tester.pumpAndSettle();

      // Wait for registration to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify success (this would depend on your success screen/navigation)
      // For now, we'll check if we're redirected or see a success message
      expect(find.textContaining('successful'), findsWidgets);
    });

    testWidgets('Registration Flow - Weak MPIN Detection', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to registration and fill form
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      await _fillRegistrationForm(tester);

      // Proceed to MPIN creation
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Enter a weak MPIN (sequential)
      await _enterMPin(tester, '1234');
      await tester.pumpAndSettle();

      // Verify weak MPIN warning appears
      expect(find.textContaining('Weak MPIN'), findsOneWidget);
      expect(find.text('Choose Different'), findsOneWidget);

      // Choose to use a different MPIN
      await tester.tap(find.text('Choose Different'));
      await tester.pumpAndSettle();

      // Enter a strong MPIN
      await _enterMPin(tester, '2468');
      await tester.pumpAndSettle();

      // Verify we can proceed
      expect(find.text('Confirm Your MPIN'), findsOneWidget);
    });

    testWidgets('Login Flow - Valid Credentials', (WidgetTester tester) async {
      // Assume user is already registered (you might want to register first or mock this)
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login screen
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify we're on the login screen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);

      // Enter login credentials
      await tester.enterText(find.byKey(const Key('phone_field')), '9876543210');
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('mpin_field')), '2468');
      await tester.pumpAndSettle();

      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Wait for login to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify successful login (check for navigation or success message)
      expect(find.textContaining('Welcome back'), findsWidgets);
    });

    testWidgets('Login Flow - Invalid Credentials', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Enter invalid credentials
      await tester.enterText(find.byKey(const Key('phone_field')), '9999999999');
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('mpin_field')), '0000');
      await tester.pumpAndSettle();

      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Wait for error to appear
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify error message appears
      expect(find.textContaining('not registered'), findsWidgets);
    });

    testWidgets('Form Validation Tests', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Test invalid phone number
      await tester.enterText(find.byKey(const Key('phone_field')), '123456');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.textContaining('valid phone'), findsWidgets);

      // Test invalid email
      await tester.enterText(find.byKey(const Key('phone_field')), '9876543210');
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.textContaining('valid email'), findsWidgets);

      // Test invalid PAN
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('pan_field')), 'INVALID');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.textContaining('PAN'), findsWidgets);
    });
  });

  // Helper methods
  Future<void> _fillRegistrationForm(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('phone_field')), '9876543210');
    await tester.enterText(find.byKey(const Key('name_field')), 'John Doe');
    await tester.enterText(find.byKey(const Key('email_field')), 'john.doe@example.com');
    await tester.enterText(find.byKey(const Key('address_field')), '123 Main Street, City, State - 123456');
    await tester.enterText(find.byKey(const Key('pan_field')), 'ABCDE1234F');
    await tester.pumpAndSettle();
  }

  Future<void> _enterMPin(WidgetTester tester, String mpin) async {
    for (int i = 0; i < mpin.length; i++) {
      await tester.enterText(
        find.byKey(Key('mpin_field_$i')),
        mpin[i],
      );
      await tester.pumpAndSettle();
    }
  }
}

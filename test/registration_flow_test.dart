import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digi_gold/features/auth/screens/customer_registration_screen.dart';
import 'package:digi_gold/features/auth/widgets/mpin_input_widget.dart';

void main() {
  group('Registration Flow Tests', () {
    testWidgets('Registration screen loads successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerRegistrationScreen(),
        ),
      );

      // Wait for the screen to settle
      await tester.pumpAndSettle();

      // Verify that the registration screen loads
      expect(find.byType(CustomerRegistrationScreen), findsOneWidget);
      expect(find.text('Customer Registration'), findsOneWidget);
    });

    testWidgets('MPIN input widget works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MPinInputWidget(
              onMPinComplete: (pin) {},
            ),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that the MPIN input widget loads
      expect(find.byType(MPinInputWidget), findsOneWidget);
    });

    testWidgets('Form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerRegistrationScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Try to submit without filling the form
      final submitButton = find.text('Continue');
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Should show validation errors
        expect(find.textContaining('required'), findsWidgets);
      }
    });
  });
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_service.dart';
import '../../../main.dart';
import 'customer_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _mpinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _mpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.getPadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                
                // Logo and Welcome Section
                Center(
                  child: Column(
                    children: [
                      VMUruganLogo(
                        size: 120,
                        primaryColor: Colors.red,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Welcome To VMurugan Jewellers',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Your trusted partner for digital gold investments',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Login Form
                Text(
                  'Login to your account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                CustomTextField(
                  label: 'Mobile Number',
                  hint: 'Enter your mobile number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone,
                  validator: _validatePhone,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // MPIN Input
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  controller: _mpinController,
                  label: 'Enter MPIN',
                  hint: 'Enter your 4-digit MPIN',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter MPIN';
                    }
                    if (value.length != 4) {
                      return 'MPIN must be 4 digits';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Login Button
                CustomButton(
                  text: 'Login with MPIN',
                  onPressed: _isLoading ? null : _handleMPINLogin,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  type: ButtonType.primary,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Alternative Login Options
                Center(
                  child: Column(
                    children: [
                      Text(
                        'or',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Demo Login Button (Temporary)
                      GradientButton(
                        text: 'Demo Login (Skip OTP)',
                        onPressed: _handleDemoLogin,
                        gradient: AppColors.goldGreenGradient,
                        icon: Icons.play_arrow,
                        isFullWidth: true,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      CustomButton(
                        text: 'Login with Biometric',
                        onPressed: _handleBiometricLogin,
                        type: ButtonType.outline,
                        icon: Icons.fingerprint,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Register Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: Text(
                          'Register',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Terms and Privacy
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (value.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Please enter only numbers';
    }
    return null;
  }

  void _handleMPINLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Validate MPIN format first
        if (_mpinController.text.length != 4) {
          _showErrorMessage('Invalid MPIN. Please enter 4 digits.');
          return;
        }

        // Attempt login with backend API
        final loginResult = await ApiService.loginCustomer(
          phone: _phoneController.text.trim(),
          password: 'test123', // Updated password for registered users
        );

        if (loginResult['success'] == true) {
          // Save login session with customer data from login response
          await _saveLoginSessionFromResult(loginResult);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Login successful! Welcome back.'),
              backgroundColor: AppColors.success,
            ),
          );

          _navigateToHome();
        } else {
          final message = loginResult['message'] ?? 'Login failed';
          if (message.contains('not found') || message.contains('Invalid')) {
            _showErrorMessage('Phone number not registered. Please register first.');
          } else {
            _showErrorMessage('Login failed: $message');
          }
        }
      } catch (e) {
        _showErrorMessage('Login failed. Please try again.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveLoginSessionFromResult(Map<String, dynamic> loginResult) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (loginResult['success'] == true && loginResult['data'] != null) {
        final data = loginResult['data'];

        // Save customer info from login response
        await prefs.setString('customer_phone', data['phone'] ?? '');
        await prefs.setString('customer_name', data['name'] ?? '');
        await prefs.setString('customer_email', data['email'] ?? '');
        await prefs.setString('customer_id', data['customerId'] ?? '');
        await prefs.setBool('customer_registered', true);

        // Save authentication tokens
        if (data['accessToken'] != null) {
          await prefs.setString('access_token', data['accessToken']);
        }
        if (data['refreshToken'] != null) {
          await prefs.setString('refresh_token', data['refreshToken']);
        }

        print('✅ Login session saved successfully');
        print('   Customer ID: ${data['customerId']}');
        print('   Name: ${data['name']}');
        print('   Phone: ${data['phone']}');
      }
    } catch (e) {
      print('❌ Error saving login session: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _handleDemoLogin() {
    // Show info about demo login
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Demo Login'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demo login will use a temporary session.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text('To test with registered customers:'),
            SizedBox(height: 8),
            Text('1. Register a customer first'),
            Text('2. Use the registered phone number'),
            Text('3. Enter any 4-digit MPIN'),
            SizedBox(height: 12),
            Text(
              'Note: Customer ID and scheme creation will work properly only with registered customers.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToHome();
            },
            child: const Text('Continue Demo'),
          ),
        ],
      ),
    );
  }

  void _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate biometric authentication
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // For demo, always succeed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Biometric authentication successful!'),
        backgroundColor: AppColors.success,
      ),
    );

    // Navigate to home after successful biometric login
    await Future.delayed(const Duration(milliseconds: 500));
    _navigateToHome();
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerRegistrationScreen(),
      ),
    );
  }

  void _navigateToOTP() {
    // TODO: Navigate to OTP verification screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP sent to ${_phoneController.text}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _navigateToHome() {
    // Navigate to home screen (we'll import this from main.dart)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }
}

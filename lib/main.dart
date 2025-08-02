import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/responsive.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/portfolio/screens/portfolio_screen.dart';
import 'features/gold/screens/schemes_screen.dart';
import 'features/gold/screens/transaction_history_screen.dart';
import 'features/gold/screens/buy_gold_screen.dart';
import 'features/gold/services/gold_price_service.dart';
import 'features/gold/models/gold_price_model.dart';
import 'core/widgets/vmurugan_logo.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/models/notification_model.dart';
import 'core/services/customer_service.dart';
import 'core/services/migration_service.dart';
import 'features/schemes/screens/scheme_creation_screen.dart';
import 'features/debug/screens/debug_screen.dart';
import 'test_platform_fix.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize migration service to use backend-only mode
  await MigrationService.initialize();
  print('🚀 App starting in ${MigrationService.currentPhase} mode');

  runApp(const DigiGoldApp());
}

class DigiGoldApp extends StatelessWidget {
  const DigiGoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VMUrugan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const OnboardingScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GoldPriceService _priceService = GoldPriceService();
  final NotificationService _notificationService = NotificationService();
  GoldPriceModel? _currentPrice;
  double investmentAmount = 2000.0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _priceService.initialize();
    _notificationService.initialize();

    // Listen to price updates
    _priceService.priceStream.listen((price) {
      if (mounted) {
        setState(() {
          _currentPrice = price;
        });
      }
    });

    // Listen to notification count updates
    _notificationService.unreadCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    });

    // Load initial price
    _loadInitialPrice();
  }

  void _loadInitialPrice() async {
    final price = await _priceService.getCurrentPrice();
    setState(() {
      _currentPrice = price;
    });
  }

  void _showPriceSourceInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gold Price Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Source: ${_priceService.priceSource}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Status: ${_priceService.isBackendAvailable ? "🟢 Backend Live Data" : "🔴 Backend Unavailable"}'),
            const SizedBox(height: 8),
            if (!_priceService.isBackendAvailable) ...[
              const Text('• Backend service is currently unavailable'),
              const Text('• Gold purchases are disabled'),
              const Text('• No price data available'),
              const SizedBox(height: 8),
              const Text(
                '⚠️ We only allow purchases with real-time MJDTA prices',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
              ),
            ] else ...[
              const Text('• Source: MJDTA Chennai (22K)'),
              const Text('• Official South India benchmark'),
              const Text('• Update times: 9:30 AM & 3:30 PM IST'),
              const Text('• Update frequency: Every 2 minutes'),
              const Text('• Purchases enabled with live prices'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Official MJDTA source:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• thejewellersassociation.org'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!_priceService.isBackendAvailable)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _priceService.retryBackendConnection();
              },
              child: const Text('Retry MJDTA'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goldPrice = _currentPrice?.pricePerGram;
    final goldQuantity = goldPrice != null ? investmentAmount / goldPrice : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VMUruganSimpleLogo(
              size: 32,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            ),
            const SizedBox(width: 8),
            const Text(
              'VMUrugan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              // Notification badge
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'help') {
                _showHelpDialog(context);
              } else if (value == 'about') {
                _showAboutDialog(context);
              } else if (value == 'test_register') {
                _testRegistration(context);
              } else if (value == 'test_platform') {
                _testPlatform(context);
              } else if (value == 'create_scheme') {
                _navigateToSchemeCreation(context);
              } else if (value == 'debug') {
                _navigateToDebug(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('Help & Support'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('About VMUrugan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_register',
                child: Row(
                  children: [
                    Icon(Icons.bug_report),
                    SizedBox(width: 8),
                    Text('Test Registration'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_platform',
                child: Row(
                  children: [
                    Icon(Icons.web),
                    SizedBox(width: 8),
                    Text('Test Platform Fix'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'create_scheme',
                child: Row(
                  children: [
                    Icon(Icons.savings),
                    SizedBox(width: 8),
                    Text('Create Scheme'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report),
                    SizedBox(width: 8),
                    Text('Debug & Test'),
                  ],
                ),
              ),


            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Responsive.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.goldGreenGradient,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VMUruganLogo(
                        size: 50,
                        primaryColor: Colors.red,
                        textColor: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Welcome to VMUrugan',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Start your digital gold investment journey',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Gold Price Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Current Gold Price (22K)',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () {
                                _showPriceSourceInfo();
                              },
                              tooltip: 'Price Source Info',
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_alert),
                              onPressed: _createTestNotification,
                              tooltip: 'Test Notification',
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () async {
                                await _priceService.refreshPrice();
                              },
                              tooltip: 'Refresh Price',
                            ),
                            if (_currentPrice != null)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _currentPrice!.isPositive
                                        ? AppColors.success.withValues(alpha: 0.1)
                                        : _currentPrice!.isNegative
                                            ? AppColors.error.withValues(alpha: 0.1)
                                            : AppColors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                Icon(
                                  _currentPrice!.isPositive
                                      ? Icons.trending_up
                                      : _currentPrice!.isNegative
                                          ? Icons.trending_down
                                          : Icons.trending_flat,
                                  size: 12,
                                  color: _currentPrice!.isPositive
                                      ? AppColors.success
                                      : _currentPrice!.isNegative
                                          ? AppColors.error
                                          : AppColors.grey,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    _currentPrice!.formattedChange,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: _currentPrice!.isPositive
                                          ? AppColors.success
                                          : _currentPrice!.isNegative
                                              ? AppColors.error
                                              : AppColors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      goldPrice != null ? '₹${goldPrice.toStringAsFixed(2)}/gram' : 'Price Unavailable',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: goldPrice != null ? AppColors.primaryGold : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Last updated: ${_currentPrice?.timestamp.toString().substring(0, 16) ?? DateTime.now().toString().substring(0, 16)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _priceService.isBackendAvailable
                                ? AppColors.success.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _priceService.isBackendAvailable ? 'BACKEND LIVE' : 'UNAVAILABLE',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _priceService.isBackendAvailable
                                  ? AppColors.success
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Investment Calculator Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment Calculator',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Investment Amount',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '₹${investmentAmount.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: AppColors.grey),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Gold Quantity',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                goldPrice != null ? '${goldQuantity.toStringAsFixed(4)} grams' : 'N/A',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: goldPrice != null ? AppColors.primaryGold : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BuyGoldScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Buy Gold'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SchemesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.trending_up),
                    label: const Text('View Schemes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 1: // Portfolio
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PortfolioScreen()),
              );
              break;
            case 2: // History
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
              );
              break;
            case 3: // Profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primaryGold),
            SizedBox(width: 8),
            Text('Help & Support'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📞 Customer Support: +91 9999999999'),
            SizedBox(height: 8),
            Text('📧 Email: support@vmurugan.com'),
            SizedBox(height: 8),
            Text('🕒 Hours: 9 AM - 6 PM (Mon-Sat)'),
            SizedBox(height: 16),
            Text('💡 Quick Help:'),
            Text('• Buy Gold: Tap "Buy Gold" button'),
            Text('• View Portfolio: Use bottom navigation'),
            Text('• Transaction History: Check History tab'),
            Text('• Profile: Tap profile icon or tab'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryGold),
            SizedBox(width: 8),
            Text('About VMUrugan'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VMUrugan Gold Trading',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
              ),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Your trusted partner for digital gold investments.'),
            SizedBox(height: 16),
            Text('✨ Features:'),
            Text('• Live gold prices'),
            Text('• Secure transactions'),
            Text('• Real-time portfolio tracking'),
            Text('• 24/7 digital gold trading'),
            SizedBox(height: 16),
            Text('🏆 Licensed & Regulated'),
            Text('🔒 Bank-grade security'),
            Text('💎 Pure 24K digital gold'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _testRegistration(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing customer registration...'),
          ],
        ),
      ),
    );

    try {
      print('🧪 Starting test registration...');

      final result = await CustomerService.registerCustomer(
        phone: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Customer ${DateTime.now().hour}:${DateTime.now().minute}',
        email: 'test${DateTime.now().millisecondsSinceEpoch}@vmurugan.com',
        address: 'Test Address, Chennai, Tamil Nadu',
        panCard: 'ABCDE1234F',
        mpin: '1234',
      );

      final success = result['success'] as bool;
      final customerId = result['customer_id'] as String?;

      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text('Registration Test ${success ? 'Passed' : 'Failed'}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${success ? "✅ Success" : "❌ Failed"}'),
              const SizedBox(height: 16),
              if (success) ...[
                const Text('✅ Customer registration working!'),
                const Text('✅ Data should appear in Firebase'),
                const Text('✅ Check admin portal for test data'),
                if (customerId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text('🆔 Customer ID: $customerId'),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('📱 Check console logs for details'),
              ] else ...[
                const Text('❌ Registration failed'),
                const Text('❌ Check console logs for errors'),
                const Text('❌ Likely Firebase permission issue'),
                const SizedBox(height: 16),
                const Text('🔧 Check Firebase configuration'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Registration Test Error'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('❌ Test Registration Failed'),
              const SizedBox(height: 8),
              Text('Error: $e'),
              const SizedBox(height: 16),
              const Text('🔧 Check console logs for details'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToSchemeCreation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SchemeCreationScreen(),
      ),
    );
  }

  void _navigateToDebug(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DebugScreen(),
      ),
    );
  }

  void _createTestNotification() async {
    // Create a test notification to demonstrate the system
    await NotificationTemplates.adminMessage(
      title: 'Welcome to VMUrugan Gold Trading! 🎉',
      message: 'Thank you for choosing us for your gold investment journey. Start investing with as little as ₹100!',
      priority: NotificationPriority.normal,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification created!'),
        backgroundColor: Colors.green,
      ),
    );
  }



  void _testPlatform(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TestPlatformFix()),
    );
  }
}

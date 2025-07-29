import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../models/gold_price_model.dart';
import '../services/gold_price_service.dart';
// import '../../payment/screens/payment_screen.dart';
import '../../payment/services/upi_payment_service.dart';
import '../../payment/models/payment_model.dart';
import '../../portfolio/services/portfolio_service.dart';
import '../../portfolio/models/portfolio_model.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/customer_registration_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';

class BuyGoldScreen extends StatefulWidget {
  const BuyGoldScreen({super.key});

  @override
  State<BuyGoldScreen> createState() => _BuyGoldScreenState();
}

class _BuyGoldScreenState extends State<BuyGoldScreen> {
  final GoldPriceService _priceService = GoldPriceService();
  final UpiPaymentService _paymentService = UpiPaymentService();
  final PortfolioService _portfolioService = PortfolioService();
  final TextEditingController _amountController = TextEditingController();
  
  GoldPriceModel? _currentPrice;
  double _selectedAmount = 2000.0;
  bool _isCustomAmount = false;

  // Predefined amount options
  final List<double> _predefinedAmounts = [500, 1000, 2000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _amountController.text = _selectedAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _priceService.initialize();
    
    // Listen to price updates
    _priceService.priceStream.listen((price) {
      if (mounted) {
        setState(() {
          _currentPrice = price;
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

  @override
  Widget build(BuildContext context) {
    final goldQuantity = _currentPrice != null 
        ? _selectedAmount / _currentPrice!.pricePerGram 
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Gold'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Responsive.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Gold Price Card
            _buildGoldPriceCard(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Amount Selection Section
            _buildAmountSelectionSection(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Gold Quantity Preview
            _buildGoldQuantityPreview(goldQuantity),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Investment Summary
            _buildInvestmentSummary(goldQuantity),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Buy Button
            _buildBuyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldPriceCard() {
    if (_currentPrice == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Current Gold Price (22K)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                          size: 16,
                          color: _currentPrice!.isPositive
                              ? AppColors.success
                              : _currentPrice!.isNegative
                                  ? AppColors.error
                                  : AppColors.grey,
                        ),
                        const SizedBox(width: AppSpacing.xs),
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              _currentPrice!.formattedPrice,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'per gram • Last updated: ${_formatTime(_currentPrice!.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Investment Amount',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Predefined Amount Chips
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _predefinedAmounts.map((amount) {
            final isSelected = !_isCustomAmount && _selectedAmount == amount;
            return FilterChip(
              label: Text('₹${amount.toStringAsFixed(0)}'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedAmount = amount;
                  _isCustomAmount = false;
                  _amountController.text = amount.toStringAsFixed(0);
                });
              },
              backgroundColor: AppColors.lightGrey,
              selectedColor: AppColors.primaryGold.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryGold,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Custom Amount Input
        Row(
          children: [
            Checkbox(
              value: _isCustomAmount,
              onChanged: (value) {
                setState(() {
                  _isCustomAmount = value ?? false;
                  if (_isCustomAmount) {
                    _amountController.clear();
                  } else {
                    _amountController.text = _selectedAmount.toStringAsFixed(0);
                  }
                });
              },
              activeColor: AppColors.primaryGold,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: CustomTextField(
                label: 'Custom Amount',
                hint: 'Enter amount in ₹',
                controller: _amountController,
                keyboardType: TextInputType.number,
                enabled: _isCustomAmount,
                prefixIcon: Icons.currency_rupee,
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0.0;
                  setState(() {
                    _selectedAmount = amount;
                  });
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7), // Max 10 lakh
                ],
                validator: (value) {
                  if (_isCustomAmount) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 100) {
                      return 'Minimum amount is ₹100';
                    }
                    if (amount > 1000000) {
                      return 'Maximum amount is ₹10,00,000';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoldQuantityPreview(double goldQuantity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.diamond,
            size: 48,
            color: AppColors.white,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You will get',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${goldQuantity.toStringAsFixed(4)} grams',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'of 24K Digital Gold',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentSummary(double goldQuantity) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Investment Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSummaryRow('Investment Amount', '₹${_selectedAmount.toStringAsFixed(2)}'),
            _buildSummaryRow('Gold Price', _currentPrice?.formattedPrice ?? '₹0.00'),
            _buildSummaryRow('Gold Quantity', '${goldQuantity.toStringAsFixed(4)} grams'),
            const Divider(height: AppSpacing.lg),
            _buildSummaryRow(
              'Total Payable', 
              '₹${_selectedAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primaryGold : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyButton() {
    final isValidAmount = _selectedAmount >= 100 && _selectedAmount <= 1000000;
    final canPurchase = _priceService.canPurchase;

    return Column(
      children: [
        if (!canPurchase) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Purchases unavailable - MJDTA service not connected',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        GradientButton(
          text: canPurchase ? 'Proceed to Payment' : 'Service Unavailable',
          onPressed: (isValidAmount && canPurchase) ? _handleBuyGold : null,
          gradient: canPurchase ? AppColors.goldGreenGradient : LinearGradient(
            colors: [Colors.grey.shade400, Colors.grey.shade500],
          ),
          icon: canPurchase ? Icons.payment : Icons.warning,
          isFullWidth: true,
        ),
      ],
    );
  }

  Future<void> _handleBuyGold() async {
    // First check if MJDTA is available
    if (!_priceService.canPurchase) {
      _showMjdtaUnavailableDialog();
      return;
    }

    if (_selectedAmount < 100) {
      _showErrorDialog('Minimum investment amount is ₹100');
      return;
    }

    if (_selectedAmount > 1000000) {
      _showErrorDialog('Maximum investment amount is ₹10,00,000');
      return;
    }

    // Check if customer is registered
    final isRegistered = await CustomerService.isCustomerRegistered();
    if (!isRegistered) {
      final registered = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomerRegistrationScreen(),
        ),
      );

      if (registered != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration required to buy gold')),
        );
        return;
      }
    }

    // Navigate to payment screen
    _navigateToPayment();
  }

  Future<void> _navigateToPayment() async {
    final goldGrams = _selectedAmount / (_currentPrice?.pricePerGram ?? 1);

    // Show payment options dialog for demo
    _showPaymentOptionsDialog(goldGrams);
  }

  void _showPaymentOptionsDialog(double goldGrams) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Gold: ${goldGrams.toStringAsFixed(4)} grams (22K)'),
                  Text('Price: ₹${_currentPrice?.pricePerGram.toStringAsFixed(2) ?? '0'}/gram'),
                  Text('Total: ₹${_selectedAmount.toStringAsFixed(2)}',
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Choose Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPaymentOption('🟢 Google Pay', 'Pay with GPay', () => _processRealPayment(PaymentMethod.gpay, goldGrams)),
            const SizedBox(height: 8),
            _buildPaymentOption('🟣 PhonePe', 'Pay with PhonePe', () => _processRealPayment(PaymentMethod.phonepe, goldGrams)),
            const SizedBox(height: 8),
            _buildPaymentOption('💳 UPI Apps', 'Pay with any UPI app', () => _processRealPayment(PaymentMethod.upiIntent, goldGrams)),
            const SizedBox(height: 8),
            _buildPaymentOption('📱 QR Code', 'Scan QR to pay', () => _processRealPayment(PaymentMethod.qrCode, goldGrams)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _processRealPayment(PaymentMethod method, double goldGrams) async {
    Navigator.pop(context); // Close payment dialog

    try {
      // Create payment request with method-specific UPI ID
      final request = PaymentRequest(
        transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        amount: _selectedAmount,
        merchantName: UpiConfig.merchantName,
        merchantUpiId: UpiConfig.getUpiId(method),  // Get UPI ID based on payment method
        description: 'Gold Purchase - ${goldGrams.toStringAsFixed(3)}g',
        method: method,
      );

      // Show launching dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Launching ${method.displayName}...'),
              const SizedBox(height: 8),
              const Text('Complete payment in the app and return here',
                         style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

      PaymentResponse response;

      // Launch the appropriate payment app
      switch (method) {
        case PaymentMethod.gpay:
          response = await _paymentService.payWithGPay(request);
          break;
        case PaymentMethod.phonepe:
          response = await _paymentService.payWithPhonePe(request);
          break;
        case PaymentMethod.upiIntent:
          response = await _paymentService.payWithUpiIntent(request);
          break;
        default:
          response = PaymentResponse.failed(
            transactionId: request.transactionId,
            errorMessage: 'Payment method not supported',
          );
      }

      Navigator.pop(context); // Close launching dialog

      // Handle payment response
      if (response.status == PaymentStatus.success) {
        print('🎉 Payment successful! Creating scheme...');

        // Get customer info for scheme creation
        final customerInfo = await CustomerService.getCustomerInfo();
        final customerId = customerInfo['customer_id'];

        String? schemeId;
        if (customerId != null && customerId.isNotEmpty) {
          // Auto-create scheme for this purchase
          schemeId = await _getOrCreateAutoScheme(customerId, Map<String, String>.from(customerInfo));
          print('✅ Scheme created for payment: $schemeId');
        } else {
          print('⚠️ No customer ID found, skipping scheme creation');
        }

        // Save transaction to database (with scheme ID if available)
        await _saveTransaction(response, method.displayName, goldGrams, schemeId: schemeId);
        _showRealSuccessDialog(method.displayName, goldGrams, response, schemeId: schemeId);
      } else {
        // Create payment failed notification
        await NotificationTemplates.paymentFailed(
          transactionId: response.transactionId,
          amount: _selectedAmount,
          reason: response.errorMessage ?? 'Unknown error',
        );
        _showErrorDialog('Payment failed: ${response.errorMessage ?? 'Unknown error'}');
      }

    } catch (e) {
      Navigator.pop(context); // Close any open dialog
      _showErrorDialog('Payment error: ${e.toString()}');
    }
  }

  Future<void> _saveTransaction(PaymentResponse response, String paymentMethod, double goldGrams, {String? schemeId}) async {
    try {
      // Save to local database
      await _portfolioService.saveTransaction(
        transactionId: response.transactionId,
        type: TransactionType.BUY,
        amount: _selectedAmount,
        goldGrams: goldGrams,
        goldPricePerGram: _currentPrice?.pricePerGram ?? 0,
        paymentMethod: paymentMethod,
        status: TransactionStatus.SUCCESS,
        gatewayTransactionId: response.gatewayTransactionId,
      );

      // Save to server with customer details
      await CustomerService.saveTransactionWithCustomerData(
        transactionId: response.transactionId,
        type: 'BUY',
        amount: _selectedAmount,
        goldGrams: goldGrams,
        goldPricePerGram: _currentPrice?.pricePerGram ?? 0,
        paymentMethod: paymentMethod,
        status: 'SUCCESS',
        gatewayTransactionId: response.gatewayTransactionId ?? '',
      );

      // Log analytics event
      await CustomerService.logEvent('gold_purchase_completed', {
        'transaction_id': response.transactionId,
        'amount': _selectedAmount,
        'gold_grams': goldGrams,
        'payment_method': paymentMethod,
        'gold_price_per_gram': _currentPrice?.pricePerGram ?? 0,
      });

      // Create payment success notification
      await NotificationTemplates.paymentSuccess(
        transactionId: response.transactionId,
        amount: _selectedAmount,
        goldGrams: goldGrams,
        paymentMethod: paymentMethod,
      );

      // Create gold purchase notification
      await NotificationTemplates.goldPurchased(
        goldGrams: goldGrams,
        pricePerGram: _currentPrice?.pricePerGram ?? 0,
        totalAmount: _selectedAmount,
      );

      print('Transaction saved successfully to both local and server');
    } catch (e) {
      print('Error saving transaction: $e');
      // Don't show error to user as payment was successful
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMjdtaUnavailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Service Unavailable'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gold purchases are currently unavailable because we cannot connect to MJDTA (Madras Jewellery and Diamond Traders Association) for live gold prices.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Please try again later when the MJDTA service is available.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              'We only allow purchases with real-time MJDTA prices to ensure fair and accurate pricing.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _priceService.retryBackendConnection();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showRealSuccessDialog(String paymentMethod, double goldGrams, PaymentResponse response, {String? schemeId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Payment Initiated!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.payment,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Payment via $paymentMethod has been initiated!',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gold to Purchase: ${goldGrams.toStringAsFixed(4)} grams'),
                  Text('Amount: ₹${_selectedAmount.toStringAsFixed(2)}'),
                  Text('Transaction ID: ${response.transactionId}'),
                  if (response.gatewayTransactionId != null)
                    Text('UPI Ref: ${response.gatewayTransactionId}'),
                  if (schemeId != null)
                    Text('🆔 Scheme ID: $schemeId', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ Please verify payment status in your bank app. Gold will be added to your portfolio once payment is confirmed.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Check Payment Status'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close success dialog
              Navigator.pop(context); // Go back to main screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    final goldGrams = _selectedAmount / (_currentPrice?.pricePerGram ?? 1);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Purchase Summary:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Amount: ₹${_selectedAmount.toStringAsFixed(2)}'),
            Text('Gold: ${goldGrams.toStringAsFixed(4)} grams'),
            Text('Price: ₹${_currentPrice?.pricePerGram.toStringAsFixed(2) ?? '0'}/gram'),
            const SizedBox(height: 16),
            const Text(
              'Note: This is a demo purchase. In production, this would integrate with a payment gateway.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _completePurchase(goldGrams),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete Purchase'),
          ),
        ],
      ),
    );
  }

  Future<void> _completePurchase(double goldGrams) async {
    print('🚀 _completePurchase called!');
    print('   Gold Grams: $goldGrams');
    print('   Selected Amount: $_selectedAmount');

    try {
      // Close the dialog first
      Navigator.pop(context);

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing purchase...'),
            ],
          ),
        ),
      );

      print('📝 Step 1: Getting customer info...');
      // Get customer info
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo['customer_id'];

      print('   Customer Info: $customerInfo');
      print('   Customer ID: $customerId');

      if (customerId == null || customerId.isEmpty) {
        print('❌ No customer ID found!');
        Navigator.pop(context); // Close loading
        _showErrorDialog('Please login with a registered account to buy gold.');
        return;
      }

      print('📝 Step 2: Creating auto scheme...');
      // Auto-create or get existing scheme
      String? schemeId = await _getOrCreateAutoScheme(customerId, Map<String, String>.from(customerInfo));

      print('📝 Step 3: Checking scheme creation result...');
      print('   Scheme ID: $schemeId');

      if (schemeId == null) {
        print('❌ Scheme creation failed!');
        Navigator.pop(context); // Close loading
        _showErrorDialog('Failed to create scheme. Please try again.');
        return;
      }

      print('✅ Scheme created successfully: $schemeId');
      print('📝 Step 4: Generating transaction ID...');
      // Generate transaction ID
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      print('   Transaction ID: $transactionId');

      // Create transaction data with scheme ID
      final transactionData = {
        'transaction_id': transactionId,
        'customer_id': customerId,
        'scheme_id': schemeId,
        'amount': _selectedAmount,
        'gold_grams': goldGrams,
        'gold_price': _currentPrice?.pricePerGram ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'completed',
        'payment_method': 'Demo',
      };

      // Save transaction with customer data
      await CustomerService.saveTransactionWithCustomerData(
        transactionId: transactionId,
        type: 'BUY',
        amount: _selectedAmount,
        goldGrams: goldGrams,
        goldPricePerGram: _currentPrice?.pricePerGram ?? 0,
        paymentMethod: 'Demo',
        status: 'completed',
        gatewayTransactionId: transactionId,
      );

      // Update scheme with payment
      await _updateSchemePayment(schemeId, _selectedAmount, goldGrams);

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog with scheme info
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Purchase Successful! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'You have successfully purchased ${goldGrams.toStringAsFixed(4)} grams of gold for ₹${_selectedAmount.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🆔 Scheme Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Scheme ID: $schemeId'),
                    Text('Transaction ID: $transactionId'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close success dialog
                Navigator.pop(context); // Go back to main screen
              },
              child: const Text('View Portfolio'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Buy More'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Purchase Failed'),
          content: Text('Failed to complete purchase: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }



  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Digital Gold'),
        content: const Text(
          '• 24K pure digital gold\n'
          '• Stored securely in digital vault\n'
          '• Real-time price updates\n'
          '• Minimum investment: ₹100\n'
          '• Maximum investment: ₹10,00,000\n'
          '• Instant purchase confirmation'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Auto-create scheme for first-time buyers or get existing scheme
  Future<String?> _getOrCreateAutoScheme(String customerId, Map<String, String> customerInfo) async {
    print('🎯 _getOrCreateAutoScheme called with:');
    print('   Customer ID: $customerId');
    print('   Customer Info: $customerInfo');
    print('   Selected Amount: $_selectedAmount');

    try {
      // For now, always create a new scheme for each purchase
      // In production, you might want to check for existing active schemes

      print('📝 Step 1: Generating scheme ID...');
      // Generate scheme ID
      final schemeId = await ApiService.generateSchemeId(customerId);
      print('✅ Generated scheme ID: $schemeId');

      print('📝 Step 2: Creating scheme in Firebase...');
      // Create auto scheme with purchase amount as monthly target
      final result = await ApiService.saveScheme(
        schemeId: schemeId,
        customerId: customerId,
        customerPhone: customerInfo['phone'] ?? '',
        customerName: customerInfo['name'] ?? '',
        monthlyAmount: _selectedAmount, // Use current purchase as monthly amount
        durationMonths: 11, // Default 11 months
        schemeType: 'AUTO_GOLD_SAVINGS',
        status: 'ACTIVE',
      );

      print('📝 Step 3: Checking save result...');
      print('   Success: ${result['success']}');
      print('   Message: ${result['message']}');

      if (result['success']) {
        print('✅ Auto-created scheme: $schemeId');
        print('🎯 SCHEME SHOULD NOW BE IN FIREBASE!');
        print('   Collection: schemes');
        print('   Document ID: $schemeId');
        return schemeId;
      } else {
        print('❌ Failed to create auto scheme: ${result['message']}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating auto scheme: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Update scheme with payment
  Future<void> _updateSchemePayment(String schemeId, double amount, double goldGrams) async {
    try {
      // In production, this would update the scheme's payment progress
      // For now, we'll just log the payment
      print('💰 Payment recorded for scheme $schemeId: ₹$amount for ${goldGrams}g gold');

      // You can implement scheme payment tracking here
      // Example: Update paid_amount, paid_months, gold_accumulated in Firebase
    } catch (e) {
      print('❌ Error updating scheme payment: $e');
    }
  }

}

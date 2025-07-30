import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/customer_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> _allTransactions = [];
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'PENDING', 'SUCCESS', 'FAILED'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() async {
    print('📊 TransactionHistoryScreen: Loading transactions...');

    setState(() {
      _isLoading = true;
    });

    try {
      // Get customer info
      print('📊 Getting customer info...');
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo['customer_id'];
      print('📊 Customer ID: $customerId');

      if (customerId != null) {
        // Fetch real transactions from backend
        print('📊 Fetching transactions for customer: $customerId');
        final result = await ApiService.getCustomerTransactions(
          customerId: customerId,
          limit: 100,
        );

        print('📊 API Result: $result');

        if (result['success'] == true) {
          final transactions = List<Map<String, dynamic>>.from(result['data'] ?? []);
          print('📊 Found ${transactions.length} transactions');
          setState(() {
            _allTransactions = transactions;
          });
        } else {
          print('❌ Failed to fetch transactions: ${result['message']}');
        }
      } else {
        print('❌ No customer ID found');
      }

      // Note: Scheme payments are handled separately if needed

    } catch (e) {
      print('❌ Error loading transactions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == 'All') {
      return _allTransactions;
    }
    return _allTransactions.where((transaction) {
      return transaction['status']?.toString().toUpperCase() == _selectedFilter.toUpperCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),
          
          // Transaction Summary
          _buildTransactionSummary(),
          
          // Transaction List
          Expanded(
            child: _filteredTransactions.isEmpty 
                ? _buildEmptyState() 
                : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: AppColors.lightGrey,
              selectedColor: AppColors.primaryGold.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryGold,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionSummary() {
    final totalAmount = _filteredTransactions.fold(0.0, (sum, transaction) =>
      sum + (transaction['amount']?.toDouble() ?? 0.0));
    final totalGold = _filteredTransactions.fold(0.0, (sum, transaction) =>
      sum + (transaction['gold_grams']?.toDouble() ?? 0.0));
    
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.goldGreenGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total Invested',
              '₹${totalAmount.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Gold Purchased',
              '${totalGold.toStringAsFixed(4)}g',
              Icons.diamond,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Transactions',
              '${_filteredTransactions.length}',
              Icons.receipt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.white,
          size: 24,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final status = transaction['status']?.toString() ?? 'PENDING';
    final amount = transaction['amount']?.toDouble() ?? 0.0;
    final goldGrams = transaction['gold_grams']?.toDouble() ?? 0.0;
    final type = transaction['type']?.toString() ?? 'BUY';
    final createdAt = transaction['created_at']?.toString() ?? '';
    final transactionId = transaction['transaction_id']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTransactionIcon(status),
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gold $type',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transactionId,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Transaction Details
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Gold Quantity',
                        '${goldGrams.toStringAsFixed(3)}g',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Gold Price',
                        '₹${(transaction['gold_price_per_gram']?.toDouble() ?? 0.0).toStringAsFixed(2)}/g',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Payment Method',
                        transaction['payment_method']?.toString() ?? 'N/A',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: Responsive.getPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 60,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No Transactions Found',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your transaction history will appear here once you start investing in gold',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              text: 'Start Investing',
              onPressed: () => Navigator.pop(context),
              type: ButtonType.primary,
              icon: Icons.diamond,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return Icons.check_circle;
      case 'PENDING':
        return Icons.schedule;
      case 'FAILED':
        return Icons.error;
      default:
        return Icons.payment;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'FAILED':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transaction Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Transaction ID', transaction['transaction_id']?.toString() ?? 'N/A'),
                    _buildDetailRow('Amount', '₹${(transaction['amount']?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
                    _buildDetailRow('Gold Quantity', '${(transaction['gold_grams']?.toDouble() ?? 0.0).toStringAsFixed(3)}g'),
                    _buildDetailRow('Gold Price', '₹${(transaction['gold_price_per_gram']?.toDouble() ?? 0.0).toStringAsFixed(2)}/g'),
                    _buildDetailRow('Payment Method', transaction['payment_method']?.toString() ?? 'N/A'),
                    _buildDetailRow('Date', transaction['created_at']?.toString() ?? 'N/A'),
                    _buildDetailRow('Status', (transaction['status']?.toString() ?? 'PENDING').toUpperCase()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filterOptions.map((filter) {
            return RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _exportTransactions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Transactions'),
        content: const Text(
          'Transaction export feature will be implemented in the next update. '
          'You will be able to export your transaction history as PDF or CSV.',
        ),
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

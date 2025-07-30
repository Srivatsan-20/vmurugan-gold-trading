import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_border_radius.dart';
import '../../../core/services/api_service.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getTransactions(
        limit: 100,
        status: _selectedFilter == 'All' ? null : _selectedFilter.toUpperCase(),
      );

      if (result['success']) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(result['transactions']);
          _filteredTransactions = _transactions;
        });
        _filterTransactions('');
      } else {
        _showErrorSnackBar('Failed to load transactions: ${result['message']}');
        // No transactions available
        setState(() {
          _transactions = [];
          _filteredTransactions = [];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading transactions: $e');
      // No transactions available
      setState(() {
        _transactions = [];
        _filteredTransactions = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }



  void _filterTransactions(String query) {
    setState(() {
      var filtered = _transactions.where((txn) {
        final matchesSearch = query.isEmpty ||
            txn['customerName'].toLowerCase().contains(query.toLowerCase()) ||
            txn['id'].toLowerCase().contains(query.toLowerCase()) ||
            txn['customerPhone'].contains(query);
        
        final matchesFilter = _selectedFilter == 'All' ||
            txn['status'] == _selectedFilter ||
            txn['type'] == _selectedFilter;
        
        return matchesSearch && matchesFilter;
      }).toList();
      
      _filteredTransactions = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => _filterTransactions(value),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              DropdownButton<String>(
                value: _selectedFilter,
                items: ['All', 'COMPLETED', 'PENDING', 'FAILED', 'BUY', 'SELL']
                    .map((filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(filter),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  _filterTransactions(_searchController.text);
                },
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export feature coming soon!')),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Transaction Stats
          Row(
            children: [
              _buildStatCard('Total Transactions', _transactions.length.toString(), AppColors.info),
              const SizedBox(width: AppSpacing.lg),
              _buildStatCard('Completed', _transactions.where((t) => t['status'] == 'COMPLETED').length.toString(), AppColors.success),
              const SizedBox(width: AppSpacing.lg),
              _buildStatCard('Pending', _transactions.where((t) => t['status'] == 'PENDING').length.toString(), AppColors.warning),
              const SizedBox(width: AppSpacing.lg),
              _buildStatCard('Total Volume', '₹${_transactions.fold(0.0, (sum, t) => sum + t['amount']).toStringAsFixed(0)}', AppColors.primaryGold),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Transaction Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Gold (g)', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        
                        // Table Body
                        Expanded(
                          child: ListView.builder(
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _filteredTransactions[index];
                              return _buildTransactionRow(transaction);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> transaction) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Transaction ID
          Expanded(
            flex: 1,
            child: Text(
              transaction['id'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          
          // Customer
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['customerName'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  transaction['customerPhone'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // Type
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: transaction['type'] == 'BUY' 
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction['type'],
                style: TextStyle(
                  color: transaction['type'] == 'BUY' 
                      ? AppColors.success
                      : AppColors.info,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Amount
          Expanded(
            flex: 1,
            child: Text(
              '₹${transaction['amount'].toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          
          // Gold
          Expanded(
            flex: 1,
            child: Text(
              '${transaction['goldGrams'].toStringAsFixed(3)}g',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          
          // Payment Method
          Expanded(
            flex: 1,
            child: Text(
              transaction['paymentMethod'],
              style: const TextStyle(fontSize: 12),
            ),
          ),
          
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction['status'],
                style: TextStyle(
                  color: _getStatusColor(transaction['status']),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Date
          Expanded(
            flex: 1,
            child: Text(
              transaction['timestamp'].split(' ')[0],
              style: const TextStyle(fontSize: 11),
            ),
          ),
          
          // Actions
          Expanded(
            flex: 1,
            child: IconButton(
              icon: const Icon(Icons.visibility, size: 18),
              onPressed: () => _viewTransactionDetails(transaction),
              tooltip: 'View Details',
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return AppColors.success;
      case 'PENDING': return AppColors.warning;
      case 'FAILED': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  void _viewTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Transaction Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Transaction ID', transaction['transaction_id'] ?? transaction['id'] ?? ''),
              _buildDetailRow('Customer', '${transaction['customer_name'] ?? transaction['customerName'] ?? ''} (${transaction['customer_phone'] ?? transaction['customerPhone'] ?? ''})'),
              _buildDetailRow('Amount', '₹${(transaction['amount'] as double).toStringAsFixed(2)}'),
              _buildDetailRow('Gold Quantity', '${(transaction['gold_grams'] ?? transaction['goldGrams'] ?? 0.0).toStringAsFixed(3)} grams'),
              _buildDetailRow('Price per Gram', '₹${(transaction['gold_price_per_gram'] ?? transaction['goldPrice'] ?? 0.0).toStringAsFixed(2)}'),
              _buildDetailRow('Payment Method', transaction['payment_method'] ?? transaction['paymentMethod'] ?? ''),
              _buildDetailRow('Status', transaction['status'] ?? ''),
              _buildDetailRow('Gateway Transaction ID', transaction['gateway_transaction_id'] ?? transaction['gatewayTxnId'] ?? ''),
              _buildDetailRow('Timestamp', transaction['timestamp'] ?? ''),
              if (transaction['device_info'] != null && transaction['device_info'].toString().isNotEmpty)
                _buildDetailRow('Device Info', transaction['device_info']),
              if (transaction['location'] != null && transaction['location'].toString().isNotEmpty)
                _buildDetailRow('Location', transaction['location']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _copyTransactionId(transaction['transaction_id'] ?? transaction['id'] ?? ''),
            child: const Text('Copy ID'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _copyTransactionId(String transactionId) {
    Clipboard.setData(ClipboardData(text: transactionId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction ID copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

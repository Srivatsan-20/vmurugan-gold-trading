import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _loadCustomers() {
    // No mock data - load real customers from backend API
    _customers = [];
    _filteredCustomers = [];
    setState(() {
      _isLoading = false;
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = List.from(_customers);
      } else {
        _filteredCustomers = _customers.where((customer) {
          return customer['name'].toLowerCase().contains(query.toLowerCase()) ||
                 customer['phone'].contains(query) ||
                 customer['email'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterCustomers,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  // Export functionality
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
          
          // Customer Stats
          Row(
            children: [
              _buildStatCard('Total Customers', _customers.length.toString(), AppColors.info),
              const SizedBox(width: AppSpacing.lg),
              _buildStatCard('Verified KYC', _customers.where((c) => c['kycStatus'] == 'Verified').length.toString(), AppColors.success),
              const SizedBox(width: AppSpacing.lg),
              _buildStatCard('Pending KYC', _customers.where((c) => c['kycStatus'] == 'Pending').length.toString(), AppColors.warning),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Customer Table
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
                              Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Invested', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Gold (g)', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('KYC', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        
                        // Table Body
                        Expanded(
                          child: ListView.builder(
                            itemCount: _filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              return _buildCustomerRow(customer);
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
                fontSize: 24,
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

  Widget _buildCustomerRow(Map<String, dynamic> customer) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Customer Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Joined: ${customer['joinDate']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Contact
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer['phone']),
                Text(
                  customer['email'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Investment
          Expanded(
            flex: 1,
            child: Text(
              '₹${customer['totalInvested'].toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          
          // Gold Holdings
          Expanded(
            flex: 1,
            child: Text(
              '${customer['goldHoldings'].toStringAsFixed(2)}g',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          
          // KYC Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: customer['kycStatus'] == 'Verified' 
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                customer['kycStatus'],
                style: TextStyle(
                  color: customer['kycStatus'] == 'Verified' 
                      ? AppColors.success
                      : AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18),
                  onPressed: () => _viewCustomerDetails(customer),
                  tooltip: 'View Details',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editCustomer(customer),
                  tooltip: 'Edit',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewCustomerDetails(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Customer Details - ${customer['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${customer['phone']}'),
            Text('Email: ${customer['email']}'),
            Text('Total Invested: ₹${customer['totalInvested']}'),
            Text('Gold Holdings: ${customer['goldHoldings']}g'),
            Text('Join Date: ${customer['joinDate']}'),
            Text('KYC Status: ${customer['kycStatus']}'),
            Text('Last Transaction: ${customer['lastTransaction']}'),
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

  void _editCustomer(Map<String, dynamic> customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit customer feature coming soon!')),
    );
  }
}

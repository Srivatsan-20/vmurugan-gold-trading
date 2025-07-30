import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/database_service.dart';
import '../models/portfolio_model.dart';
import '../../gold/models/gold_price_model.dart';
import '../../gold/services/gold_price_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/customer_service.dart';

class PortfolioService {
  final DatabaseService _db = DatabaseService();

  // Get current portfolio calculated from backend transactions
  Future<Portfolio> getPortfolio() async {
    try {
      print('📊 PortfolioService: Calculating portfolio from backend transactions...');

      // Get customer info
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo['customer_id'];

      if (customerId == null) {
        print('❌ No customer ID found');
        return _getEmptyPortfolio();
      }

      // Fetch transactions from backend API
      final result = await ApiService.getCustomerTransactions(
        customerId: customerId,
        limit: 1000, // Get all transactions for portfolio calculation
      );

      if (result['success'] == true) {
        final transactionsData = List<Map<String, dynamic>>.from(result['data'] ?? []);
        print('📊 Calculating portfolio from ${transactionsData.length} transactions');

        // Calculate portfolio metrics from transactions
        double totalGoldGrams = 0.0;
        double totalInvested = 0.0;

        for (final txn in transactionsData) {
          final status = txn['status']?.toString().toUpperCase();
          final type = txn['type']?.toString().toUpperCase();
          final amount = txn['amount']?.toDouble() ?? 0.0;
          final goldGrams = txn['gold_grams']?.toDouble() ?? 0.0;

          // Only count successful transactions
          if (status == 'SUCCESS' || status == 'PENDING') {
            if (type == 'BUY' || type == 'SCHEME_PAYMENT') {
              totalGoldGrams += goldGrams;
              totalInvested += amount;
            } else if (type == 'SELL') {
              totalGoldGrams -= goldGrams;
              // For sells, subtract the original investment proportionally
              // This is a simplified calculation
            }
          }
        }

        // Get current gold price for valuation
        double currentGoldPrice = 6000.0; // Default fallback
        try {
          final priceService = GoldPriceService();
          final currentPrice = await priceService.getCurrentPrice();
          if (currentPrice != null) {
            currentGoldPrice = currentPrice.pricePerGram;
          }
        } catch (e) {
          print('Warning: Could not fetch current gold price, using default');
        }

        // Calculate current value and profit/loss
        final currentValue = totalGoldGrams * currentGoldPrice;
        final profitLoss = currentValue - totalInvested;
        final profitLossPercentage = totalInvested > 0 ? (profitLoss / totalInvested) * 100 : 0.0;

        print('📊 Portfolio calculated:');
        print('   Gold: ${totalGoldGrams.toStringAsFixed(3)}g');
        print('   Invested: ₹${totalInvested.toStringAsFixed(2)}');
        print('   Current Value: ₹${currentValue.toStringAsFixed(2)}');
        print('   P&L: ₹${profitLoss.toStringAsFixed(2)} (${profitLossPercentage.toStringAsFixed(2)}%)');

        return Portfolio(
          id: 1,
          totalGoldGrams: totalGoldGrams,
          totalInvested: totalInvested,
          currentValue: currentValue,
          profitLoss: profitLoss,
          profitLossPercentage: profitLossPercentage,
          lastUpdated: DateTime.now(),
        );
      } else {
        print('❌ Failed to fetch transactions: ${result['message']}');
        return _getEmptyPortfolio();
      }
    } catch (e) {
      print('❌ Error getting portfolio: $e');
      return _getEmptyPortfolio();
    }
  }

  // Helper method to return empty portfolio
  Portfolio _getEmptyPortfolio() {
    return Portfolio(
      id: 1,
      totalGoldGrams: 0.0,
      totalInvested: 0.0,
      currentValue: 0.0,
      profitLoss: 0.0,
      profitLossPercentage: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  // Update portfolio after successful purchase
  Future<void> addGoldPurchase({
    required double goldGrams,
    required double amountPaid,
    required double pricePerGram,
  }) async {
    try {
      final currentPortfolio = await getPortfolio();
      
      final newTotalGrams = currentPortfolio.totalGoldGrams + goldGrams;
      final newTotalInvested = currentPortfolio.totalInvested + amountPaid;
      
      // Calculate current value (will be updated when price changes)
      final currentValue = newTotalGrams * pricePerGram;
      final profitLoss = currentValue - newTotalInvested;
      final profitLossPercentage = newTotalInvested > 0 ? (profitLoss / newTotalInvested) * 100 : 0.0;

      final updatedPortfolio = {
        'total_gold_grams': newTotalGrams,
        'total_invested': newTotalInvested,
        'current_value': currentValue,
        'profit_loss': profitLoss,
        'profit_loss_percentage': profitLossPercentage,
      };

      await _db.updatePortfolio(updatedPortfolio);
      print('Portfolio updated: +${goldGrams}g gold, +₹${amountPaid}');
    } catch (e) {
      print('Error updating portfolio: $e');
      rethrow;
    }
  }

  // Update portfolio value based on current gold price
  Future<void> updatePortfolioValue(GoldPriceModel currentPrice) async {
    try {
      final portfolio = await getPortfolio();
      
      if (portfolio.totalGoldGrams > 0) {
        final currentValue = portfolio.totalGoldGrams * currentPrice.pricePerGram;
        final profitLoss = currentValue - portfolio.totalInvested;
        final profitLossPercentage = portfolio.totalInvested > 0 ? (profitLoss / portfolio.totalInvested) * 100 : 0.0;

        final updatedPortfolio = {
          'current_value': currentValue,
          'profit_loss': profitLoss,
          'profit_loss_percentage': profitLossPercentage,
        };

        await _db.updatePortfolio(updatedPortfolio);
      }
    } catch (e) {
      print('Error updating portfolio value: $e');
    }
  }

  // Save transaction
  Future<void> saveTransaction({
    required String transactionId,
    required TransactionType type,
    required double amount,
    required double goldGrams,
    required double goldPricePerGram,
    required String paymentMethod,
    required TransactionStatus status,
    String? gatewayTransactionId,
  }) async {
    try {
      final transaction = Transaction(
        transactionId: transactionId,
        type: type,
        amount: amount,
        goldGrams: goldGrams,
        goldPricePerGram: goldPricePerGram,
        paymentMethod: paymentMethod,
        status: status,
        gatewayTransactionId: gatewayTransactionId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db.insertTransaction(transaction.toMap());
      
      // If transaction is successful and it's a purchase, update portfolio
      if (status == TransactionStatus.SUCCESS && type == TransactionType.BUY) {
        await addGoldPurchase(
          goldGrams: goldGrams,
          amountPaid: amount,
          pricePerGram: goldPricePerGram,
        );
      }
      
      print('Transaction saved: ${transaction.transactionId}');
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
  }

  // Get transaction history from backend API
  Future<List<Transaction>> getTransactionHistory({int? limit}) async {
    try {
      print('📊 PortfolioService: Fetching transaction history from backend...');

      // Get customer info
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo['customer_id'];

      if (customerId == null) {
        print('❌ No customer ID found');
        return [];
      }

      // Fetch transactions from backend API
      final result = await ApiService.getCustomerTransactions(
        customerId: customerId,
        limit: limit ?? 50,
      );

      if (result['success'] == true) {
        final transactionsData = List<Map<String, dynamic>>.from(result['data'] ?? []);
        print('📊 Found ${transactionsData.length} transactions from backend');

        // Convert backend transaction format to local Transaction model
        return transactionsData.map((data) => Transaction(
          transactionId: data['transaction_id'] ?? '',
          type: _mapTransactionType(data['type']?.toString() ?? 'BUY'),
          amount: (data['amount']?.toDouble() ?? 0.0),
          goldGrams: (data['gold_grams']?.toDouble() ?? 0.0),
          goldPricePerGram: (data['gold_price_per_gram']?.toDouble() ?? 0.0),
          status: _mapTransactionStatus(data['status']?.toString() ?? 'PENDING'),
          paymentMethod: data['payment_method']?.toString() ?? 'UPI',
          gatewayTransactionId: data['gateway_transaction_id']?.toString(),
          createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
        )).toList();
      } else {
        print('❌ Failed to fetch transactions: ${result['message']}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting transaction history: $e');
      return [];
    }
  }

  // Helper method to map transaction type
  TransactionType _mapTransactionType(String type) {
    switch (type.toUpperCase()) {
      case 'BUY':
        return TransactionType.BUY;
      case 'SELL':
        return TransactionType.SELL;
      case 'SCHEME_PAYMENT':
        // Map scheme payments to BUY for now since enum doesn't have SCHEME_PAYMENT
        return TransactionType.BUY;
      default:
        return TransactionType.BUY;
    }
  }

  // Helper method to map transaction status
  TransactionStatus _mapTransactionStatus(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return TransactionStatus.SUCCESS;
      case 'PENDING':
        return TransactionStatus.PENDING;
      case 'FAILED':
        return TransactionStatus.FAILED;
      default:
        return TransactionStatus.PENDING;
    }
  }

  // Get transaction by ID
  Future<Transaction?> getTransaction(String transactionId) async {
    try {
      final transactionData = await _db.getTransactionById(transactionId);
      if (transactionData != null) {
        return Transaction.fromMap(transactionData);
      }
      return null;
    } catch (e) {
      print('Error getting transaction: $e');
      return null;
    }
  }

  // Update transaction status
  Future<void> updateTransactionStatus(String transactionId, TransactionStatus status) async {
    try {
      await _db.updateTransactionStatus(transactionId, status.toString().split('.').last);
      
      // If transaction becomes successful, update portfolio
      if (status == TransactionStatus.SUCCESS) {
        final transaction = await getTransaction(transactionId);
        if (transaction != null && transaction.type == TransactionType.BUY) {
          await addGoldPurchase(
            goldGrams: transaction.goldGrams,
            amountPaid: transaction.amount,
            pricePerGram: transaction.goldPricePerGram,
          );
        }
      }
    } catch (e) {
      print('Error updating transaction status: $e');
      rethrow;
    }
  }

  // Get portfolio summary
  Future<Map<String, dynamic>> getPortfolioSummary() async {
    try {
      final portfolio = await getPortfolio();
      final transactions = await getTransactionHistory(limit: 10);
      final summary = await _db.getTransactionSummary();
      
      return {
        'portfolio': portfolio,
        'recent_transactions': transactions,
        'summary': summary,
        'total_transactions': transactions.length,
      };
    } catch (e) {
      print('Error getting portfolio summary: $e');
      return {};
    }
  }

  // Save price history
  Future<void> savePriceHistory(GoldPriceModel price, String source) async {
    try {
      final priceHistory = PriceHistory(
        pricePer22K: price.pricePerGram,
        pricePer24K: price.pricePerGram * 1.09, // Approximate 24K price
        timestamp: DateTime.now(),
        source: source,
      );

      await _db.insertPriceHistory(priceHistory.toMap());
    } catch (e) {
      print('Error saving price history: $e');
    }
  }

  // Get price history
  Future<List<PriceHistory>> getPriceHistory({int? limit}) async {
    try {
      final priceData = await _db.getPriceHistory(limit: limit);
      return priceData.map((data) => PriceHistory.fromMap(data)).toList();
    } catch (e) {
      print('Error getting price history: $e');
      return [];
    }
  }
}

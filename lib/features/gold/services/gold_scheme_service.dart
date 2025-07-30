import 'dart:async';
import '../models/gold_scheme_model.dart';
import 'gold_price_service.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';

class GoldSchemeService {
  static final GoldSchemeService _instance = GoldSchemeService._internal();
  factory GoldSchemeService() => _instance;
  GoldSchemeService._internal();

  final GoldPriceService _priceService = GoldPriceService();
  
  // Mock user schemes (in real app, this would come from backend)
  final List<GoldSchemeModel> _userSchemes = [];

  // Initialize service
  void initialize() {
    // No sample schemes - start with empty list
  }

  // Get all user schemes
  List<GoldSchemeModel> getUserSchemes() {
    return List.unmodifiable(_userSchemes);
  }

  // Get active schemes
  List<GoldSchemeModel> getActiveSchemes() {
    return _userSchemes.where((scheme) => scheme.isActive).toList();
  }

  // Create new gold scheme
  Future<GoldSchemeModel> createScheme({
    required String userId,
    required String schemeName,
    required double monthlyAmount,
    required int totalMonths,
  }) async {
    final now = DateTime.now();
    final scheme = GoldSchemeModel(
      id: 'scheme_${now.millisecondsSinceEpoch}',
      userId: userId,
      schemeName: schemeName,
      monthlyAmount: monthlyAmount,
      totalMonths: totalMonths,
      completedMonths: 0,
      startDate: now,
      status: SchemeStatus.active,
      totalInvested: 0.0,
      totalGoldAccumulated: 0.0,
      payments: [],
      createdAt: now,
      updatedAt: now,
    );

    _userSchemes.add(scheme);
    return scheme;
  }

  // Make payment for scheme
  Future<SchemePayment> makeSchemePayment({
    required String schemeId,
    required double amount,
    required String paymentMethod,
  }) async {
    final schemeIndex = _userSchemes.indexWhere((s) => s.id == schemeId);
    if (schemeIndex == -1) {
      throw Exception('Scheme not found');
    }

    final scheme = _userSchemes[schemeIndex];
    final currentPrice = await _priceService.getCurrentPrice();

    // Check if MJDTA price is available
    if (currentPrice == null) {
      throw Exception('MJDTA price service unavailable - cannot process scheme payment');
    }

    final goldQuantity = currentPrice.calculateGoldQuantity(amount);
    
    final payment = SchemePayment(
      id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
      schemeId: schemeId,
      amount: amount,
      goldPrice: currentPrice.pricePerGram,
      goldQuantity: goldQuantity,
      paymentDate: DateTime.now(),
      paymentMethod: paymentMethod,
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      status: 'completed',
    );

    // Update scheme
    final updatedPayments = [...scheme.payments, payment];
    final updatedScheme = scheme.copyWith(
      completedMonths: scheme.completedMonths + 1,
      totalInvested: scheme.totalInvested + amount,
      totalGoldAccumulated: scheme.totalGoldAccumulated + goldQuantity,
      payments: updatedPayments,
      updatedAt: DateTime.now(),
      status: scheme.completedMonths + 1 >= scheme.totalMonths 
          ? SchemeStatus.completed 
          : SchemeStatus.active,
      endDate: scheme.completedMonths + 1 >= scheme.totalMonths 
          ? DateTime.now() 
          : null,
    );

    _userSchemes[schemeIndex] = updatedScheme;

    // Create scheme payment notification
    await NotificationTemplates.schemePayment(
      schemeName: scheme.schemeName,
      amount: amount,
      monthNumber: scheme.completedMonths + 1,
      totalMonths: scheme.totalMonths,
    );

    return payment;
  }

  // Get scheme by ID
  GoldSchemeModel? getSchemeById(String schemeId) {
    try {
      return _userSchemes.firstWhere((scheme) => scheme.id == schemeId);
    } catch (e) {
      return null;
    }
  }

  // Calculate scheme performance
  Map<String, dynamic>? calculateSchemePerformance(String schemeId) {
    final scheme = getSchemeById(schemeId);
    if (scheme == null) return null;

    final currentPrice = _priceService.currentPrice?.pricePerGram;
    if (currentPrice == null) {
      // Return null if MJDTA price is not available
      return null;
    }
    final currentValue = scheme.totalGoldAccumulated * currentPrice;
    final totalGain = currentValue - scheme.totalInvested;
    final gainPercentage = scheme.totalInvested > 0 
        ? (totalGain / scheme.totalInvested) * 100 
        : 0.0;

    // Calculate average purchase price
    double averagePurchasePrice = 0.0;
    if (scheme.payments.isNotEmpty) {
      final totalAmount = scheme.payments.fold(0.0, (sum, payment) => sum + payment.amount);
      final totalGold = scheme.payments.fold(0.0, (sum, payment) => sum + payment.goldQuantity);
      averagePurchasePrice = totalGold > 0 ? totalAmount / totalGold : 0.0;
    }

    return {
      'currentValue': currentValue,
      'totalGain': totalGain,
      'gainPercentage': gainPercentage,
      'averagePurchasePrice': averagePurchasePrice,
      'currentPrice': currentPrice,
      'priceAppreciation': averagePurchasePrice > 0 
          ? ((currentPrice - averagePurchasePrice) / averagePurchasePrice) * 100 
          : 0.0,
    };
  }

  // Get upcoming payments
  List<Map<String, dynamic>> getUpcomingPayments() {
    final upcomingPayments = <Map<String, dynamic>>[];
    
    for (final scheme in _userSchemes) {
      if (scheme.isActive && !scheme.isCompleted) {
        upcomingPayments.add({
          'schemeId': scheme.id,
          'schemeName': scheme.schemeName,
          'amount': scheme.monthlyAmount,
          'dueDate': scheme.nextPaymentDate,
          'daysUntilDue': scheme.nextPaymentDate.difference(DateTime.now()).inDays,
        });
      }
    }

    // Sort by due date
    upcomingPayments.sort((a, b) => 
        (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));

    return upcomingPayments;
  }

  // Pause scheme
  Future<void> pauseScheme(String schemeId) async {
    final schemeIndex = _userSchemes.indexWhere((s) => s.id == schemeId);
    if (schemeIndex != -1) {
      _userSchemes[schemeIndex] = _userSchemes[schemeIndex].copyWith(
        status: SchemeStatus.paused,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Resume scheme
  Future<void> resumeScheme(String schemeId) async {
    final schemeIndex = _userSchemes.indexWhere((s) => s.id == schemeId);
    if (schemeIndex != -1) {
      _userSchemes[schemeIndex] = _userSchemes[schemeIndex].copyWith(
        status: SchemeStatus.active,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Cancel scheme
  Future<void> cancelScheme(String schemeId) async {
    final schemeIndex = _userSchemes.indexWhere((s) => s.id == schemeId);
    if (schemeIndex != -1) {
      _userSchemes[schemeIndex] = _userSchemes[schemeIndex].copyWith(
        status: SchemeStatus.cancelled,
        updatedAt: DateTime.now(),
      );
    }
  }


}

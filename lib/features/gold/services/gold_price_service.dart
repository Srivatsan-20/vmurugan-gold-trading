import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gold_price_model.dart';

class GoldPriceService {
  static final GoldPriceService _instance = GoldPriceService._internal();
  factory GoldPriceService() => _instance;
  GoldPriceService._internal();

  // Stream controller for real-time price updates
  final StreamController<GoldPriceModel?> _priceController = StreamController<GoldPriceModel?>.broadcast();
  Stream<GoldPriceModel?> get priceStream => _priceController.stream;

  // Current price cache
  GoldPriceModel? _currentPrice;
  Timer? _priceUpdateTimer;

  // Backend API service - our primary price source
  bool _isBackendAvailable = false;
  DateTime? _lastBackendCheck;

  // Initialize the service
  void initialize() {
    _loadInitialPrice();
    _startPriceUpdates();
  }

  // Dispose resources
  void dispose() {
    _priceUpdateTimer?.cancel();
    _priceController.close();
  }

  // Get current gold price
  GoldPriceModel? get currentPrice => _currentPrice;

  // Get current price as Future
  Future<GoldPriceModel?> getCurrentPrice() async {
    if (_currentPrice == null) {
      await _loadInitialPrice();
    }
    return _currentPrice;
  }

  // Start real-time price updates
  void _startPriceUpdates() {
    // Update every 2 minutes for live API calls (to avoid rate limiting)
    _priceUpdateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _updatePrice();
    });
  }

  // Load initial price from backend API
  Future<void> _loadInitialPrice() async {
    try {
      print('GoldPriceService: Loading initial price from backend API...');

      final backendPrice = await _fetchGoldPriceFromBackend();
      if (backendPrice != null) {
        print('GoldPriceService: Successfully loaded price from backend: ${backendPrice.formattedPrice}');
        _currentPrice = backendPrice;
        _isBackendAvailable = true;
        _lastBackendCheck = DateTime.now();
        _priceController.add(_currentPrice);
      } else {
        print('GoldPriceService: Backend unavailable - no price data available');
        _currentPrice = null;
        _isBackendAvailable = false;
        _lastBackendCheck = DateTime.now();
        _priceController.add(null);
      }
    } catch (e) {
      print('GoldPriceService: Error loading initial price: $e');
      _currentPrice = null;
      _isBackendAvailable = false;
      _lastBackendCheck = DateTime.now();
      _priceController.add(null);
    }
  }



  // Update price from backend API
  Future<void> _updatePrice() async {
    try {
      // Check if we should retry backend (every 5 minutes if it was down)
      final shouldRetryBackend = !_isBackendAvailable &&
          _lastBackendCheck != null &&
          DateTime.now().difference(_lastBackendCheck!).inMinutes >= 5;

      if (_isBackendAvailable || shouldRetryBackend) {
        print('GoldPriceService: Fetching updated price from backend API...');

        final backendPrice = await _fetchGoldPriceFromBackend();
        if (backendPrice != null) {
          print('GoldPriceService: Successfully updated price from backend: ${backendPrice.formattedPrice}');
          _currentPrice = backendPrice;
          _isBackendAvailable = true;
          _lastBackendCheck = DateTime.now();
          _priceController.add(_currentPrice);
        } else {
          print('GoldPriceService: Backend still unavailable');
          _currentPrice = null;
          _isBackendAvailable = false;
          _lastBackendCheck = DateTime.now();
          _priceController.add(null);
        }
      }
    } catch (e) {
      print('GoldPriceService: Error updating price: $e');
      _currentPrice = null;
      _isBackendAvailable = false;
      _lastBackendCheck = DateTime.now();
      _priceController.add(null);
    }
  }



  // Manual price refresh
  Future<GoldPriceModel?> refreshPrice() async {
    await _updatePrice();
    return _currentPrice;
  }

  // Get backend availability status
  bool get isBackendAvailable => _isBackendAvailable;

  // Get price source description
  String get priceSource {
    if (_isBackendAvailable) {
      return 'Backend API - Live Gold Price';
    } else {
      return 'Backend Unavailable - No Price Data';
    }
  }

  // Force backend retry
  Future<void> retryBackendConnection() async {
    await _updatePrice();
  }

  // Fetch gold price from backend API
  Future<GoldPriceModel?> _fetchGoldPriceFromBackend() async {
    try {
      print('GoldPriceService: Calling backend API for gold price...');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/gold/price'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          print('GoldPriceService: Successfully received price data from backend');
          return GoldPriceModel.fromJson(data['data']);
        }
      }

      print('GoldPriceService: Backend API returned error: ${response.statusCode}');
      return null;
    } catch (e) {
      print('GoldPriceService: Error calling backend API: $e');
      return null;
    }
  }

  // Check if purchases are allowed (only when backend is available)
  bool get canPurchase => _isBackendAvailable && _currentPrice != null;

  // Get historical prices (only available when backend is working)
  Future<List<GoldPriceModel>> getHistoricalPrices({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Return empty list if backend is not available
    if (!_isBackendAvailable || _currentPrice == null) {
      return [];
    }

    // Historical data would typically come from backend API
    // For now, return empty list as we only support real-time data
    return [];
  }

  // Calculate investment scenarios (only available when MJDTA is working)
  Map<String, dynamic>? calculateInvestmentScenario({
    required double monthlyAmount,
    required int months,
  }) {
    // Return null if backend is not available
    if (!_isBackendAvailable || _currentPrice == null) {
      return null;
    }

    final currentPrice = _currentPrice!.pricePerGram;
    final totalInvestment = monthlyAmount * months;

    // Simulate average price over the period (with slight appreciation)
    final averagePrice = currentPrice * (1 + (0.05 * months / 12)); // 5% annual appreciation
    final totalGoldQuantity = totalInvestment / averagePrice;

    // Calculate potential returns
    final futurePrice = currentPrice * (1 + (0.08 * months / 12)); // 8% annual appreciation
    final futureValue = totalGoldQuantity * futurePrice;
    final potentialGain = futureValue - totalInvestment;
    final potentialGainPercent = (potentialGain / totalInvestment) * 100;

    return {
      'totalInvestment': totalInvestment,
      'averagePrice': averagePrice,
      'totalGoldQuantity': totalGoldQuantity,
      'currentValue': totalGoldQuantity * currentPrice,
      'futureValue': futureValue,
      'potentialGain': potentialGain,
      'potentialGainPercent': potentialGainPercent,
    };
  }

  // Get price alerts (for future implementation)
  Future<void> setPriceAlert({
    required double targetPrice,
    required String alertType, // 'above' or 'below'
  }) async {
    // TODO: Implement price alerts
    // This would typically involve backend integration
  }
}

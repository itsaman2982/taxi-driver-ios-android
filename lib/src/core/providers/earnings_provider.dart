
import 'package:flutter/material.dart';
import 'package:taxi_driver/src/core/api/api_service.dart';

class EarningsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic> _earningsData = {};
  List<dynamic> _transactions = [];
  Map<String, dynamic> _payoutConfig = {};
  List<dynamic> _payoutMethods = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> get earningsData => _earningsData;
  List<dynamic> get transactions => _transactions;
  Map<String, dynamic> get payoutConfig => _payoutConfig;
  List<dynamic> get payoutMethods => _payoutMethods;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get todayEarnings => (_earningsData['today'] ?? 0).toDouble();
  double get weekEarnings => (_earningsData['week'] ?? 0).toDouble();
  double get monthEarnings => (_earningsData['month'] ?? 0).toDouble();
  double get totalEarnings => (_earningsData['total'] ?? 0).toDouble();

  // Fetch earnings summary
  Future<void> fetchEarnings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch earnings data
      final response = await _apiService.get('drivers/earnings');
      if (response is Map && response['success'] == true) {
        _earningsData = response['data'] ?? {};
      } else {
        _earningsData = {};
      }
      // driverType comes from the driver profile (via DriverProvider.refreshProfile), 
      // so we just set a sensible default here to avoid a duplicate API call.
      _earningsData['driverType'] ??= 'commission';
    } catch (e) {
      _error = e.toString();
      _earningsData = {'driverType': 'commission'};
      debugPrint('❌ Error fetching earnings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch transaction history
  Future<void> fetchTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('transactions');
      if (response is Map && response['success'] == true) {
        _transactions = response['data'] ?? [];
      } else {
        _transactions = [];
      }
    } catch (e) {
      _error = e.toString();
      _transactions = [];
      debugPrint('❌ Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch payout config
  Future<void> fetchPayoutConfig() async {
    try {
      final response = await _apiService.get('payouts/config');
      if (response is Map && response['success'] == true) {
        _payoutConfig = response['data'] ?? {};
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error fetching payout config: $e');
    }
  }

  // Fetch driver's payout methods
  Future<void> fetchPayoutMethods() async {
    try {
      final response = await _apiService.get('payouts/methods');
      if (response is Map && response['success'] == true) {
        _payoutMethods = response['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error fetching payout methods: $e');
    }
  }

  // Request withdrawal
  Future<bool> requestWithdrawal(double amount, String methodId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post('payouts/request', {
        'amount': amount,
        'methodId': methodId,
      });
      _isLoading = false;
      notifyListeners();
      return response['success'] == true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

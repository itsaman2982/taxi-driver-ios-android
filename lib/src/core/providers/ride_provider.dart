
import 'package:flutter/material.dart';
import 'package:taxi_driver/src/core/api/api_service.dart';
import 'package:taxi_driver/src/core/utils/app_logger.dart';

class RideProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _activeRides = [];
  List<dynamic> _rideHistory = [];
  Map<String, dynamic>? _currentRide;
  bool _isLoading = false;
  String? _error;

  List<dynamic> get activeRides => _activeRides;
  List<dynamic> get rideHistory => _rideHistory;
  Map<String, dynamic>? get currentRide => _currentRide;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch active rides for driver
  Future<void> fetchActiveRides() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('rides/driver/active');
      if (response is Map && response['success'] == true) {
        _activeRides = response['data'] ?? [];
      } else {
        _activeRides = [];
      }
    } catch (e) {
      _error = e.toString();
      _activeRides = [];
      AppLogger.error('Error fetching active rides', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch ride history
  Future<void> fetchRideHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('rides/driver/history');
      if (response is Map && response['success'] == true) {
        _rideHistory = response['data'] ?? [];
      } else {
        _rideHistory = [];
      }
    } catch (e) {
      _error = e.toString();
      _rideHistory = [];
      AppLogger.error('Error fetching ride history', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Accept a ride
  Future<bool> acceptRide(String rideId) async {
    try {
      final response = await _apiService.post('rides/$rideId/accept', {});
      if (response is Map && response['success'] == true) {
        _currentRide = response['data'];
        await fetchActiveRides();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error accepting ride', e);
      return false;
    }
  }

  // Update ride status
  Future<bool> updateRideStatus(String rideId, String status) async {
    try {
      final response = await _apiService.patch('rides/$rideId', {'status': status});
      if (response is Map && response['success'] == true) {
        await fetchActiveRides();
        if (status == 'completed') {
          _currentRide = null;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error updating ride status', e);
      return false;
    }
  }

  void setCurrentRide(Map<String, dynamic>? ride) {
    _currentRide = ride;
    notifyListeners();
  }
}



import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver/src/core/api/api_service.dart';
import 'package:taxi_driver/src/core/services/socket_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DriverProvider extends ChangeNotifier {
  Map<String, dynamic>? _driver;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  final SocketService _socketService = SocketService();

  Map<String, dynamic>? get driver => _driver;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  IO.Socket? get socket => _socketService.socket;
  
  // Driver type helpers
  String get driverType => _driver?['driverType'] ?? 'commission';
  bool get isCommissionBased => driverType == 'commission';
  bool get isSalaryBased => driverType == 'salary';
  bool get isFleetDriver => driverType == 'fleet' || driverType == 'salary' || _driver?['vehicleId'] != null;

  DriverProvider() {
    _loadDriver();
  }

  Future<void> _loadDriver() async {
    final prefs = await SharedPreferences.getInstance();
    final driverStr = prefs.getString('driver');
    if (driverStr != null) {
      _driver = jsonDecode(driverStr);
      _isLoggedIn = true;
      final token = _driver!['token'] ?? _driver!['_id'] ?? _driver!['id'];
      if (token != null) {
        ApiService().setToken(token.toString());
      }
      
      // Connect socket on app startup
      final driverId = _driver!['_id'] ?? _driver!['id'];
      if (driverId != null) {
        _socketService.connect(driverId.toString());
        // Also check for current ride to join room
        checkCurrentRide().then((ride) {
          if (ride != null && ride['_id'] != null) {
            _socketService.joinRideRoom(ride['_id'].toString());
          }
        });
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setDriver(Map<String, dynamic> driverData) async {
    if (driverData.containsKey('_id') && !driverData.containsKey('id')) {
      driverData['id'] = driverData['_id'];
    }
    _driver = driverData;
    _isLoggedIn = true;
    
    final token = driverData['token'] ?? driverData['_id'] ?? driverData['id'];
    if (token != null) {
      ApiService().setToken(token.toString());
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver', jsonEncode(driverData));
    
    // Connect socket with driver ID
    final driverId = driverData['_id'] ?? driverData['id'];
    if (driverId != null) {
      _socketService.connect(driverId.toString());
    }
    
    notifyListeners();
  }

  Future<void> logout() async {
    _driver = null;
    _isLoggedIn = false;
    ApiService().clearToken();
    
    // Disconnect socket
    _socketService.disconnect();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('driver');
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final response = await ApiService().get('users/me');
      if (response is Map && response['success'] == true) {
        final Map<String, dynamic> driverData = Map<String, dynamic>.from(response['data'] ?? {});
        await setDriver(driverData);
      }
    } catch (e) {
      print('❌ Error refreshing driver profile: $e');
    }
  }

  Future<void> toggleOnlineStatus(bool isOnline) async {
    try {
      final response = await ApiService().put('users/online-status', {
        'isOnline': isOnline,
      });
      
      if (response is Map && response['success'] == true) {
        // Update local driver data
        if (_driver != null) {
          _driver!['isOnline'] = isOnline;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('driver', jsonEncode(_driver));
          notifyListeners();
        }
        print('✅ Online status updated: $isOnline');
      }
    } catch (e) {
      print('❌ Error updating online status: $e');
    }
  }

  DateTime? _lastHttpUpdate;

  Future<void> updateLocation(double lat, double lng, {double? heading, double? speed}) async {
    try {
      final payload = {
        'lat': lat,
        'lng': lng,
        'heading': heading ?? 0.0,
        'speed': speed ?? 0.0,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 1. Emit via socket for real-time (FAST, NO THROTTLE)
      if (_socketService.socket?.connected == true) {
        _socketService.emit('update_location', payload);
      }
      
      // 2. Fallback/Sync with HTTP (THROTTLED to every 5s)
      final now = DateTime.now();
      if (_lastHttpUpdate == null || now.difference(_lastHttpUpdate!) > const Duration(seconds: 5)) {
        _lastHttpUpdate = now;
        await ApiService().post('drivers/location', payload);
      }
    } catch (e) {
      print('❌ Error updating location: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchPendingRide() async {
    try {
      // Endpoint to get nearest pending ride
      final res = await ApiService().get('rides/pending'); 
      if (res is Map && res['success'] == true) {
        final List<dynamic> list = res['data'] ?? [];
        if (list.isNotEmpty) return list.first;
      }
    } catch (e) {
      print('Error fetching pending ride: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> checkCurrentRide() async {
    try {
      final res = await ApiService().get('rides/current');
      if (res is Map && res['success'] == true && res['data'] != null) {
        return res['data'];
      }
    } catch (e) {
      print('Error checking current ride: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> acceptRide(String rideId) async {
    try {
      final res = await ApiService().post('rides/$rideId/accept', {});
      if (res is Map && res['success'] == true) {
        final ride = res['data'];
        if (ride != null && ride['_id'] != null) {
           _socketService.joinRideRoom(ride['_id'].toString());
        }
        return ride;
      }
    } catch (e) {
      print('Error accepting ride: $e');
    }
    return null;
  }

  Future<bool> acceptEmergency(String breakdownId) async {
    try {
      final res = await ApiService().post('breakdowns/$breakdownId/accept-emergency', {});
      return res['success'] == true;
    } catch (e) {
      print('Error accepting emergency: $e');
      return false;
    }
  }

  Future<bool> arrivedAtBreakdown(String breakdownId) async {
    try {
      final res = await ApiService().post('breakdowns/$breakdownId/arrived', {});
      return res['success'] == true;
    } catch (e) {
      print('Error reporting arrival at breakdown: $e');
      return false;
    }
  }

  Future<bool> updateRideStatus(String rideId, String status) async {
    try {
      final res = await ApiService().post('rides/$rideId/status', {'status': status});
      return res['success'] == true;
    } catch (e) {
      print('Error updating status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> completeRide(String rideId, {String paymentMethod = 'cash'}) async {
    try {
      final res = await ApiService().post('rides/$rideId/complete', {
        'paymentMethod': paymentMethod,
      });
      if (res['success'] == true) {
        // Refresh earnings data in background or notify
        return res['data']['ride'];
      }
      return null;
    } catch (e) {
      print('Error completing ride: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> reportBreakdown(String rideId, double lat, double lng, String notes) async {
    try {
      final res = await ApiService().post('breakdowns/report', {
        'rideId': rideId,
        'lat': lat,
        'lng': lng,
        'notes': notes,
      });
      if (res['success'] == true) {
        return res['data'];
      }
      return null;
    } catch (e) {
      print('❌ Error reporting breakdown: $e');
      return null;
    }
  }
  Future<bool> cancelBreakdown(String rideId) async {
    try {
      final res = await ApiService().post('breakdowns/ride/$rideId/cancel', {});
      return res['success'] == true;
    } catch (e) {
      print('❌ Error cancelling breakdown: $e');
      return false;
    }
  }
}

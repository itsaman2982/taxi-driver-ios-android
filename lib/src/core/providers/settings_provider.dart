import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _rideRequestSound = true;
  bool _messageSound = true;
  bool _vibration = true;
  
  String _language = 'English (US)';
  String _navigationApp = 'Google Maps';
  String _mapDisplay = 'Standard, 3D View';
  String _units = 'Kilometers';

  bool get rideRequestSound => _rideRequestSound;
  bool get messageSound => _messageSound;
  bool get vibration => _vibration;
  
  String get language => _language;
  String get navigationApp => _navigationApp;
  String get mapDisplay => _mapDisplay;
  String get units => _units;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _rideRequestSound = prefs.getBool('rideRequestSound') ?? true;
    _messageSound = prefs.getBool('messageSound') ?? true;
    _vibration = prefs.getBool('vibration') ?? true;
    
    _language = prefs.getString('language') ?? 'English (US)';
    _navigationApp = prefs.getString('navigationApp') ?? 'Google Maps';
    _mapDisplay = prefs.getString('mapDisplay') ?? 'Standard, 3D View';
    _units = prefs.getString('units') ?? 'Kilometers';
    
    notifyListeners();
  }

  Future<void> setRideRequestSound(bool value) async {
    _rideRequestSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rideRequestSound', value);
    notifyListeners();
  }

  Future<void> setMessageSound(bool value) async {
    _messageSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('messageSound', value);
    notifyListeners();
  }

  Future<void> setVibration(bool value) async {
    _vibration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> setNavigationApp(String value) async {
    _navigationApp = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('navigationApp', value);
    notifyListeners();
  }

  Future<void> setMapDisplay(String value) async {
    _mapDisplay = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mapDisplay', value);
    notifyListeners();
  }

  Future<void> setUnits(String value) async {
    _units = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('units', value);
    notifyListeners();
  }
}

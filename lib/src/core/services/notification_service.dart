import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:taxi_driver/src/core/utils/app_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isPlaying = false;

  Future<void> init() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      // On Android 14+, fullScreenIntent requires explicit user permission if not a dialer
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> showLocalNotification({required String title, required String body, bool isEmergency = false}) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      isEmergency ? 'emergency_channel_v2' : 'request_channel_v2',
      isEmergency ? 'Emergency Alerts' : 'Ride Requests',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'New Ride Request',
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: '<b>$title</b>',
        htmlFormatContentTitle: true,
        summaryText: isEmergency ? '<i>Emergency Action Needed</i>' : '<i>Tap to Open Driver App</i>',
        htmlFormatSummaryText: true,
      ),
      color: isEmergency ? const Color(0xFFD32F2F) : const Color(0xFF00C853),
      colorized: true,
    );
    
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBadge: true),
    );

    await _notificationsPlugin.show(
      isEmergency ? 911 : 100,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> playRideRequestSound({bool isEmergency = false}) async {
    if (_isPlaying) return;
    
    _isPlaying = true;
    
    // Play sound in app using just_audio
    try {
      final soundPath = isEmergency ? 'assets/sounds/emergency_alert.mp3' : 'assets/sounds/request_alert.mp3';
      await _audioPlayer.setAsset(soundPath);
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      AppLogger.error('just_audio play error', e);
    }

    // Vibrate
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [500, 1000], repeat: 0);
    }

    // Also show a local notification
    try {
      await showLocalNotification(
        title: isEmergency ? '🚨 EMERGENCY REQUEST' : '🚖 NEW RIDE REQUEST',
        body: isEmergency 
          ? 'A breakdown has occurred. Action required immediately!' 
          : 'A new passenger is looking for a ride.',
        isEmergency: isEmergency,
      );
    } catch (e) {
      AppLogger.error('local_notifications error', e);
    }
  }

  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      await Vibration.cancel();
      _isPlaying = false;
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      AppLogger.error('Error stopping notification', e);
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}


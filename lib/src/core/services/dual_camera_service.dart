import 'dart:io';
import 'package:flutter/services.dart';
import 'package:taxi_driver/src/core/utils/app_logger.dart';

class DualCameraService {
  static const MethodChannel _channel = MethodChannel('com.example.dual_camera');

  int? backTextureId;
  int? frontTextureId;
  int? compositeTextureId;

  Future<bool> isMultiCamSupported() async {
    if (!Platform.isIOS) return false;
    try {
      final bool supported = await _channel.invokeMethod('isMultiCamSupported');
      return supported;
    } catch (e) {
      return false;
    }
  }

  Future<Map?> getDualCameraStatus() async {
    if (!Platform.isIOS) return null;
    try {
      final Map? status = await _channel.invokeMethod('getDualCameraStatus');
      return status;
    } catch (e) {
      return null;
    }
  }

  Future<bool> startDualCamera() async {
    if (!Platform.isIOS) return false;
    try {
      final Map? result = await _channel.invokeMethod('startDualCamera');
      if (result != null) {
        backTextureId = result['backTextureId'];
        frontTextureId = result['frontTextureId'];
        compositeTextureId = result['compositeTextureId'];
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error starting dual camera', e);
      return false;
    }
  }

  Future<void> stopDualCamera() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('stopDualCamera');
      backTextureId = null;
      frontTextureId = null;
      compositeTextureId = null;
    } catch (e) {
      AppLogger.error('Error stopping dual camera', e);
    }
  }

  void onFrame(Function(Uint8List) callback) {
    ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
      'com.example.dual_camera/frames',
      (ByteData? message) async {
        if (message != null) {
          callback(message.buffer.asUint8List());
        }
        return null;
      },
    );
  }
}

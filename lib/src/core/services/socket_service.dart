import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:taxi_driver/src/core/api/api_service.dart';
import 'package:taxi_driver/src/core/utils/app_logger.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  io.Socket? get socket => _socket;

  void connect(String driverId) {
    if (_socket != null && _socket!.connected) {
      AppLogger.info('Socket already connected');
      return;
    }

    // Remove '/api/' from baseUrl for socket connection
    final baseUrl = ApiService.baseUrl.replaceAll('/api/', '');
    
    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'driver-id': driverId})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      AppLogger.info('Driver socket connected');
      // Join driver-specific room
      _socket!.emit('join_room', 'driver_$driverId');
      // Join global driver room for fallback broadcasts
      _socket!.emit('join_room', 'drivers_global');
    });

    _socket!.onDisconnect((_) {
      AppLogger.warning('Driver socket disconnected');
    });

    _socket!.onError((error) {
      AppLogger.error('Socket error', error);
    });

    _socket!.onConnectError((error) {
       AppLogger.error('Socket connection error', error);
    });
  }

  void joinRideRoom(String rideId) {
    if (_socket != null && _socket!.connected) {
       AppLogger.info('[SOCKET] Joining Ride Room: ride_$rideId');
       _socket!.emit('join_room', 'ride_$rideId');
    }
  }

  void leaveRideRoom(String rideId) {
    if (_socket != null && _socket!.connected) {
       _socket!.emit('leave_room', 'ride_$rideId');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      AppLogger.info('Socket disconnected and disposed');
    }
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    } else {
      AppLogger.warning('Cannot emit $event: Socket not connected');
    }
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }
}


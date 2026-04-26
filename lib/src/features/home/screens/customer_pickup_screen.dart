import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/api/api_service.dart';
import 'package:taxi_driver/src/core/providers/driver_provider.dart';
import 'package:taxi_driver/src/features/home/screens/trip_completed_screen.dart';
import 'package:taxi_driver/src/features/home/screens/warehouse_return_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:taxi_driver/src/core/map/mappls_service.dart';
import 'package:taxi_driver/src/core/utils/app_logger.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomerPickupScreen extends StatefulWidget {
  final Map<String, dynamic> ride;
  const CustomerPickupScreen({super.key, required this.ride});

  @override
  State<CustomerPickupScreen> createState() => _CustomerPickupScreenState();
}

class _CustomerPickupScreenState extends State<CustomerPickupScreen> with WidgetsBindingObserver {
  static const Set<String> _ignoredTrackingTypes = {
    'driver',
    'active_driver',
    'original_driver',
    'current_driver',
    'vehicle',
  };

  String? _extractId(dynamic id) {
    if (id == null) return null;
    if (id is String) return id;
    if (id is List && id.isNotEmpty) return _extractId(id[0]);
    if (id is Map) {
      if (id.containsKey('\$oid')) return id['\$oid'].toString();
      if (id.containsKey('_id')) return _extractId(id['_id']);
      if (id.containsKey('id')) return _extractId(id['id']);
      if (id.values.isNotEmpty) {
         for (var v in id.values) {
            if (v is String && v.length == 24) return v;
         }
      }
      return id.toString();
    }
    return id.toString();
  }

  String _status = 'accepted'; 
  bool _breakdownResolvedOverride = false;
  Map<String, dynamic> _rideData = {};
  LatLng currentLocation = const LatLng(23.0225, 72.5714); 
  double _currentHeading = 0.0;
  MapplsMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  bool _isFirstLocation = true;
  List<LatLng> _routePoints = [];
  List<Map<String, dynamic>> _trafficSegments = [];
  List<LatLng> _altRoutePoints = [];
  String _routeEta = '';
  String _routeDistance = '';
  final Map<String, LatLng> _trackingEntities = {};
  bool _mapStyleReady = false;
  Symbol? _driverSymbol;
  Circle? _driverHaloCircle;
  Symbol? _pickupSymbol;
  Symbol? _dropSymbol;
  final Map<String, Symbol> _trackingSymbols = {};
  Line? _routeLine;
  Line? _altRouteLine;
  final List<Line> _trafficLines = [];
  bool _followDriver = false;
  bool _fitRouteOnNextUpdate = true;
  DateTime _lastCameraMoveAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _isReplacementDriver {
    final driverData = Provider.of<DriverProvider>(context, listen: false).driver;
    if (driverData == null) return false;

    final myId = _extractId(driverData['_id']) ?? _extractId(driverData['id']);
    final rideReplacementId = _extractId(_rideData['replacementDriverId'] ?? widget.ride['replacementDriverId']);
    
    if (myId != null && rideReplacementId != null && myId == rideReplacementId) {
      return true;
    }

    final bool isEmergency = ((_rideData['isEmergency'] ?? widget.ride['isEmergency']) == true) || 
                             ((_rideData['is_emergency'] ?? widget.ride['is_emergency']) == true) ||
                             ((_rideData['type'] ?? widget.ride['type']) == 'emergency');
                             
    final originalDriverId = _extractId(_rideData['driverId'] ?? widget.ride['driverId']);
    if (isEmergency && myId != null && originalDriverId != null && myId != originalDriverId) {
      return true;
    }

    return false;
  }
  
  MediaStream? _interiorStream;
  MediaStream? _frontRoadStream;
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, DateTime> _lastNativeConnectionRequest = {};
  
  MediaRecorder? _roadRecorder;
  MediaRecorder? _interiorRecorder;
  bool _isRecording = false;

  // Native front camera MethodChannel (iOS only)
  static const _nativeFrontCam = MethodChannel('com.taxi.native_front_camera');
  bool _nativeFrontCamStarted = false;

  @override
  void initState() {
    super.initState();
    _rideData = Map<String, dynamic>.from(widget.ride);
    
    if (_rideData['status'] != null && _rideData['status'].isNotEmpty) {
      _status = _rideData['status'];
    } else {
      _status = 'accepted';
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.ride['driverLat'] != null && widget.ride['driverLng'] != null) {
        setState(() {
          currentLocation = LatLng(
            (widget.ride['driverLat'] as num).toDouble(),
            (widget.ride['driverLng'] as num).toDouble()
          );
        });
      }
      _getLocation();
      _updateRoutePath(); 
    });
    
    WidgetsBinding.instance.addObserver(this);
    _setupSocketListeners();
    _startCameraWithPermissions();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopNativeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _startCameraWithPermissions();
    }
  }

  Future<void> _stopNativeCamera() async {
    if (Platform.isIOS && _nativeFrontCamStarted) {
      try {
        await _nativeFrontCam.invokeMethod('stopCapture');
        _nativeFrontCamStarted = false;
        AppLogger.info('[iOS] Native front camera stopped via lifecycle/dispose');
      } catch (e) {
        AppLogger.error('[iOS] Failed to stop native camera', e);
      }
    }
  }

  Future<void> _startCameraWithPermissions() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      await _initCamera();
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is permanently denied. Please enable it in settings.'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ),
        );
      }
    } else {
      AppLogger.warning('Camera permission denied. Requesting again in 3 seconds...');
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _startCameraWithPermissions();
      });
    }
  }

  bool _isInitializingCamera = false;

  Future<void> _initCamera() async {
    if (Platform.isIOS) {
        // iOS: Front and Back cameras are handled by the Native MultiCam Engine
        // Do NOT use getUserMedia to avoid hardware resource contention and freezes.
        if (_nativeFrontCamStarted || _isInitializingCamera) return;
        _isInitializingCamera = true;
        try {
          await Permission.camera.request();
          final bool? started = await _nativeFrontCam.invokeMethod('startCapture');
          if (started == true) {
            _nativeFrontCamStarted = true;
          } else {
             AppLogger.warning('[iOS] Native front camera startCapture returned false - possible resource lock');
           }
           // Listen for events from native pipeline (ICE candidates + state changes)
           _nativeFrontCam.setMethodCallHandler((call) async {
             final args = Map<String, dynamic>.from(call.arguments as Map? ?? {});

             if (call.method == 'onIceCandidate') {
               final connId = args['connectionId'] as String;
               final driverProvider = Provider.of<DriverProvider>(context, listen: false);
               final socket = driverProvider.socket;
               String adminSocketId = connId;
               String streamType = 'tablet_main';
               for (final suffix in ['_tablet_main', '_phone_interior', '_phone_front_road']) {
                 if (connId.endsWith(suffix)) {
                   adminSocketId = connId.substring(0, connId.length - suffix.length);
                   streamType = suffix.substring(1);
                   break;
                 }
               }
               AppLogger.debug('🧩 [iOS-NATIVE] Forwarding ICE for $streamType to $adminSocketId');
               socket!.emit('webrtc_ice_candidate', {
                 'targetSocketId': adminSocketId,
                 'adminSocketId': socket.id,
                 'target': 'admin',
                 'rideId': _extractId(widget.ride),
                 'type': streamType,
                 'candidate': {
                   'candidate': args['candidate'],
                   'sdpMid': args['sdpMid'],
                   'sdpMLineIndex': args['sdpMLineIndex'],
                 },
               });

             } else if (call.method == 'onIceStateChange') {
                final state = args['state'] as String? ?? '';
                final connId = args['connectionId'] as String? ?? '';
                final streamType = args['streamType'] as String? ?? '';

                if (state == 'failed' || state == 'disconnected' || state == 'closed') {
                  AppLogger.warning('⚠️ [iOS-NATIVE] ICE $state for $connId — waiting 4s');
                  Future.delayed(const Duration(seconds: 4), () async {
                    if (!mounted) return;
                    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
                    final socket = driverProvider.socket;
                    if (socket == null) return;
                    final driverId = (driverProvider.driver?['_id'] ?? driverProvider.driver?['id'] ?? '').toString();
                    String adminSocketId = connId;
                    for (final suffix in ['_tablet_main', '_phone_interior', '_phone_front_road']) {
                      if (connId.endsWith(suffix)) {
                        adminSocketId = connId.substring(0, connId.length - suffix.length);
                        break;
                      }
                    }
                    AppLogger.info('🔁 [iOS-NATIVE] Forcing full reconnect for $streamType');
                    try { await _nativeFrontCam.invokeMethod('disposeConnection', {'connectionId': connId}); } catch (_) {}
                    socket.emit('request_webrtc_stream', { 
                       'driverId': driverId, 
                       'adminSocketId': adminSocketId,
                       'type': streamType 
                    });
                  });
                }
              }
           });
           AppLogger.info('[iOS] Native front camera started (Cam 1: Tablet Main)');
         } catch (e) {
           AppLogger.error('[iOS] Native front camera failed', e);
         } finally {
            _isInitializingCamera = false;
          }
          _startRecording();
          return; // CRITICAL: Stop here for iOS to prevent conflict
        }

    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      final videoDevices = devices.where((device) => device.kind == 'videoinput').toList();

      String? frontCamId; 
      String? backCamId;  
      
      if (videoDevices.isNotEmpty) {
        backCamId = videoDevices[0].deviceId;
        if (videoDevices.length > 1) {
          frontCamId = videoDevices[1].deviceId;
        }
        for (var device in videoDevices) {
           String label = device.label.toLowerCase();
           if (label.contains('back') || label.contains('env') || label.contains('rear')) {
             backCamId = device.deviceId;
           } else if (label.contains('front') || label.contains('user')) {
             frontCamId = device.deviceId;
           }
        }
      }

      try {
        if (frontCamId != null && _interiorStream == null) {
          _interiorStream = await navigator.mediaDevices.getUserMedia({'audio': false, 'video': {'deviceId': frontCamId, 'width': {'ideal': 1280}, 'height': {'ideal': 720}}});
        }
        if (backCamId != null && _frontRoadStream == null) {
          _frontRoadStream = await navigator.mediaDevices.getUserMedia({'audio': false, 'video': {'deviceId': backCamId, 'width': {'ideal': 1280}, 'height': {'ideal': 720}}});
        }
        _startRecording();
      } catch (e) {
        AppLogger.error('Camera Error', e);
      }
    } catch (_) {}
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    try {
      final dir = await getTemporaryDirectory();
      final rideId = _extractId(widget.ride);
      if (rideId == null) return;
      
      if (_frontRoadStream != null) {
        _roadRecorder = MediaRecorder();
        final path = '${dir.path}/road_${rideId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
        await _roadRecorder!.start(path, videoTrack: _frontRoadStream!.getVideoTracks().first);
      }
      
      if (_interiorStream != null) {
        _interiorRecorder = MediaRecorder();
        final path = '${dir.path}/interior_${rideId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
        await _interiorRecorder!.start(path, videoTrack: _interiorStream!.getVideoTracks().first);
      }

      setState(() => _isRecording = true);
      AppLogger.info('📹 [DASHCAM] Phone Recording started for Ride $rideId');
    } catch (e) {
      AppLogger.error('[DASHCAM] Start error', e);
    }
  }

  Future<void> _stopAndUploadRecording() async {
    if (!_isRecording) return;
    final rideId = _extractId(widget.ride);
    if (rideId == null) return;
    
    try {
      String? roadPath;
      String? interiorPath;

      if (_roadRecorder != null) {
         roadPath = await _roadRecorder!.stop();
         _roadRecorder = null;
      }
      if (_interiorRecorder != null) {
         interiorPath = await _interiorRecorder!.stop();
         _interiorRecorder = null;
      }

      setState(() => _isRecording = false);
      AppLogger.info('📼 [DASHCAM] Phone Recording stopped. Initiating upload...');

      if (_isRecording) {
        _uploadVideo(roadPath, 'road', rideId);
        _uploadVideo(interiorPath, 'interior', rideId);
      }
    } catch (e) {
      AppLogger.error('[DASHCAM] Stop error', e);
    }
  }

  Future<void> _uploadVideo(String? path, String type, String rideId) async {
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;

    try {
      if (!mounted) return;
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      final token = driverProvider.driver?['token'] ?? driverProvider.driver?['_id'] ?? driverProvider.driver?['id'] ?? '';
      
      final dio = dio_pkg.Dio();
      final baseUrl = ApiService.baseUrl.endsWith('/')
          ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1)
          : ApiService.baseUrl;
          
      final uploadUrl = '$baseUrl/uploads';
      final associationUrl = '$baseUrl/rides';

      final formData = dio_pkg.FormData.fromMap({
        'file': await dio_pkg.MultipartFile.fromFile(path, filename: '${type}_$rideId.mp4'),
      });

      AppLogger.info('📤 [PHONE-SURVEILLANCE] Archiving $type footage...');
      
      final response = await dio.post(
        uploadUrl, 
        data: formData,
        options: dio_pkg.Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['success'] == true) {
        final videoUrl = response.data['data']['url'];
        await dio.post(
          '$associationUrl/$rideId/recordings', 
          data: {
            'url': videoUrl,
            'type': type,
            'source': 'phone',
            'metadata': {
              'size': response.data['data']['size'],
              'timestamp': DateTime.now().toIso8601String(),
              'device': 'driver_phone'
            }
          },
          options: dio_pkg.Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );
        AppLogger.info('✅ [PHONE-SURVEILLANCE] Archive Linked: $videoUrl');
      } else {
        AppLogger.error('❌ [PHONE-SURVEILLANCE] Upload failed: ${response.data['message']}');
      }
    } catch (e) {
      AppLogger.error('[PHONE-SURVEILLANCE] Critical pipeline failure ($type)', e);
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String type, String adminSocketId, dynamic socket) async {
    final pc = await createPeerConnection({
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
        {"urls": "stun:stun1.l.google.com:19302"},
        {
          "urls": "turn:openrelay.metered.ca:80",
          "username": "openrelayproject",
          "credential": "openrelayproject",
        },
        {
          "urls": "turn:openrelay.metered.ca:443",
          "username": "openrelayproject",
          "credential": "openrelayproject",
        },
        {
          "urls": "turn:openrelay.metered.ca:443?transport=tcp",
          "username": "openrelayproject",
          "credential": "openrelayproject",
        },
      ],
      "sdpSemantics": "unified-plan",
    });
    
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
         socket.emit('webrtc_ice_candidate', {
           'targetSocketId': adminSocketId,
           'target': 'admin',
           'rideId': _extractId(widget.ride),
           'type': type,
           'candidate': candidate.toMap(),
         });
      }
    };
    
    // Route the correct camera stream based on type (works for both iOS and Android)
    // Front camera → tablet_main, interior | Back camera → road, front_road
    final stream = type.contains('interior') || type.contains('tablet_main')
        ? _interiorStream
        : _frontRoadStream;
    if (stream != null) {
      stream.getTracks().forEach((track) {
         pc.addTrack(track, stream);
      });
    }
    
    return pc;
  }

  void _setupSocketListeners() {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final socket = driverProvider.socket;
    
    if (socket != null) {
      final rideId = _extractId(widget.ride);
      
      void joinSignalingRoom() {
        socket.emit('join_room', 'ride_$rideId');
      }

      joinSignalingRoom();
      socket.on('connect', (_) => joinSignalingRoom());
      socket.on('reconnect', (_) => joinSignalingRoom());
      
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (socket.connected) joinSignalingRoom();
      });
      
      socket.on('ride_resumed', (data) {
        if (mounted && _extractId(data['rideId']) == _extractId(widget.ride['_id'])) {
          if (data['ride'] is Map) {
            _rideData = Map<String, dynamic>.from(data['ride']);
          }
          setState(() {
            _breakdownResolvedOverride = true;
            _status = (data['status']?.toString().isNotEmpty == true)
                ? data['status'].toString()
                : 'ongoing';
            _trackingEntities.clear();
            _fitRouteOnNextUpdate = true;
          });
          unawaited(_updateMapOverlays());
          _updateRoutePath();
        }
      });

      socket.on('ride_status_update', (data) {
        if (mounted && _extractId(data['rideId']) == _extractId(widget.ride['_id'])) {
          final newStatus = data['status'];
          if (data['ride'] is Map) {
            _rideData = Map<String, dynamic>.from(data['ride']);
            final rideStatus = (_rideData['status'] ?? '').toString().toLowerCase();
            if (rideStatus == 'breakdown' || rideStatus == 'replacing' || rideStatus == 'on-site' || rideStatus == 'monitoring_breakdown') {
              _breakdownResolvedOverride = false;
            }
          }
          if (newStatus != null && newStatus != _status) {
             if (newStatus == 'cancelled') {
                _handleCancellation();
             } else if (newStatus == 'ongoing' && _status == 'breakdown') {
                setState(() {
                  _status = 'ongoing';
                  _trackingEntities.clear();
                  _fitRouteOnNextUpdate = true;
                });
                unawaited(_updateMapOverlays());
                _updateRoutePath();
             } else {
                setState(() { _status = newStatus; });
                unawaited(_updateMapOverlays());
                _updateRoutePath();
             }
          }
        }
      });

      socket.on('breakdown_cancelled', (data) {
        if (mounted && _extractId(data['rideId']) == _extractId(widget.ride['_id'])) {
           if (data['ride'] is Map) {
             _rideData = Map<String, dynamic>.from(data['ride']);
           }
           setState(() {
             _breakdownResolvedOverride = true;
             _status = (data['status']?.toString().isNotEmpty == true)
                 ? data['status'].toString()
                 : (_rideData['status']?.toString().isNotEmpty == true
                     ? _rideData['status'].toString()
                     : 'ongoing');
             _trackingEntities.clear();
             _fitRouteOnNextUpdate = true;
           });
           unawaited(_updateMapOverlays());
           _updateRoutePath();
        }
      });

      socket.on('ride_cancelled', (data) {
        if (mounted && data['rideId'] == widget.ride['_id']) {
          _handleCancellation();
        }
      });

      socket.on('breakdown_update', (data) {
        if (mounted && _extractId(data['rideId'] ?? data['breakdownId']) == rideId) {
          if (_breakdownResolvedOverride) return;
          _breakdownResolvedOverride = false;
          final type = data['type'];
          if (type == 'replacement_assigned' || type == 'replacement_accepted') {
            setState(() {
              if (data['driver'] != null) {
                final d = data['driver'];
                if (d['location'] != null && d['location']['coordinates'] != null) {
                   final coords = d['location']['coordinates'];
                   _trackingEntities['replacement'] = LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
                }
              }
            });
            _updateRoutePath();
          }
        }
      });

      socket.on('breakdown_tracking_update', (data) {
        if (mounted && _extractId(data['rideId']) == rideId) {
          final type = (data['type'] ?? '').toString();
          if (_ignoredTrackingTypes.contains(type)) {
            return;
          }
          setState(() {
            _trackingEntities[type] = LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble());
          });
          if (!_isReplacementDriver && type == 'replacement') {
             _updateRoutePath();
          }
        }
      });

      socket.on('ride_active', (data) {
        if (mounted) {
           setState(() { _status = 'started'; });
           unawaited(_updateMapOverlays());
           _updateRoutePath();
        }
      });

      socket.on('breakdown_handover_complete', (data) {
        if (!mounted) return;
        _positionStream?.cancel();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WarehouseReturnScreen()),
          (route) => false,
        );
      });

      socket.on('vehicle_breakdown_alert', (data) {
        if (mounted && data['rideId'] == widget.ride['_id']) {
          if (_breakdownResolvedOverride) return;
          setState(() {
            _breakdownResolvedOverride = false;
            _status = 'breakdown';
          });
        }
      });

      final driver = Provider.of<DriverProvider>(context, listen: false).driver;
      final driverId = (driver?['_id'] ?? driver?['id'] ?? '').toString();

      socket.emit('join_room', 'driver_$driverId');

      socket.off('request_webrtc_stream');
      socket.on('request_webrtc_stream', (data) async {
          final adminSocketId = data['adminSocketId']?.toString();
          final rawType = data['type']?.toString();
          
          if (adminSocketId == null) {
            AppLogger.warning('⚠️ [WEBRTC] request_webrtc_stream missing adminSocketId: $data');
            return;
          }
          
          // If type is null, admin wants ALL streams — expand to all types
          final streamTypes = (rawType != null) ? [rawType] : ['tablet_main', 'phone_front_road', 'phone_interior'];
          
          for (final streamType in streamTypes) {
          
          // iOS: Use the NATIVE multi-camera pipeline for stable dual-camera support
          if (Platform.isIOS && (streamType == 'tablet_main' || streamType == 'phone_interior' || streamType == 'phone_front_road')) {
            final connectionId = '${adminSocketId}_$streamType';

            // Debounce: If we recently handled a request for this exact stream, ignore
            final lastRequest = _lastNativeConnectionRequest[connectionId];
            if (lastRequest != null && DateTime.now().difference(lastRequest).inSeconds < 3) {
              AppLogger.info('⏭️ [iOS-NATIVE] Ignoring redundant stream request for $streamType');
              continue;
            }
            _lastNativeConnectionRequest[connectionId] = DateTime.now();

            await _initCamera(); // Ensures native front cam is started
            try {
              // Dispose previous native connection if exists
              try { await _nativeFrontCam.invokeMethod('disposeConnection', {'connectionId': connectionId}); } catch (_) {}
              
              final offerResult = await _nativeFrontCam.invokeMethod('createOffer', {
                'connectionId': connectionId,
                'streamType': streamType,
              });
              final offer = Map<String, dynamic>.from(offerResult as Map);
              socket.emit('webrtc_offer', {
                'targetSocketId': adminSocketId,
                'rideId': _extractId(widget.ride),
                'type': streamType,
                'sdp': {'sdp': offer['sdp'], 'type': offer['type']},
              });
              AppLogger.info('📤 [iOS-NATIVE] Front camera offer sent for $streamType');
            } catch (e) {
              AppLogger.error('[iOS-NATIVE] createOffer failed', e);
            }
            continue;
          }

          if (streamType == 'phone_front_road' && _frontRoadStream == null) await _initCamera();

          final connectionKey = '${adminSocketId}_$streamType';
          if (_peerConnections.containsKey(connectionKey)) {
             await _peerConnections[connectionKey]?.dispose();
             _peerConnections.remove(connectionKey);
          }
          
          final pc = await _createPeerConnection(streamType, adminSocketId, socket);
          _peerConnections[connectionKey] = pc;
          final offer = await pc.createOffer();
          await pc.setLocalDescription(offer);
          socket.emit('webrtc_offer', {
            'targetSocketId': adminSocketId,
            'rideId': _extractId(widget.ride),
            'type': streamType,
            'sdp': offer.toMap(),
          });
          } // end for loop
      });

      socket.off('toggle_webrtc_stream');
      socket.on('toggle_webrtc_stream', (data) async {
         if (data is! Map) return;
         final type = data['type']?.toString();
         final status = data['status']?.toString();
         
         if (status == 'off') {
            if (type == 'phone_front_road' || type == null) {
               _frontRoadStream?.getTracks().forEach((t) => t.stop());
               _frontRoadStream = null;
            }
            if (type == 'phone_interior' || type == 'tablet_main' || type == null) {
               _interiorStream?.getTracks().forEach((t) => t.stop());
               _interiorStream = null;
            }
            _peerConnections.removeWhere((key, pc) {
               if (type == null || key.endsWith(type)) {
                  pc.dispose();
                  return true;
               }
               return false;
            });
            if (mounted) setState(() {});
         } else if (status == 'on') {
            await _initCamera();
            final requester = data['adminSocketId'];
            if (requester != null) {
               socket.emit('request_webrtc_stream', { 'rideId': _extractId(widget.ride), 'adminSocketId': requester, 'type': type });
            } 
         }
      });

      socket.off('webrtc_answer');
      socket.on('webrtc_answer', (data) async {
         final adminId = data['adminSocketId'] ?? data['senderSocketId'];
         final type = data['type'];
         final connectionKey = '${adminId}_$type';
         if (_extractId(data['rideId']) != _extractId(widget.ride)) return;
         
         // iOS: Forward answer to native side for all native streams
         if (Platform.isIOS && (type == 'tablet_main' || type == 'phone_interior' || type == 'phone_front_road')) {

            AppLogger.info('📥 [iOS-NATIVE] Received Answer from $adminId for $type');
            try {
               await _nativeFrontCam.invokeMethod('setAnswer', {
                  'connectionId': connectionKey,
                  'sdp': data['sdp']['sdp'],
               });
               AppLogger.info('✅ [iOS-NATIVE] Answer set for $type');
            } catch (e) {
               AppLogger.error('[iOS-NATIVE] setAnswer failed', e);
            }
            return;
         }
         
         final pc = _peerConnections[connectionKey];
         if (pc != null) {
            final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
            await pc.setRemoteDescription(sdp);
         }
      });

      socket.off('webrtc_ice_candidate');
      socket.on('webrtc_ice_candidate', (data) async {
         if (_extractId(data['rideId']) != _extractId(widget.ride)) return;
         final adminId = data['senderSocketId'] ?? data['adminSocketId'];
         final type = data['type'];
         final connectionKey = '${adminId}_$type';
         
         // iOS: Forward ICE candidates to native side for all native streams
         if (Platform.isIOS && (type == 'tablet_main' || type == 'phone_interior' || type == 'phone_front_road')) {

            AppLogger.debug('📥 [iOS-NATIVE] Received ICE candidate from $adminId for $type');
            try {
              final c = data['candidate'];
              await _nativeFrontCam.invokeMethod('addIceCandidate', {
                'connectionId': connectionKey,
                'candidate': c['candidate'],
                'sdpMid': c['sdpMid'],
                'sdpMLineIndex': c['sdpMLineIndex'],
              });
            } catch (e) {
              AppLogger.error('[iOS-NATIVE] addIceCandidate failed', e);
            }
            return;
         }
         
         final pc = _peerConnections[connectionKey];
         if (pc != null && data['candidate'] != null) {
            final candidateData = data['candidate'];
            final candidate = RTCIceCandidate(
               candidateData['candidate'],
               candidateData['sdpMid'],
               candidateData['sdpMLineIndex']
            );
            await pc.addCandidate(candidate);
         }
      });
    }
  }

  void _handleCancellation() async {
    if (!mounted) return;
    AppLogger.info('🛑 [DASHCAM] Ride cancelled. Archiving footage before exiting...');
    await _stopAndUploadRecording();
    _positionStream?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _getLocation() async {
    try {
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) _updateLocation(lastKnown);
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
      ).listen((Position position) {
        if (mounted) _updateLocation(position);
      });
    } catch (e) {
      AppLogger.error('Location error', e);
    }
  }

  DateTime _lastRouteUpdate = DateTime.now().subtract(const Duration(minutes: 1));

  void _updateLocation(Position position) {
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      if (position.heading != 0) _currentHeading = position.heading;
    });

    _updateDriverSymbol();

    if (_isFirstLocation) {
      _recenterOnDriver();
      _isFirstLocation = false;
    } else if (_followDriver) {
      _focusOnDriver();
    }
    
    Provider.of<DriverProvider>(context, listen: false).updateLocation(
      position.latitude, 
      position.longitude,
      heading: position.heading,
      speed: position.speed,
    );
    
    if (_routePoints.isEmpty || DateTime.now().difference(_lastRouteUpdate).inSeconds > 30) {
      _updateRoutePath();
    }
  }

  String _getCustomerName(Map<String, dynamic> ride) {
    if (ride['userId'] != null && ride['userId'] is Map) {
      return ride['userId']['name'] ?? 'Customer';
    }
    if (ride['user'] != null && ride['user'] is Map) {
      return ride['user']['name'] ?? 'Customer';
    }
    return ride['userName'] ?? 'Customer';
  }

  String _formatDuration(double seconds) {
    if (seconds < 20) return 'Arrived';
    if (seconds < 60) return '${seconds.round()} sec';
    int minutes = (seconds / 60).floor();
    int remainingSeconds = (seconds % 60).round();
    if (minutes < 5 && remainingSeconds > 5) {
      return '$minutes min $remainingSeconds sec';
    }
    return '$minutes min';
  }

  Future<void> _updateRoutePath() async {
    _lastRouteUpdate = DateTime.now();
    LatLng start = currentLocation;
    final ride = _rideData.isNotEmpty ? _rideData : widget.ride;
    final pickup = ride['pickup'];
    final drop = ride['drop'];
    final String status = _effectiveTripStatus();
    final destinationStatus = _isPrePickupStatus(status);
    
    var destination = (_isReplacementDriver && (status == 'breakdown' || status == 'on-site' || status == 'replacing'))
        ? (ride['breakdownLocation'] ?? ride['pickup'])
        : (destinationStatus ? pickup : (drop ?? ride['destination']));

    if (!_isReplacementDriver && status == 'breakdown') {
      if (_trackingEntities.containsKey('replacement')) {
        start = _trackingEntities['replacement']!;
        destination = {
          'lat': currentLocation.latitude,
          'lng': currentLocation.longitude
        };
      }
    }

    if (destination == null || destination['lat'] == null || destination['lng'] == null) return;

    try {
      final routeData = await MapplsService.getRoute(
        start: start,
        end: LatLng(
          (destination['lat'] as num).toDouble(),
          (destination['lng'] as num).toDouble(),
        ),
        alternatives: true,
      );

      if (routeData != null && mounted) {
        setState(() {
          _routePoints = List<LatLng>.from(routeData['routePoints'] ?? const []);
          _trafficSegments = List<Map<String, dynamic>>.from(routeData['trafficSegments'] ?? const []);
          _altRoutePoints = List<LatLng>.from(routeData['altRoutePoints'] ?? const []);
          final duration = (routeData['durationSeconds'] as num?)?.toDouble() ?? 0;
          final distance = (routeData['distanceMeters'] as num?)?.toDouble();
          _routeEta = duration > 3600 * 24 ? '> 1 day' : _formatDuration(duration);
          if (distance != null) {
            final km = distance / 1000.0;
            _routeDistance = km < 1.0 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
          }
        });
        await _updateMapOverlays();
        return;
      }
      await _applyFallbackRouteEstimate(start, LatLng((destination['lat'] as num).toDouble(), (destination['lng'] as num).toDouble()));
    } catch (e) {
      await _applyFallbackRouteEstimate(start, LatLng((destination['lat'] as num).toDouble(), (destination['lng'] as num).toDouble()));
    }
  }

  Future<void> _applyFallbackRouteEstimate(LatLng start, LatLng end) async {
    try {
      final response = await ApiService().get('maps/direction?pickup=${start.latitude},${start.longitude}&drop=${end.latitude},${end.longitude}');
      if (response is Map && response['success'] == true && mounted) {
        final data = response['data'] as Map?;
        final distanceKm = double.tryParse('${data?['distanceKm'] ?? ''}');
        final durationMin = int.tryParse('${data?['durationMin'] ?? ''}');
        setState(() {
          _routePoints = [];
          _altRoutePoints = [];
          _trafficSegments = [];
          if (distanceKm != null) _routeDistance = distanceKm < 1.0 ? '${(distanceKm * 1000).round()} m' : '${distanceKm.toStringAsFixed(1)} km';
          if (durationMin != null) _routeEta = durationMin <= 1 ? 'Arrived' : '$durationMin min';
        });
        await _updateMapOverlays();
        return;
      }
    } catch (e) {
      AppLogger.error('Error getting route', e);
    }
    final meters = Geolocator.distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude);
    final km = meters / 1000.0;
    final etaMinutes = km <= 0.1 ? 1 : ((km / 28.0) * 60).ceil();
    setState(() {
      _routePoints = [];
      _altRoutePoints = [];
      _trafficSegments = [];
      _routeDistance = km < 1.0 ? '${meters.round()} m' : '${km.toStringAsFixed(1)} km';
      _routeEta = etaMinutes <= 1 ? 'Arrived' : '$etaMinutes min';
    });
    await _updateMapOverlays();
  }

  LatLng? _pickupLatLng() {
    final ride = _rideData.isNotEmpty ? _rideData : widget.ride;
    final pickup = ride['pickup'];
    if (pickup == null || pickup['lat'] == null || pickup['lng'] == null) return null;
    return LatLng((pickup['lat'] as num).toDouble(), (pickup['lng'] as num).toDouble());
  }

  LatLng? _dropLatLng() {
    final ride = _rideData.isNotEmpty ? _rideData : widget.ride;
    final drop = ride['drop'];
    if (drop == null || drop['lat'] == null || drop['lng'] == null) return null;
    return LatLng((drop['lat'] as num).toDouble(), (drop['lng'] as num).toDouble());
  }

  bool _hasActiveBreakdown() {
    if (_breakdownResolvedOverride) return false;
    final ride = _rideData.isNotEmpty ? _rideData : widget.ride;
    final breakdown = ride['breakdownId'];
    if (breakdown == null || breakdown == '') return false;
    if (breakdown is Map) {
      final breakdownStatus = (breakdown['status'] ?? '').toString().toLowerCase();
      if (breakdownStatus == 'resolved' || breakdownStatus == 'cancelled' || breakdownStatus == 'closed') return false;
    }
    final rideStatus = (ride['status'] ?? '').toString().toLowerCase();
    if (rideStatus == 'ongoing' || rideStatus == 'started' || rideStatus == 'completed' || rideStatus == 'cancelled') return false;
    return true;
  }

  String _effectiveTripStatus() {
    final current = _status.toLowerCase();
    if ((current == 'breakdown' || current == 'monitoring_breakdown' || current == 'replacing' || current == 'on-site') && !_hasActiveBreakdown()) {
      final ride = _rideData.isNotEmpty ? _rideData : widget.ride;
      final rideStatus = (ride['status'] ?? '').toString().toLowerCase();
      if (rideStatus.isNotEmpty && rideStatus != 'breakdown' && rideStatus != 'replacing' && rideStatus != 'on-site') return rideStatus;
      return 'ongoing';
    }
    return current;
  }

  Future<void> _ensureMapAssets() async {
    if (_mapController == null || !_mapStyleReady) return;
    try {
      final bytesCar = (await rootBundle.load('assets/car_marker.png')).buffer.asUint8List();
      await _mapController!.addImage('driver-car-marker', bytesCar, false);
      final bytesUser = (await rootBundle.load('assets/user_marker.png')).buffer.asUint8List();
      await _mapController!.addImage('user-marker', bytesUser, false);
      final bytesDrop = (await rootBundle.load('assets/drop_marker.png')).buffer.asUint8List();
      await _mapController!.addImage('drop-marker', bytesDrop, false);
    } catch (e) {
      AppLogger.error('Error ensuring map assets', e);
    }
  }

  Future<void> _setupMapOverlays() async {
    _mapStyleReady = true;
    await _ensureMapAssets();
    await _syncStaticSymbols();
    await _updateDriverSymbol();
    await _updateMapOverlays();
  }

  Future<void> _syncStaticSymbols() async {
    if (_mapController == null || !_mapStyleReady) return;
    final pickupLatLng = _pickupLatLng();
    final dropLatLng = _dropLatLng();
    final String status = _status.toLowerCase();
    final showPickup = pickupLatLng != null && _isPrePickupStatus(status);

    if (showPickup) {
      if (_pickupSymbol == null) {
        _pickupSymbol = await _mapController!.addSymbol(SymbolOptions(geometry: pickupLatLng, iconImage: 'user-marker', iconSize: 0.18));
      } else {
        await _mapController!.updateSymbol(_pickupSymbol!, SymbolOptions(geometry: pickupLatLng, iconImage: 'user-marker', iconSize: 0.18));
      }
    } else if (_pickupSymbol != null) {
      await _mapController!.removeSymbol(_pickupSymbol!);
      _pickupSymbol = null;
    }

    if (dropLatLng != null) {
      if (_dropSymbol == null) {
        _dropSymbol = await _mapController!.addSymbol(SymbolOptions(geometry: dropLatLng, iconImage: 'drop-marker', iconSize: 0.18));
      } else {
        await _mapController!.updateSymbol(_dropSymbol!, SymbolOptions(geometry: dropLatLng, iconImage: 'drop-marker', iconSize: 0.18));
      }
    }
  }

  Future<void> _updateDriverSymbol() async {
    if (_mapController == null || !_mapStyleReady) return;
    await _ensureMapAssets();
    if (_driverHaloCircle == null) {
      _driverHaloCircle = await _mapController!.addCircle(CircleOptions(geometry: currentLocation, circleRadius: 20, circleColor: '#2563EB', circleOpacity: 0.14, circleStrokeColor: '#60A5FA', circleStrokeWidth: 1.8, circleBlur: 0.6));
    } else {
      await _mapController!.updateCircle(_driverHaloCircle!, CircleOptions(geometry: currentLocation, circleRadius: 20, circleColor: '#2563EB', circleOpacity: 0.14, circleStrokeColor: '#60A5FA', circleStrokeWidth: 1.8, circleBlur: 0.6));
    }
    if (_driverSymbol == null) {
      _driverSymbol = await _mapController!.addSymbol(SymbolOptions(geometry: currentLocation, iconImage: 'driver-car-marker', iconSize: 0.16, iconRotate: _currentHeading, iconAnchor: 'center'));
      if (mounted) setState(() { _routePoints = []; _altRoutePoints = []; _trafficSegments = []; });
      await _updateMapOverlays();
      return;
    }
    await _mapController!.updateSymbol(_driverSymbol!, SymbolOptions(geometry: currentLocation, iconImage: 'driver-car-marker', iconSize: 0.16, iconRotate: _currentHeading, iconAnchor: 'center'));
  }

  Future<void> _updateTrackingSymbols() async {
    if (_mapController == null || !_mapStyleReady) return;
    final activeKeys = _trackingEntities.keys.where((key) => !_ignoredTrackingTypes.contains(key)).toSet();
    final staleKeys = _trackingSymbols.keys.where((key) => !activeKeys.contains(key)).toList();
    for (final key in staleKeys) {
      await _mapController!.removeSymbol(_trackingSymbols[key]!);
      _trackingSymbols.remove(key);
    }
    for (final entry in _trackingEntities.entries) {
      if (_ignoredTrackingTypes.contains(entry.key)) continue;
      final color = entry.key == 'tow' ? '#F97316' : '#2563EB';
      final existing = _trackingSymbols[entry.key];
      if (existing == null) {
        _trackingSymbols[entry.key] = await _mapController!.addSymbol(SymbolOptions(geometry: entry.value, iconImage: 'marker-15', iconSize: 0.85, iconColor: color));
      } else {
        await _mapController!.updateSymbol(existing, SymbolOptions(geometry: entry.value, iconImage: 'marker-15', iconSize: 0.85, iconColor: color));
      }
    }
  }

  bool _isUpdatingOverlays = false;

  Future<void> _updateMapOverlays() async {
    if (_mapController == null || !_mapStyleReady || _isUpdatingOverlays) return;
    _isUpdatingOverlays = true;
    try {
      await _syncStaticSymbols();
      await _updateDriverSymbol();
      await _updateTrackingSymbols();
      
      if (_routeLine != null) { 
        await _mapController!.removeLine(_routeLine!); 
        _routeLine = null; 
      }
      if (_altRouteLine != null) { 
        await _mapController!.removeLine(_altRouteLine!); 
        _altRouteLine = null; 
      }
      
      // Fix: Copy list to avoid concurrent modification during async iteration
      final linesToRemove = List<Line>.from(_trafficLines);
      _trafficLines.clear();
      for (final line in linesToRemove) { 
        await _mapController!.removeLine(line); 
      }
      
      if (_routePoints.isNotEmpty) {
        _routeLine = await _mapController!.addLine(LineOptions(
          geometry: _routePoints, 
          lineColor: '#FFFFFF', 
          lineWidth: 7.2, 
          lineOpacity: 0.92
        ));
        
        if (_trafficSegments.isNotEmpty) {
          for (final segment in _trafficSegments) {
            final points = (segment['points'] as List?)?.whereType<LatLng>().toList() ?? const <LatLng>[];
            if (points.length < 2) continue;
            final line = await _mapController!.addLine(LineOptions(
              geometry: points, 
              lineColor: _lineColorHex(segment['color'], fallback: '#2196F3'), 
              lineWidth: 4.8, 
              lineOpacity: 0.98
            ));
            _trafficLines.add(line);
          }
        } else {
          final line = await _mapController!.addLine(LineOptions(
            geometry: _routePoints, 
            lineColor: '#2563EB', 
            lineWidth: 4.8, 
            lineOpacity: 0.98
          ));
          _trafficLines.add(line);
        }
        if (_fitRouteOnNextUpdate) { 
          _fitRouteOnNextUpdate = false; 
          _followDriver = false; 
          await _recenterActiveRoute(); 
        }
      }
      if (_altRoutePoints.isNotEmpty) { 
        _altRouteLine = await _mapController!.addLine(LineOptions(
          geometry: _altRoutePoints, 
          lineColor: '#4F46E5', 
          lineWidth: 3.4, 
          lineOpacity: 0.42
        )); 
      }
    } finally {
      _isUpdatingOverlays = false;
    }
  }

  bool _canMoveCamera() {
    final now = DateTime.now();
    if (now.difference(_lastCameraMoveAt) < const Duration(milliseconds: 900)) return false;
    _lastCameraMoveAt = now;
    return true;
  }

  bool _isPrePickupStatus(String status) => status == 'accepted' || status == 'assigned' || status == 'arrived';

  Future<void> _recenterOnDriver() async { if (_mapController == null || !_canMoveCamera()) return; await _recenterActiveRoute(); }

  String _lineColorHex(dynamic value, {String fallback = '#2196F3'}) {
    if (value is String && value.isNotEmpty) return value;
    if (value is Color) {
      final hex = value.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
      return '#$hex';
    }
    return fallback;
  }

  Future<void> _focusOnDriver() async {
    if (_mapController == null || !_canMoveCamera()) return;
    await _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: currentLocation, zoom: 14.8, bearing: _currentHeading)));
  }

  Future<void> _recenterActiveRoute() async {
    if (_mapController == null || !_canMoveCamera()) return;
    if (_routePoints.isEmpty) {
      await _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: currentLocation, zoom: 15.2, bearing: _currentHeading)));
      return;
    }
    final visiblePoints = [..._routePoints, ..._altRoutePoints, currentLocation, ..._trackingEntities.values];
    final bounds = LatLngBounds(
      southwest: LatLng(visiblePoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b), visiblePoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(visiblePoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b), visiblePoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b)),
    );
    await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, left: 44, right: 44, top: 120, bottom: 250));
  }

  String _getButtonText() {
    final status = _effectiveTripStatus();
    final isReplacement = _isReplacementDriver;
    if (isReplacement) {
      if (status == 'breakdown' || status == 'assigned' || status == 'accepted' || status == 'on-site') return 'I Have Arrived';
      if (status == 'replacing' || status == 'arrived') return 'Complete Handover';
      return 'Complete Ride';
    }
    if (status == 'breakdown') return 'Awaiting Rescue...';
    if (status == 'assigned' || status == 'accepted') return 'I Have Arrived';
    if (status == 'arrived') return 'Start Ride';
    if (status == 'started' || status == 'ongoing' || status == 'picked_up') return 'Complete Ride';
    return 'Continue';
  }

  Widget _routeMetricTile({required IconData icon, required String label, required String value, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final status = _effectiveTripStatus();
    final bool isReplacement = _isReplacementDriver;
    final String rideId = _extractId(widget.ride) ?? '';
    final String breakdownId = _extractId(widget.ride['breakdownId'] ?? widget.ride['id']) ?? '';

    // setState(() { _completingRide = true; });

    try {
      if (isReplacement) {
        if (status == 'breakdown' || status == 'accepted' || status == 'assigned' || status == 'on-site') {
          final success = await driverProvider.arrivedAtBreakdown(breakdownId);
          if (success && mounted) { setState(() { _status = 'replacing'; }); _updateRoutePath(); }
          return;
        }
        if (status == 'replacing' || status == 'arrived') {
          setState(() { _status = 'ongoing'; });
          _updateRoutePath();
          return;
        }
      }

      String nextStatus = '';
      if (status == 'accepted' || status == 'assigned') {
        nextStatus = 'arrived';
      } else if (status == 'arrived' || status == 'replacing') {
        nextStatus = 'started';
      } else if (status == 'started' || status == 'ongoing' || status == 'picked_up') {
        _showPaymentSelectionSheet();
        return;
      }

      if (nextStatus.isNotEmpty) {
        final success = await driverProvider.updateRideStatus(rideId, nextStatus);
        if (success && mounted) { setState(() { _status = nextStatus; }); unawaited(_updateMapOverlays()); _updateRoutePath(); }
      }
    } finally {
      // if (mounted) setState(() { _completingRide = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    return Scaffold(
      body: Stack(
        children: [
          MapplsMap(
            initialCameraPosition: CameraPosition(target: currentLocation, zoom: 14.2),
            onMapCreated: (controller) { _mapController = controller; },
            onStyleLoadedCallback: () { _setupMapOverlays(); },
            myLocationEnabled: false,
          ),
          Positioned(
            right: 16, bottom: 320,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12)]),
                  child: IconButton(tooltip: 'Route overview', onPressed: () { setState(() { _followDriver = false; _fitRouteOnNextUpdate = true; }); _recenterActiveRoute(); }, icon: const Icon(Icons.center_focus_strong_rounded, color: Colors.black87)),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: _followDriver ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12)]),
                  child: IconButton(tooltip: 'Focus on driver', onPressed: () { setState(() { _followDriver = true; }); _focusOnDriver(); }, icon: Icon(Icons.navigation_rounded, color: _followDriver ? Colors.white : Colors.black87)),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1.5)), child: const CircleAvatar(radius: 24, backgroundColor: Color(0xFFF0F0F0), child: Icon(Icons.person, color: Colors.black54))),
                            Positioned(bottom: 0, right: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)))),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getCustomerName(ride), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.redAccent, size: 12),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(ride['pickup']?['address'] ?? 'Loading address...', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${ride['fare']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
                            const SizedBox(height: 4),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: const Text('LIVE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_routeEta.isNotEmpty)
            Positioned(
              top: 130, right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5))]),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.access_time_filled_rounded, color: Colors.blue, size: 18), const SizedBox(width: 6), Text(_routeEta, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 14))]),
                        if (_routeDistance.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(width: 30, height: 2, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 8),
                          Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.route_rounded, color: Colors.black54, size: 18), const SizedBox(width: 6), Text(_routeDistance, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 14))]),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -5))]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 16),
                  Text((_status == 'accepted' || _status == 'assigned') ? 'Driving to Pickup' : (_status == 'arrived' ? 'At Pickup Location' : 'Driving to Destination'), style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Row(
                      children: [
                        Expanded(child: _routeMetricTile(icon: Icons.access_time_filled_rounded, label: 'Est. Time', value: _routeEta.isNotEmpty ? _routeEta : 'Calculating...', color: Colors.blue)),
                        Container(width: 1, height: 38, color: const Color(0xFFE2E8F0)),
                        Expanded(child: _routeMetricTile(icon: Icons.route_rounded, label: 'Distance', value: _routeDistance.isNotEmpty ? _routeDistance : 'Calculating...', color: Colors.black87)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: (_hasActiveBreakdown() && _effectiveTripStatus() == 'breakdown' && !_isReplacementDriver) ? null : _updateStatus,
                          style: ElevatedButton.styleFrom(backgroundColor: (_effectiveTripStatus() == 'started' || _effectiveTripStatus() == 'ongoing') ? Colors.black : (_effectiveTripStatus() == 'arrived' ? Colors.green : Colors.blue), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
                          child: Text(_getButtonText(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.5)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(onTap: _showBreakdownConfirm, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.warning_rounded, color: Colors.red, size: 28))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_hasActiveBreakdown() && _effectiveTripStatus() == 'breakdown' && !_isReplacementDriver) _buildBreakdownOverlay(),
        ],
      ),
    );
  }

  void _showPaymentSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Text('Complete Ride', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            const Text('Has the passenger paid for the trip?', style: TextStyle(color: Colors.black54, fontSize: 15)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Back'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: _completeRideFinishing, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(0, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Confirm Payment'))),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _completeRideFinishing() async {
    Navigator.pop(context);
    // setState(() => _completingRide = true);
    try {
      final rideId = _extractId(widget.ride) ?? '';
      await _stopAndUploadRecording();
      if (!mounted) return;
      final success = await Provider.of<DriverProvider>(context, listen: false).updateRideStatus(rideId, 'completed');
      if (success && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TripCompletedScreen(ride: _rideData.isNotEmpty ? _rideData : widget.ride)));
      }
    } catch (e) {
      AppLogger.error('Error completing ride', e);
    } finally {
      // if (mounted) setState(() => _completingRide = false);
    }
  }

  void _showBreakdownConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Breakdown'),
        content: const Text('Are you sure you want to report a vehicle breakdown? This will dispatch a replacement driver to your location.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final rideId = _extractId(widget.ride) ?? '';
              await Provider.of<DriverProvider>(context, listen: false).reportBreakdown(rideId, currentLocation.latitude, currentLocation.longitude, 'mechanical: Reported via Phone Driver App');
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.warning_rounded, color: Colors.red, size: 48)),
                  const SizedBox(height: 24),
                  const Text('Vehicle Breakdown', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                  const Text('A replacement driver has been assigned. Please wait for them to arrive and complete the handover.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 15)),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(color: Colors.red),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopNativeCamera();
    _positionStream?.cancel();
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final socket = driverProvider.socket;
    if (socket != null) {
      socket.off('ride_status_update');
      socket.off('ride_cancelled');
      socket.off('ride_resumed');
      socket.off('breakdown_cancelled');
      socket.off('request_webrtc_stream');
      socket.off('webrtc_answer');
      socket.off('webrtc_ice_candidate');
      socket.off('breakdown_update');
      socket.off('breakdown_handover_complete');
      socket.off('ride_active');
      socket.off('vehicle_breakdown_alert');
      socket.off('breakdown_tracking_update');
    }
    _interiorStream?.getTracks().forEach((track) => track.stop());
    _frontRoadStream?.getTracks().forEach((track) => track.stop());
    for (var pc in _peerConnections.values) { pc.dispose(); }
    _peerConnections.clear();
    super.dispose();
  }
}

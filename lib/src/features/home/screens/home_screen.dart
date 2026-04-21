import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/providers/driver_provider.dart';
import 'package:taxi_driver/src/features/home/widgets/ride_request_sheet.dart';
import 'package:taxi_driver/src/features/home/widgets/home_drawer.dart';
import 'package:taxi_driver/src/features/profile/screens/profile_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi_driver/src/core/providers/earnings_provider.dart';
import 'package:taxi_driver/src/features/home/screens/customer_pickup_screen.dart';
import 'package:taxi_driver/src/core/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = false;
  Timer? _rideRequestTimer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng currentLocation = const LatLng(23.0225, 72.5714); // Immediate default: Ahmedabad
  double _currentHeading = 0.0;
  MapplsMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  bool _isFirstLocation = true;
  DateTime? _lastBackendUpdate;
  Timer? _pollingTimer;
  bool _showingRequest = false;
  bool _mapStyleReady = false;
  Symbol? _driverSymbol;
  bool _followDriver = false;
  DateTime _lastCameraMoveAt = DateTime.fromMillisecondsSinceEpoch(0);
  
  // WebRTC Components
  MediaStream? _frontRoadStream;
  MediaStream? _interiorStream;
  final Map<String, RTCPeerConnection> _peerConnections = {};

  // Native front camera MethodChannel (iOS only)
  static const _nativeFrontCam = MethodChannel('com.taxi.native_front_camera');
  bool _nativeFrontCamStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Location is local and fast — start immediately
      _getLocation();
      // API calls run in background — failures won't freeze the UI
      _initData();
    });
  }

  Future<void> _initData() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final earningsProvider = Provider.of<EarningsProvider>(context, listen: false);

    // Run both in parallel with a safety timeout so a cold-starting
    // Render backend can never freeze the app.
    try {
      await Future.wait([
        driverProvider.refreshProfile().timeout(
          const Duration(seconds: 15),
          onTimeout: () => debugPrint('⏱️ refreshProfile timed out'),
        ),
        earningsProvider.fetchEarnings().timeout(
          const Duration(seconds: 15),
          onTimeout: () => debugPrint('⏱️ fetchEarnings timed out'),
        ),
      ]);

      // SYNC ONLINE STATUS FROM BACKEND
      if (mounted && driverProvider.driver != null) {
        final backendOnlineStatus = driverProvider.driver!['isOnline'] ?? false;
        setState(() {
          _isOnline = backendOnlineStatus;
        });
        debugPrint('🔄 Synced online status from backend: $_isOnline');
        
        // Ensure listening starts if online
        if (_isOnline) {
          _startOrderListening();
        }
      }

      // AUTO REDIRECT TO ONGOING RIDE IF EXISTS
      final currentRide = await driverProvider.checkCurrentRide();
      if (currentRide != null && mounted) {
        debugPrint('🚀 Driver has active ride, redirecting to surveillance...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => CustomerPickupScreen(ride: currentRide)),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Startup data fetch error (non-fatal): $e');
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      // 1. Get initial position quickly
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        _updateLocation(lastKnown);
      }

      // 2. Start continuous tracking for "perfect" real-time updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // Use high accuracy for real-time navigation
          distanceFilter: 2, // Update every 2 meters for smoother tracking
        ),
      ).listen((Position position) {
        if (mounted) {
          _updateLocation(position);
        }
      });

    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  void _updateLocation(Position position) {
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      _currentHeading = position.heading;
    });

    _syncDriverSymbol();

    if (_isFirstLocation && _mapController != null) {
      _recenterOnDriver();
      _isFirstLocation = false;
    } else if (_followDriver) {
      _focusOnDriver();
    }

    // Send to backend/socket if online
    if (_isOnline) {
      Provider.of<DriverProvider>(context, listen: false).updateLocation(
        position.latitude, 
        position.longitude,
        heading: position.heading,
        speed: position.speed,
      );
    }
  }

  Future<void> _ensureMapAssets() async {
    if (_mapController == null || !_mapStyleReady) return;

    try {
      final bytes = (await rootBundle.load('assets/car_marker.png')).buffer.asUint8List();
      await _mapController!.addImage('driver-car-marker', bytes, false);
    } catch (e) {
      debugPrint('Map image load error: $e');
    }
  }

  Future<void> _syncDriverSymbol() async {
    if (_mapController == null || !_mapStyleReady) return;

    await _ensureMapAssets();

    if (_driverSymbol == null) {
      _driverSymbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: currentLocation,
          iconImage: 'driver-car-marker',
          iconSize: 0.22,
          iconRotate: _currentHeading,
          iconAnchor: 'center',
        ),
      );
      return;
    }

    await _mapController!.updateSymbol(
      _driverSymbol!,
      SymbolOptions(
        geometry: currentLocation,
        iconImage: 'driver-car-marker',
        iconSize: 0.22,
        iconRotate: _currentHeading,
        iconAnchor: 'center',
      ),
    );
  }

  void _onMapCreated(MapplsMapController controller) {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    _mapStyleReady = true;
    await _syncDriverSymbol();
  }

  bool _canMoveCamera() {
    final now = DateTime.now();
    if (now.difference(_lastCameraMoveAt) < const Duration(milliseconds: 900)) {
      return false;
    }
    _lastCameraMoveAt = now;
    return true;
  }

  Future<void> _recenterOnDriver() async {
    if (_mapController == null || !_canMoveCamera()) return;
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(currentLocation, 14.2),
    );
  }

  Future<void> _focusOnDriver() async {
    if (_mapController == null || !_canMoveCamera()) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentLocation,
          zoom: 14.8,
          bearing: _currentHeading,
        ),
      ),
    );
  }

  void _handleStatusChange(bool isOnline) async {
    setState(() {
      _isOnline = isOnline;
    });

    // Notify backend
    await Provider.of<DriverProvider>(context, listen: false).toggleOnlineStatus(isOnline);
    
    if (isOnline) {
      _startOrderListening();
      _setupWebRTCSignaling();
      // IMMEDIATE location sync when going online
      Provider.of<DriverProvider>(context, listen: false).updateLocation(
        currentLocation.latitude, 
        currentLocation.longitude,
        heading: _currentHeading,
      );
    } else {
      _stopOrderListening();
    }
  }

  void _startOrderListening() {
    _stopOrderListening();
    
    debugPrint("🎧 [DEBUG] Starting order listening (Socket + Polling)");

    // 1. Socket Listener (REAL-TIME)
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    driverProvider.socket?.on('new_ride_request', (data) {
      debugPrint("📢 [DEBUG] Received SOCKET ride request!");
      if (mounted && !_showingRequest) {
        _onNewRideReceived(data);
      }
    });

    driverProvider.socket?.on('ride_taken', (data) {
      debugPrint("⛔ [DEBUG] Ride taken event received: $data");
      if (mounted && _showingRequest) {
        _showingRequest = false;
      }
    });

    driverProvider.socket?.on('ride_assigned', (data) {
      debugPrint("🎯 [DEBUG] Admin assigned a ride to you: $data");
      final ride = data['ride'];
      final bool isEmergency = ride['isEmergency'] ?? false;
      
      if (mounted) {
        if (_showingRequest) {
          Navigator.of(_scaffoldKey.currentContext ?? context).pop();
          _showingRequest = false;
        }
        
        if (isEmergency) {
          _onNewRideReceived(ride);
          ScaffoldMessenger.of(_scaffoldKey.currentContext ?? context).showSnackBar(
            const SnackBar(
              content: Text('🚨 EMERGENCY BREAKDOWN ASSIGNED'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 10),
            ),
          );
        } else {
          NotificationService().playRideRequestSound();
          Future.delayed(const Duration(seconds: 5), () => NotificationService().stopSound());

          Navigator.of(_scaffoldKey.currentContext ?? context).push(
            MaterialPageRoute(builder: (context) => CustomerPickupScreen(ride: ride)),
          );
        }
      }
    });

    driverProvider.socket?.on('breakdown_handover_complete', (data) {
      debugPrint("🏢 [DEBUG] Handover complete, directing to warehouse");
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Handover Complete'),
            content: const Text('The replacement driver has arrived and taken over the ride. Please return to the nearest warehouse.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _initData(); 
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });

    // 3. Refresh earnings immediately
    Provider.of<EarningsProvider>(context, listen: false).fetchEarnings();

    // 4. Keep polling as a backup
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || !_isOnline || _showingRequest) return;
      
      final ride = await driverProvider.fetchPendingRide();
      if (ride != null && mounted) {
        _onNewRideReceived(ride);
      }
    });

    // NEW: Also join the WebRTC signaling room immediately if already online
    _setupWebRTCSignaling();
  }

  void _stopOrderListening() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    final socket = Provider.of<DriverProvider>(context, listen: false).socket;
    socket?.off('new_ride_request');
    socket?.off('ride_assigned');
    socket?.off('breakdown_handover_complete');
    socket?.off('request_webrtc_stream');
    socket?.off('toggle_webrtc_stream');
    
    _stopSensors();
    debugPrint("🔇 [DEBUG] Stopped order listening");
  }

  void _setupWebRTCSignaling() {
     final driverProvider = Provider.of<DriverProvider>(context, listen: false);
     final socket = driverProvider.socket;
     if (socket == null) return;
     
     final driver = driverProvider.driver;
     final driverId = (driver?['_id'] ?? driver?['id'] ?? '').toString();

     socket.emit('join_room', 'driver_$driverId');
     debugPrint('📡 [WEBRTC] Phone joined diagnostics room: driver_$driverId');

     socket.off('request_webrtc_stream');
     socket.on('request_webrtc_stream', (data) async {
        final streamTypes = (data['type'] != null) ? [data['type']] : ['phone_front_road', 'phone_interior'];
        final adminSocketId = data['adminSocketId'];
        
        for (final streamType in streamTypes) {
           unawaited(() async {
              try {
                 // iOS: Use NATIVE multi-camera pipeline for stable dual-camera support (tablet_main, phone_interior, phone_front_road)
                 if (Platform.isIOS && (streamType == 'tablet_main' || streamType == 'phone_interior' || streamType == 'phone_front_road')) {

                   await _initCamera();
                   final connectionId = '${adminSocketId}_$streamType';
                   try { await _nativeFrontCam.invokeMethod('disposeConnection', {'connectionId': connectionId}); } catch (_) {}
                   
                   final offerResult = await _nativeFrontCam.invokeMethod('createOffer', {
                      'connectionId': connectionId,
                      'streamType': streamType,
                    });
                   final offer = Map<String, dynamic>.from(offerResult as Map);
                   socket.emit('webrtc_offer', {
                      'driverId': driverId,
                      'type': streamType,
                      'sdp': {'sdp': offer['sdp'], 'type': offer['type']},
                      'adminSocketId': adminSocketId
                   });
                   debugPrint('📤 [iOS-NATIVE] Front camera offer sent for $streamType');
                   return;
                 }

                 if (streamType == 'phone_front_road' && _frontRoadStream == null) await _initCamera();

                 final connectionKey = '${adminSocketId}_$streamType';
                 if (_peerConnections.containsKey(connectionKey)) {
                    await _peerConnections[connectionKey]?.dispose();
                    _peerConnections.remove(connectionKey);
                 }
                 
                 if (_frontRoadStream == null) return;
                 
                 final pc = await _createPeerConnection(streamType, adminSocketId, socket);
                 _peerConnections[connectionKey] = pc;
                 
                 final offer = await pc.createOffer();
                 await pc.setLocalDescription(offer);
                 
                 socket.emit('webrtc_offer', {
                    'driverId': driverId,
                    'type': streamType,
                    'sdp': offer.toMap(),
                    'adminSocketId': adminSocketId
                 });
              } catch (e) {
                 debugPrint('WebRTC Mobile Stream Error: $e');
              }
           }());
        }
     });

     socket.off('toggle_webrtc_stream');
     socket.on('toggle_webrtc_stream', (data) async {
        final status = data['status'];
        final type = data['type'];
        debugPrint('🔌 [REMOTE] Phone Toggle $type -> $status');

        if (status == 'on') {
           await _initCamera();
           socket.emit('request_webrtc_stream', { 
             'driverId': driverId, 
             'adminSocketId': data['adminSocketId'],
             'type': type 
           });
        } else {
            if (type == 'phone_front_road') {
               _frontRoadStream?.getTracks().forEach((t) => t.stop());
               _frontRoadStream = null;
            } else if (type == 'phone_interior' || type == 'tablet_main') {
               // iOS: dispose native front camera connection
               if (Platform.isIOS) {
                 try { await _nativeFrontCam.invokeMethod('stopCapture'); } catch (_) {}
                 _nativeFrontCamStarted = false;
               } else {
                 _interiorStream?.getTracks().forEach((t) => t.stop());
                 _interiorStream = null;
               }
            } else {
               _stopSensors();
            }
        }
     });

     socket.off('webrtc_answer');
     socket.on('webrtc_answer', (data) async {
        final type = data['type'];
        final adminSocketId = data['adminSocketId'];
        final connectionKey = '${adminSocketId}_$type';
        
        // iOS: Forward answer to native side for all native streams
        if (Platform.isIOS && (type == 'tablet_main' || type == 'phone_interior' || type == 'phone_front_road')) {

          try {
            await _nativeFrontCam.invokeMethod('setAnswer', {
              'connectionId': connectionKey,
              'sdp': data['sdp']['sdp'],
            });
          } catch (e) {
            debugPrint('❌ [iOS-NATIVE] setAnswer failed: $e');
          }
          return;
        }
        
        final pc = _peerConnections[connectionKey];
        if (pc != null && data['sdp'] != null) {
           await pc.setRemoteDescription(RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']));
        }
     });

     socket.off('webrtc_ice_candidate');
     socket.on('webrtc_ice_candidate', (data) async {
        final type = data['type'];
        final adminSocketId = data['adminSocketId'];
        final connectionKey = '${adminSocketId}_$type';
        
        // iOS: Forward ICE candidates to native side for all native streams
        if (Platform.isIOS && (type == 'tablet_main' || type == 'phone_interior' || type == 'phone_front_road')) {

          try {
            final c = data['candidate'];
            await _nativeFrontCam.invokeMethod('addIceCandidate', {
              'connectionId': connectionKey,
              'candidate': c['candidate'],
              'sdpMid': c['sdpMid'],
              'sdpMLineIndex': c['sdpMLineIndex'],
            });
          } catch (e) {
            debugPrint('❌ [iOS-NATIVE] addIceCandidate failed: $e');
          }
          return;
        }
        
        final pc = _peerConnections[connectionKey];
        if (pc != null && data['candidate'] != null) {
           await pc.addCandidate(RTCIceCandidate(
              data['candidate']['candidate'],
              data['candidate']['sdpMid'],
              data['candidate']['sdpMLineIndex']
           ));
        }
     });
  }

  Future<void> _initCamera() async {
    if (Platform.isIOS) {
       // iOS: Dual cameras are handled entirely by Native MultiCam Engine
        // No need for separate getUserMedia to avoid hardware conflicts

       // iOS: Front camera via NATIVE pipeline
       if (!_nativeFrontCamStarted) {
         try {
           await _nativeFrontCam.invokeMethod('startCapture');
           _nativeFrontCamStarted = true;
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

               socket?.emit('webrtc_ice_candidate', {
                 'targetSocketId': adminSocketId,
                 'adminSocketId': socket.id,
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

               if (state == 'failed' || state == 'disconnected') {
                 debugPrint('⚠️ [iOS-NATIVE-HOME] ICE \$state for \$connId — waiting 8s');
                 Future.delayed(const Duration(seconds: 8), () async {
                   if (!mounted) return;
                   final dp = Provider.of<DriverProvider>(context, listen: false);
                   final socket = dp.socket;
                   if (socket == null) return;
                   String adminId = connId;
                   for (final s in ['_tablet_main', '_phone_interior', '_phone_front_road']) {
                     if (connId.endsWith(s)) { adminId = connId.substring(0, connId.length - s.length); break; }
                   }

                   try { await _nativeFrontCam.invokeMethod('disposeConnection', {'connectionId': connId}); } catch (_) {}
                   try {
                     final r = await _nativeFrontCam.invokeMethod('createOffer', {'connectionId': connId, 'streamType': streamType});
                     final offer = Map<String, dynamic>.from(r as Map);
                     socket.emit('webrtc_offer', {'targetSocketId': adminId, 'type': streamType, 'sdp': {'sdp': offer['sdp'], 'type': offer['type']}});
                   } catch (e) { debugPrint('❌ [iOS-NATIVE-HOME] Reconnect: \$e'); }
                 });
               }
             }
           });
           debugPrint('✅ [iOS] Native front camera started');
         } catch (e) {
           debugPrint('❌ [iOS] Native front camera failed: $e');
         }
       }
       return;
    }

    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      final videoDevices = devices.where((device) => device.kind == 'videoinput').toList();
      String? frontCamId; String? backCamId;  
      
      if (videoDevices.isNotEmpty) {
        backCamId = videoDevices[0].deviceId;
        if (videoDevices.length > 1) frontCamId = videoDevices[1].deviceId;
        for (var device in videoDevices) {
           String label = device.label.toLowerCase();
           if (label.contains('back') || label.contains('rear')) backCamId = device.deviceId;
           else if (label.contains('front') || label.contains('user')) frontCamId = device.deviceId;
        }
      }

      if (frontCamId != null && _interiorStream == null) {
        _interiorStream = await navigator.mediaDevices.getUserMedia({'audio': false, 'video': {'deviceId': frontCamId, 'width': {'ideal': 1280}, 'height': {'ideal': 720}}});
      }
      if (backCamId != null && _frontRoadStream == null) {
        _frontRoadStream = await navigator.mediaDevices.getUserMedia({'audio': false, 'video': {'deviceId': backCamId, 'width': {'ideal': 1280}, 'height': {'ideal': 720}}});
      }
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String type, String adminSocketId, dynamic socket) async {
    final pc = await createPeerConnection({'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]});
    
    // Route the correct stream: front camera for interior/tablet_main, back camera for road
    final activeStream = (type.contains('interior') || type.contains('tablet_main')) ? _interiorStream : _frontRoadStream;
    if (activeStream != null) {
       for (var track in activeStream.getTracks()) {
          await pc.addTrack(track, activeStream);
       }
    }

    pc.onIceCandidate = (candidate) {
      socket.emit('webrtc_ice_candidate', {
        'targetSocketId': adminSocketId,
        'adminSocketId': socket.id,
        'candidate': candidate.toMap(),
        'type': type
      });
    };

    return pc;
  }

  void _stopSensors() {
    debugPrint("🛑 [HW] Terminating all hardware sensors and diagnostic streams");
    _interiorStream?.getTracks().forEach((t) => t.stop());
    _frontRoadStream?.getTracks().forEach((t) => t.stop());
    _interiorStream = null;
    _frontRoadStream = null;
    for (var pc in _peerConnections.values) {
       pc.dispose();
    }
    _peerConnections.clear();
  }

  void _onNewRideReceived(dynamic ride) async {
    if (!mounted || _showingRequest) return;
    
    debugPrint("🔔 [DEBUG] Showing ride request sheet for ID: ${ride['_id']}");
    _showingRequest = true;

    // PLAY SOUND AND VIBRATE
    final bool isEmergency = (ride['isEmergency'] == true) || 
                             (ride['is_emergency'] == true) || 
                             (ride['type'] == 'emergency');
    
    NotificationService().playRideRequestSound(isEmergency: isEmergency);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RideRequestSheet(ride: ride),
    ).then((_) {
      _showingRequest = false;
      NotificationService().stopSound(); // stop sound when sheet is dismissed
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const HomeDrawer(),
      body: Stack(
        children: [
          MapplsMap(
            initialCameraPosition: CameraPosition(
              target: currentLocation,
              zoom: 14.2,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            myLocationEnabled: false,
          ),
          
          // 2. Top Area
          SafeArea(
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                children: [
                  // Profile Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Consumer<DriverProvider>(
                      builder: (context, driverProvider, child) {
                        final driver = driverProvider.driver;
                        final name = driver?['name'] ?? 'Driver';
                        final avatar = driver?['avatar'];

                        return Row(
                          children: [
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _scaffoldKey.currentState?.openDrawer(),
                              child: const Icon(Icons.menu),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    const SizedBox(width: 4),
                                    Text('${driver?['rating'] ?? 5.0}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                );
                              },
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey,
                                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                                child: avatar == null ? const Icon(Icons.person, color: Colors.white) : null,
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 8),
                  // TOP BAR: BRANDING
                  
                  const SizedBox(height: 6),
                  // Assigned Vehicle Card (Real-time Details)
                  Consumer<DriverProvider>(
                    builder: (context, provider, _) {
                      if (!provider.isFleetDriver) return const SizedBox.shrink();
                      
                      final driver = provider.driver;
                      // For Fleet/Salary drivers, EXCLUSIVELY use assigned vehicleId.
                      final vehicle = (driver?['vehicleId'] is Map) ? driver!['vehicleId'] : null;
                      
                      if (vehicle == null) return const SizedBox.shrink();

                      final String plate = vehicle['plate'] ?? vehicle['licensePlate'] ?? 'N/A';
                      final String modelName = vehicle['makeModel'] ?? '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}'.trim();
                      final String year = (vehicle['year'] ?? vehicle['yearOfManufacture'])?.toString() ?? '';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF), // Light blue tint for corporate
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0369A1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Assigned Car', style: TextStyle(color: Color(0xFF0C4A6E), fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text('$year $modelName'.trim().isEmpty ? 'Company Vehicle' : '$year $modelName'.trim(), 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: Text(
                                plate,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
                ),
              ),
            ),
          ),
          
          // 3. Floating Action Buttons on Map
          Positioned(
            bottom: 340, // Adjust based on bottom sheet height
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'location_btn',
                  onPressed: () {
                    _getLocation();
                    setState(() {
                      _followDriver = false;
                    });
                    _recenterOnDriver();
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.center_focus_strong_rounded, color: Colors.black),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'focus_btn',
                  onPressed: () {
                    setState(() {
                      _followDriver = true;
                    });
                    _focusOnDriver();
                  },
                  backgroundColor: _followDriver ? Colors.black : Colors.white,
                  child: Icon(
                    Icons.navigation_rounded,
                    color: _followDriver ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Sheet (Status)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Status', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      _isOnline ? "You're Online" : "You're Offline",
                      style: TextStyle(
                        color: _isOnline ? const Color(0xFF10B981) : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 370,height: 30,),
                    // Custom Switch Button
                    GestureDetector(
                      onTap: () => _handleStatusChange(!_isOnline),
                      child: Container(
                        width: 140,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _isOnline ? const Color(0xFF10B981) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              left: _isOnline ? 94 : 4,
                              top: 4,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.power_settings_new,
                                  color: _isOnline ? const Color(0xFF10B981) : Colors.grey,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                     const SizedBox(height: 20),
                     Text(
                      _isOnline ? "You're Online" : "You're Offline",
                      style: TextStyle(
                        color: _isOnline ? const Color(0xFF10B981) : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isOnline ? "Ready to receive ride requests" : "Go online to start earning",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapMarker(IconData icon, Color color) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 5)],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/providers/driver_provider.dart';
import 'package:taxi_driver/src/features/home/screens/customer_pickup_screen.dart';

import 'package:taxi_driver/src/core/services/notification_service.dart';

class RideRequestSheet extends StatefulWidget {
  final Map<String, dynamic> ride;
  const RideRequestSheet({super.key, required this.ride});

  @override
  State<RideRequestSheet> createState() => _RideRequestSheetState();
}

class _RideRequestSheetState extends State<RideRequestSheet>
    with TickerProviderStateMixin {
  bool _rideTaken = false;
  String _unavailableTitle = 'Request Unavailable';
  String _unavailableMessage = 'Another driver was faster.\nBetter luck next time!';

  late AnimationController _takenAnimController;
  late Animation<double> _takenFadeAnim;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _takenAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _takenFadeAnim = CurvedAnimation(parent: _takenAnimController, curve: Curves.easeOut);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socket = Provider.of<DriverProvider>(context, listen: false).socket;
      final myRideId = widget.ride['_id']?.toString() ?? '';

      socket?.on('ride_taken', (data) {
        final takenRideId = data['rideId']?.toString() ?? '';
        if (!mounted) return;
        if (takenRideId.isEmpty || takenRideId == myRideId) {
          _handleRideTaken('Request Unavailable', 'Another driver was faster.\nBetter luck next time!');
        }
      });

      socket?.on('ride_cancelled', (data) {
        final takenRideId = data['rideId']?.toString() ?? '';
        if (!mounted) return;
        if (takenRideId.isEmpty || takenRideId == myRideId) {
          _handleRideTaken('Request Cancelled', 'The passenger cancelled the request.');
        }
      });
    });
  }

  void _handleRideTaken(String title, String message) {
    if (!mounted || _rideTaken) return;
    
    // Stop ringing IMMEDIATELY
    NotificationService().stopSound();

    setState(() {
      _rideTaken = true;
      _unavailableTitle = title;
      _unavailableMessage = message;
    });
    
    _takenAnimController.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _takenAnimController.dispose();
    _pulseController.dispose();
    final socket = Provider.of<DriverProvider>(context, listen: false).socket;
    socket?.off('ride_taken');
    socket?.off('ride_cancelled');
    super.dispose();
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

  String _formatDuration(dynamic duration) {
    if (duration == null) return 'N/A';
    double mins = 0;
    if (duration is num) {
      mins = duration.toDouble();
    } else if (duration is String) {
      mins = double.tryParse(duration) ?? 0;
    }

    if (mins < 1) {
      int secs = (mins * 60).round();
      return '$secs sec';
    }
    int m = mins.floor();
    int s = ((mins - m) * 60).round();
    if (m < 5 && s > 5) return '$m min $s sec';
    return '$m min';
  }

  Widget _point(String title, String subtitle, Color color, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, spreadRadius: 1)
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.black12,
              )
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTimeline(Map<String, dynamic> ride) {
    final pickup = ride['pickup']?['address'] ?? 'Fetching pickup location...';
    final drop = ride['drop']?['address'] ?? 'Fetching drop-off location...';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _point("PICKUP LOCATION", pickup, Colors.green, false),
          _point("DROP-OFF LOCATION", drop, Colors.red, true),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.black, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStats(Map<String, dynamic> ride) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statBox(Icons.route_outlined, '${ride['distance']} km', 'Distance'),
          Container(width: 1, height: 40, color: Colors.black12),
          _statBox(Icons.schedule, _formatDuration(ride['duration']), 'Duration'),
        ],
      ),
    );
  }

  Widget _buildPassenger(Map<String, dynamic> ride) {
    final name = _getCustomerName(ride);
    final userData = (ride['userId'] is Map) ? ride['userId'] : ((ride['user'] is Map) ? ride['user'] : null);
    final rating = userData?['rating'] ?? 5.0;
    final avatar = userData?['avatar'];
    final fare = ride['fare'] ?? '0';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFF0F0F0),
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null ? const Icon(Icons.person, color: Colors.black54, size: 28) : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05), 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(rating.toString(), style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹$fare', style: TextStyle(color: Colors.green.shade700, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Courier')),
            const SizedBox(height: 2),
            const Text('Estimated Fare', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final isEmergency = ride['isEmergency'] == true || ride['is_emergency'] == true || ride['type'] == 'emergency';

    return SafeArea(
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: -5, offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isEmergency ? Colors.red.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(isEmergency ? Icons.warning_amber_rounded : Icons.local_taxi, color: isEmergency ? Colors.red : Colors.black),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEmergency ? 'EMERGENCY ASSIGNMENT' : 'NEW RIDE REQUEST',
                                    style: TextStyle(color: isEmergency ? Colors.red : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('Passenger is waiting...', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 28),
                        _buildPassenger(ride),
                        const SizedBox(height: 28),
                        _buildTimeline(ride),
                        const SizedBox(height: 24),
                        _buildStats(ride),
                        const SizedBox(height: 32),

                        if (isEmergency)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.car_crash, color: Colors.red, size: 28),
                                SizedBox(width: 16),
                                Expanded(child: Text("Car breakdown reported. You are assigned as the replacement vehicle.", style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: _rideTaken ? null : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.black26),
                                  padding: const EdgeInsets.symmetric(vertical: 22),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  backgroundColor: Colors.transparent,
                                ),
                                child: const Text('DECLINE', style: TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isEmergency ? Colors.red : Colors.black,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 22),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        elevation: 8,
                                        shadowColor: (isEmergency ? Colors.red : Colors.black).withValues(alpha: 0.5),
                                      ),
                                      onPressed: _rideTaken ? null : () => _acceptRide(context, ride, isEmergency),
                                      child: Text(
                                        isEmergency ? 'ACCEPT EMERGENCY' : 'ACCEPT RIDE',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_rideTaken)
            Positioned.fill(
              child: FadeTransition(
                opacity: _takenFadeAnim,
                child: Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red.shade200, width: 2),
                          ),
                          child: const Icon(Icons.block, color: Colors.red, size: 40),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _unavailableTitle,
                          style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _unavailableMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54, fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _acceptRide(BuildContext context, Map<String, dynamic> ride, bool isEmergency) async {
    // 🛑 Stop sound/vibration immediately upon tapping ACCEPT 🛑
    NotificationService().stopSound();
    
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    if (isEmergency) {
      final success = await driverProvider.acceptEmergency(ride['breakdownId'].toString());
      if (success && context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => CustomerPickupScreen(ride: ride)));
      }
    } else {
      final acceptedRide = await driverProvider.acceptRide(ride['_id']);
      if (acceptedRide != null && context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => CustomerPickupScreen(ride: acceptedRide)));
      }
    }
  }
}


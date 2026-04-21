import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:taxi_driver/src/core/providers/ride_provider.dart';
import 'package:taxi_driver/src/features/trips/screens/trip_details_screen.dart';
import 'package:taxi_driver/src/features/navigation/main_navigation_screen.dart';

enum TripStatus { completed, cancelled, disputed }

class TripData {
  final String dateStr;
  final DateTime dateTime;
  final String tripId;
  final String price;
  final String rating;
  final String startLoc;
  final String startSub;
  final String endLoc;
  final String endSub;
  final String duration;
  final String distance;
  final TripStatus status;
  final String? cancelledReason;

  TripData({
    required this.dateStr,
    required this.dateTime,
    required this.tripId,
    required this.price,
    required this.rating,
    required this.startLoc,
    required this.startSub,
    required this.endLoc,
    required this.endSub,
    required this.duration,
    required this.distance,
    required this.status,
    this.cancelledReason,
  });
}

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  String _selectedTimeFilter = 'This Week';
  String _selectedStatusFilter = 'All';

  // Initialize with empty list to avoid LateInitializationError during hot reloads
  List<TripData> _allTrips = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RideProvider>(context, listen: false).fetchRideHistory();
    });
  }
  
  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
  
  String _formatTime(DateTime date) {
    int hour = date.hour;
    String period = 'AM';
    if (hour >= 12) {
      period = 'PM';
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  List<dynamic> get _filteredTrips {
    final rideProvider = Provider.of<RideProvider>(context);
    final allRides = rideProvider.rideHistory;

    return allRides.where((ride) {
      final tripDate = DateTime.parse(ride['createdAt']);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tripDateDay = DateTime(tripDate.year, tripDate.month, tripDate.day);

      // 1. Time Filter
      bool timeMatch = false;
      if (_selectedTimeFilter == 'Today') {
        timeMatch = tripDateDay.isAtSameMomentAs(today);
      } else if (_selectedTimeFilter == 'This Week') {
        final diff = today.difference(tripDateDay).inDays;
        timeMatch = diff >= 0 && diff <= 6;
      } else if (_selectedTimeFilter == 'Last Week') {
        final diff = today.difference(tripDateDay).inDays;
        timeMatch = diff >= 7 && diff <= 13;
      } else if (_selectedTimeFilter == 'This Month') {
        timeMatch = tripDateDay.month == now.month && tripDateDay.year == now.year;
      } else {
        timeMatch = true;
      }

      // 2. Status Filter
      bool statusMatch = false;
      final status = ride['status'];
      if (_selectedStatusFilter == 'All') {
        statusMatch = true;
      } else if (_selectedStatusFilter == 'Completed') {
        statusMatch = status == 'completed';
      } else if (_selectedStatusFilter == 'Cancelled') {
        statusMatch = status == 'cancelled';
      } else {
        statusMatch = true;
      }

      return timeMatch && statusMatch;
    }).toList();
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return 'N/A';
    double mins = 0;
    if (duration is num) mins = duration.toDouble();
    else if (duration is String) mins = double.tryParse(duration) ?? 0;
    if (mins < 1) return '${(mins * 60).round()} sec';
    int m = mins.floor();
    int s = ((mins - m) * 60).round();
    if (m < 5 && s > 5) return '$m min $s sec';
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              MainNavigationScreen.goToHome(context);
            }
          },
        ),
        title: const Text(
          'Trip History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                // 1. Time Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildTimeFilter('Today'),
                      _buildTimeFilter('This Week'),
                      _buildTimeFilter('Last Week'),
                      _buildTimeFilter('This Month'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 2. Status Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatusFilter('All'),
                      _buildStatusFilter('Completed'),
                      _buildStatusFilter('Cancelled'),
                      _buildStatusFilter('Disputed'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Provider.of<RideProvider>(context, listen: false).fetchRideHistory();
              },
              child: _filteredTrips.isEmpty 
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('No trips found', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTrips.length + 1, // +1 for Load More button
                    itemBuilder: (context, index) {
                      if (index == _filteredTrips.length) {
                         return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'Load More',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        );
                      }
                      
                      final trip = _filteredTrips[index];
                      return _buildTripCard(trip);
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(String label) {
    bool isSelected = _selectedTimeFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(String label) {
    bool isSelected = _selectedStatusFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(dynamic ride) {
    bool isCancelled = ride['status'] == 'cancelled';
    final tripDate = DateTime.parse(ride['createdAt']);
    final dateStr = DateFormat('MMM d, h:mm a').format(tripDate);
    final price = '₹${ride['fare']}';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TripDetailsScreen(ride: ride)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isCancelled ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCancelled ? Icons.close : Icons.check,
                      color: isCancelled ? Colors.red : Colors.green,
                      size: 12,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCancelled ? Colors.grey.shade400 : Colors.black,
                    ),
                  ),
                  if (isCancelled)
                     const Text(
                      'Cancelled',
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
          Text(
            'Trip ID: #${ride['_id'].toString().substring(ride['_id'].toString().length - 6).toUpperCase()} • ${_formatDuration(ride['duration'])}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 16),

          _buildLocationRow(
            color: isCancelled ? Colors.grey.shade300 : const Color(0xFF00C853),
            title: ride['pickup']?['address'] ?? 'Unknown Pickup',
            subtitle: '',
            isFirst: true,
          ),
          _buildLocationRow(
            color: isCancelled ? Colors.grey.shade300 : const Color(0xFFFF3D00),
            title: ride['drop']?['address'] ?? 'Unknown Drop',
            subtitle: '',
            isLast: true,
          ),
          
          const SizedBox(height: 16),
          
          if (!isCancelled)
             Row(
               children: [
                 Icon(Icons.access_time_filled, size: 14, color: Colors.grey.shade400),
                 const SizedBox(width: 4),
                 Text(_formatDuration(ride['duration']), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                 const SizedBox(width: 16),
                 Icon(Icons.directions_car, size: 14, color: Colors.grey.shade400),
                 const SizedBox(width: 4),
                 Text('${ride['distance'] ?? 0} km', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                 const Spacer(),
                 Icon(Icons.chevron_right, color: Colors.grey.shade400),
               ],
             ),
        ],
      ),
      ),
    );
  }

  Widget _buildLocationRow({
    required Color color,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 4),
            Icon(Icons.circle, size: 12, color: color),
             if (!isLast)
              Container(
                width: 1,
                height: 34,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

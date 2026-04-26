import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:taxi_driver/src/core/providers/earnings_provider.dart';
import 'package:taxi_driver/src/core/providers/ride_provider.dart';
import 'package:taxi_driver/src/features/trips/screens/trip_history_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _selectedPeriod = 'Today';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final earnings = Provider.of<EarningsProvider>(context, listen: false);
      earnings.fetchEarnings();
      Provider.of<RideProvider>(context, listen: false).fetchRideHistory();
    });
  }

  double _getEarningsForPeriod(EarningsProvider earnings) {
    switch (_selectedPeriod) {
      case 'Today':
        return earnings.todayEarnings;
      case 'This Week':
        return earnings.weekEarnings;
      case 'This Month':
        return earnings.monthEarnings;
      case 'Total':
        return earnings.totalEarnings;
      default:
        return earnings.todayEarnings;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Earnings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.black, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Consumer2<EarningsProvider, RideProvider>(
        builder: (context, earnings, rides, _) {
          if (earnings.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final filteredRides = rides.rideHistory.where((r) {
            final date = DateTime.parse(r['createdAt']);
            final now = DateTime.now();
            if (_selectedPeriod == 'Today') {
              return date.day == now.day && date.month == now.month && date.year == now.year;
            } else if (_selectedPeriod == 'This Week') {
              final weekAgo = now.subtract(const Duration(days: 7));
              return date.isAfter(weekAgo);
            } else if (_selectedPeriod == 'This Month') {
              return date.month == now.month && date.year == now.year;
            }
            return true;
          }).toList();

          final earningsValue = _getEarningsForPeriod(earnings);
          final tripCount = filteredRides.length;
          final avgTrip = tripCount > 0 ? earningsValue / tripCount : 0.0;

          // Check driver type from earnings data
          final driverData = earnings.earningsData;
          final driverType = driverData['driverType'] ?? 'commission';
          final isSalaryBased = driverType == 'salary';

          return RefreshIndicator(
            onRefresh: () async {
              await earnings.fetchEarnings();
              await rides.fetchRideHistory();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Salary-Based Driver Info Banner
                    if (isSalaryBased) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade200,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Salary-Based Driver',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Fixed monthly salary plan',
                                        style: TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.white, size: 18),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Trip earnings are not credited to your wallet. You receive a fixed salary.',
                                      style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Commission-Based Driver: Time Filters & Earnings
                    if (!isSalaryBased) ...[
                      // 1. Time Filters
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Today'),
                            _buildFilterChip('This Week'),
                            _buildFilterChip('This Month'),
                            _buildFilterChip('Total'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Main Earnings Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$_selectedPeriod Earnings',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Text('₹ ${earningsValue.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedPeriod == 'Today' 
                                        ? DateFormat('EEEE, MMM d').format(DateTime.now())
                                        : 'Based on your activity',
                                      style: const TextStyle(color: Colors.white54, fontSize: 12)
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.show_chart, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatItem('$tripCount', 'Trips'),
                                _buildStatItem((tripCount * 0.8).toStringAsFixed(1), 'Online Hrs'),
                                _buildStatItem('₹${avgTrip.toStringAsFixed(1)}', 'Avg/Trip'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Simulated Graph Line
                            SizedBox(
                              height: 60,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _GraphPainter(),
                              )
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],

                    // 3. Trip Details (shown for both types)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isSalaryBased ? 'Recent Trip History' : '$_selectedPeriod Trip Details',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (filteredRides.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('No trips found for this period', style: TextStyle(color: Colors.grey.shade500)),
                        ),
                      )
                    else
                      ...filteredRides.take(5).map((ride) => _buildTripCard(
                        DateFormat('MMM d, h:mm a').format(DateTime.parse(ride['createdAt'])),
                        '${ride['distance'] ?? 0} km',
                        ride['pickup']?['address']?.split(',')[0] ?? 'Pickup',
                        ride['drop']?['address']?.split(',')[0] ?? 'Drop',
                        '₹${ride['fare']}',
                        '5.0'
                      )),

                    if (filteredRides.length > 5)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const TripHistoryScreen()));
                          },
                          child: Text('View All ${filteredRides.length} Trips', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // 5. View Payouts Button (only for commission-based)
                    if (!isSalaryBased) ...[
                      InkWell(
                        onTap: () {
                          // Navigate to payout settings or history
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.credit_card, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('View Payouts',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                   Text('Manage payment methods',
                                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedPeriod == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = label;
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
            fontSize: 13
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }


  Widget _buildTripCard(String time, String distance, String start, String end,
      String amount, String rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(time,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(' • $distance',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
              Text(amount,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$start → $end',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Row(
                children: [
                   const Icon(Icons.star, color: Colors.amber, size: 14),
                   const SizedBox(width: 4),
                   Text(rating,
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
           const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
           Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(2),
                 decoration: BoxDecoration(
                   color: Colors.green.withValues(alpha: 0.1),
                   shape: BoxShape.circle
                 ),
                 child: const Icon(Icons.check, color: Colors.green, size: 14)
               ),
               const SizedBox(width: 8),
               Text('Completed', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
               const Spacer(),
               Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18)
             ],
           )

        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.8, size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.4, size.width, size.height * 0.5);
    
    // Draw line
    canvas.drawPath(path, paint);
    
    // Draw gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
      
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
         Colors.white.withValues(alpha: 0.2),
         Colors.white.withValues(alpha: 0.0),
      ],
    );
    
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

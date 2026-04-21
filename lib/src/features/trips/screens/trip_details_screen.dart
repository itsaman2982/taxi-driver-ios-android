import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/providers/driver_provider.dart';

class TripDetailsScreen extends StatelessWidget {
  final dynamic ride;
  const TripDetailsScreen({super.key, this.ride});

  String _formatDuration(dynamic duration) {
    if (duration == null) return 'N/A';
    double mins = 0;
    if (duration is num)
      mins = duration.toDouble();
    else if (duration is String) mins = double.tryParse(duration) ?? 0;
    if (mins < 1) return '${(mins * 60).round()} sec';
    int m = mins.floor();
    int s = ((mins - m) * 60).round();
    if (m < 5 && s > 5) return '$m min $s sec';
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final pickupLat = (ride?['pickup']?['lat'] as num?)?.toDouble() ?? 0.0;
    final pickupLng = (ride?['pickup']?['lng'] as num?)?.toDouble() ?? 0.0;
    final dropLat = (ride?['drop']?['lat'] as num?)?.toDouble() ?? 0.0;
    final dropLng = (ride?['drop']?['lng'] as num?)?.toDouble() ?? 0.0;
    final pickupPoint = latlng.LatLng(pickupLat, pickupLng);
    final dropPoint = latlng.LatLng(dropLat, dropLng);
    final center =
        latlng.LatLng((pickupLat + dropLat) / 2, (pickupLng + dropLng) / 2);

    // Check driver type
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final driverType = driverProvider.driver?['driverType'];
    final isSalaryDriver = driverType == 'salary';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Trip Details',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (ride != null && ride['createdAt'] != null)
              Text(
                DateFormat('MMM d, h:mm a')
                    .format(DateTime.parse(ride['createdAt'])),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map View
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: pickupLat == 0.0 || dropLat == 0.0
                        ? Container(
                            color: Colors.grey.shade100,
                            alignment: Alignment.center,
                            child: Text(
                              'Map not available',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : FlutterMap(
                            options: MapOptions(
                              initialCenter: center,
                              initialZoom: 11.8,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.qis.taxidriver',
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: [pickupPoint, dropPoint],
                                    strokeWidth: 4,
                                    color: Colors.black.withOpacity(0.15),
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: pickupPoint,
                                    width: 36,
                                    height: 36,
                                    child: const Icon(Icons.location_on,
                                        color: Color(0xFF10B981), size: 30),
                                  ),
                                  Marker(
                                    point: dropPoint,
                                    width: 36,
                                    height: 36,
                                    child: const Icon(Icons.location_on,
                                        color: Color(0xFFEF4444), size: 30),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  // Distance badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.straighten,
                              size: 14, color: Colors.black87),
                          const SizedBox(width: 4),
                          Text(
                            '${ride?['distance'] ?? 0} km',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Earnings Card
            if (!isSalaryDriver)
              Center(
                child: Column(
                  children: [
                    Text(
                      '₹${ride?['fare'] ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Earnings',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Trip Completed',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Trip Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Trip ID',
                      '#${ride != null ? ride['_id'].toString().substring(ride['_id'].toString().length - 8).toUpperCase() : ''}'),
                  _buildInfoRow('Duration', _formatDuration(ride?['duration'])),
                  _buildInfoRow('Distance', '${ride?['distance'] ?? 0} km'),
                  _buildInfoRow('Status',
                      (ride?['status'] ?? '').toString().toUpperCase()),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if ((ride?['rating'] as num?)?.toDouble() != null ||
                (ride?['review']?.toString().trim().isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Review',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFF59E0B), size: 22),
                              const SizedBox(width: 8),
                              Text(
                                ((ride?['rating'] as num?)?.toDouble() ?? 0) > 0
                                    ? ((ride?['rating'] as num?)!.toDouble())
                                        .toStringAsFixed(1)
                                    : 'No rating yet',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                          if ((ride?['review']?.toString().trim().isNotEmpty ??
                              false)) ...[
                            const SizedBox(height: 12),
                            Text(
                              ride['review'].toString(),
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Route Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Route Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLocationCard(
                    icon: Icons.circle,
                    iconColor: const Color(0xFF10B981),
                    title: 'Pickup Location',
                    address: ride?['pickup']?['address'] ?? 'Unknown',
                    details: '',
                    time: '',
                  ),
                  const SizedBox(height: 16),
                  _buildLocationCard(
                    icon: Icons.circle,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Drop-off Location',
                    address: ride?['drop']?['address'] ?? 'Unknown',
                    details: '',
                    time: '',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Fare Breakdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fare Breakdown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFareRow('Total Fare', '₹${ride?['fare'] ?? '0.00'}',
                      isBold: true),
                  _buildFareRow('Distance (${ride?['distance'] ?? 0} km)',
                      '₹${ride?['fare'] ?? '0.00'}'),
                  const Divider(height: 24),
                  _buildFareRow(
                      'Payment Method',
                      (ride?['paymentMethod'] ?? 'Unknown')
                          .toString()
                          .toUpperCase()),
                  if (!isSalaryDriver) ...[
                    const Divider(height: 24),
                    _buildFareRow('Net Earnings (80%)',
                        '₹${((ride?['fare'] ?? 0) * 0.8).toStringAsFixed(2)}',
                        isGreen: true, isBold: true, isLarge: true),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Passenger Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Passenger Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey,
                          backgroundImage: ride?['userId']?['avatar'] != null
                              ? NetworkImage(ride['userId']['avatar'])
                              : null,
                          child: ride?['userId']?['avatar'] == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride?['userId']?['name'] ?? 'Passenger',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Color(0xFFF59E0B), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${ride?['userId']?['rating'] ?? 5.0} passenger rating',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.warning,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'Report an Issue with this Trip',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(Icons.headset_mic,
                              color: Colors.grey.shade700, size: 18),
                          label: Text(
                            'Contact Support',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.share,
                              color: Colors.white, size: 18),
                          label: const Text(
                            'Share Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
    required String details,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(String label, String amount,
      {bool isBold = false,
      bool isRed = false,
      bool isGreen = false,
      bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isRed ? const Color(0xFFEF4444) : Colors.grey.shade700,
              fontSize: isLarge ? 15 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Flexible(
            child: Text(
              amount,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isGreen
                    ? const Color(0xFF10B981)
                    : (isRed ? const Color(0xFFEF4444) : Colors.black),
                fontSize: isLarge ? 18 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(String rating, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            rating,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => const Icon(
                Icons.star,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

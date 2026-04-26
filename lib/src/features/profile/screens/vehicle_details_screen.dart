import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/providers/driver_provider.dart';

class VehicleDetailsScreen extends StatelessWidget {
  const VehicleDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          driverProvider.isFleetDriver ? 'Assigned Vehicle' : 'Vehicle Details',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<DriverProvider>(
        builder: (context, driverProvider, child) {
          final driver = driverProvider.driver;
          
          // If fleet driver but vehicle is just an ID (not map), it will be null.
          // Trigger a silent refresh to populate the data.
          if (driverProvider.isFleetDriver && driver?['vehicleId'] != null && driver?['vehicleId'] is! Map) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              driverProvider.refreshProfile();
            });
          }

          final vehicle = driverProvider.isFleetDriver 
              ? (driver?['vehicleId'] is Map ? driver!['vehicleId'] : null)
              : driver?['vehicle'];
          
          // Use real-time assigned vehicle keys from backend
          final type = vehicle?['vehicleType'] ?? vehicle?['type'] ?? (driverProvider.isFleetDriver ? 'Loading...' : 'N/A');
          String modelName = vehicle?['makeModel'] ?? '${vehicle?['make'] ?? ''} ${vehicle?['model'] ?? ''}'.trim();
          if (modelName.isEmpty) modelName = driverProvider.isFleetDriver ? 'Loading...' : 'N/A';
          final color = vehicle?['vehicleColor'] ?? vehicle?['color'] ?? (driverProvider.isFleetDriver ? 'Loading...' : 'N/A');
          final year = (vehicle?['yearOfManufacture'] ?? vehicle?['year'])?.toString() ?? (driverProvider.isFleetDriver ? '...' : 'N/A');
          final plate = vehicle?['licensePlate'] ?? vehicle?['plate'] ?? (driverProvider.isFleetDriver ? 'Fetching...' : 'N/A');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
            // 1. Vehicle Photos Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  // Exterior
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Exterior Photo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      GestureDetector(
                        onTap: () {},
                        child: const Row(
                          children: [
                            Icon(Icons.camera_alt, size: 14),
                            SizedBox(width: 4),
                            Text('Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.directions_car, size: 40, color: Colors.grey.shade400),
                    ),
                  ),

                   const SizedBox(height: 20),

                   // Interior
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Interior Photo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      GestureDetector(
                        onTap: () {},
                        child: const Row(
                          children: [
                            Icon(Icons.camera_alt, size: 14),
                            SizedBox(width: 4),
                            Text('Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.airline_seat_recline_extra, size: 40, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Vehicle Information Form
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                 boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                       const Text('Assigned Vehicle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       if (driverProvider.isFleetDriver)
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                           decoration: BoxDecoration(
                             color: const Color(0xFFF0F9FF),
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: const Text('Company Owned', style: TextStyle(color: Color(0xFF0369A1), fontSize: 10, fontWeight: FontWeight.bold)),
                         ),
                     ],
                   ),
                   const SizedBox(height: 20),

                   _buildLabel('Vehicle Type'),
                   _buildTextField(value: type, hasEditLink: !driverProvider.isFleetDriver),
                   const SizedBox(height: 16),

                   _buildLabel('Make & Model'),
                   _buildTextField(value: modelName, hasEditLink: !driverProvider.isFleetDriver),
                   const SizedBox(height: 16),

                   _buildLabel('Color'),
                   _buildTextField(value: color, hasEditLink: !driverProvider.isFleetDriver),
                   const SizedBox(height: 16),

                   _buildLabel('Year of Manufacture'),
                   _buildTextField(value: year, hasEditLink: !driverProvider.isFleetDriver),
                   const SizedBox(height: 16),

                   _buildLabel('License Plate Number'),
                   _buildTextField(value: plate, isBold: true, textAlign: TextAlign.center, hasEditLink: !driverProvider.isFleetDriver),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Associated Documents
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                 boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       const Text('Associated Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       TextButton.icon(
                         onPressed: (){}, 
                         icon: const Icon(Icons.arrow_forward, size: 14),
                         label: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                         style: TextButton.styleFrom(
                           padding: EdgeInsets.zero,
                           minimumSize: Size.zero,
                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                           iconColor: Colors.blue,
                           foregroundColor: Colors.blue,
                         ),
                       )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDocItem(
                    title: 'Vehicle Registration',
                    status: 'Approved',
                    color: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF10B981),
                    icon: Icons.description,
                  ),
                  const SizedBox(height: 12),
                  _buildDocItem(
                    title: 'Insurance',
                    status: 'Expires in 5 days',
                    color: const Color(0xFFFFFBEB),
                    iconColor: const Color(0xFFF59E0B),
                    icon: Icons.security,
                    isWarning: true,
                  ),
                  const SizedBox(height: 12),
                   _buildDocItem(
                    title: 'Vehicle Inspection',
                    status: 'Valid until Dec 2025',
                    color: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF10B981),
                    icon: Icons.verified,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (driverProvider.isFleetDriver)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Color(0xFF0369A1), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This vehicle is officially assigned to you by the company fleet manager.',
                        style: TextStyle(color: Color(0xFF0C4A6E), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),

            // 4. Action Buttons
            if (!driverProvider.isFleetDriver)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                  label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            if (!driverProvider.isFleetDriver) const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: driverProvider.isFleetDriver ? Colors.black : const Color(0xFFFFE5E5),
                  foregroundColor: driverProvider.isFleetDriver ? Colors.white : const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(driverProvider.isFleetDriver ? Icons.arrow_back : Icons.close, size: 20),
                label: Text(driverProvider.isFleetDriver ? 'Go Back' : 'Cancel', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
             const SizedBox(height: 40),
          ],
        ),
      );
    },
  ),
);
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String value, 
    bool hasEditLink = false, 
    bool isBold = false,
    TextAlign textAlign = TextAlign.start
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: textAlign,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, 
                fontSize: isBold? 16 : 14,
                letterSpacing: isBold ? 1.0 : 0
              ),
            ),
          ),
          if (hasEditLink)
             const Text(
               'Edit', 
               style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)
             ),
        ],
      ),
    );
  }

  Widget _buildDocItem({
    required String title,
    required String status,
    required Color color,
    required Color iconColor,
    required IconData icon,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)), // slightly darker border
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Color.lerp(Colors.black, iconColor, 0.4), fontWeight: FontWeight.bold, fontSize: 13)),
                Text(status, style: TextStyle(color: isWarning ? const Color(0xFF92400E) : const Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
           Icon(
             isWarning ? Icons.warning : Icons.check_circle, 
             color: isWarning ? const Color(0xFFD97706) : const Color(0xFF10B981), // darker warning icon
             size: 18
           )
        ],
      ),
    );
  }
}

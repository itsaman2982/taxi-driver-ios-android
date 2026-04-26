import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/api/api_service.dart';
import 'package:taxi_driver/src/core/providers/driver_provider.dart';
import 'package:taxi_driver/src/features/navigation/main_navigation_screen.dart';
import 'package:taxi_driver/src/features/profile/screens/personal_information_screen.dart';
import 'package:taxi_driver/src/features/profile/screens/vehicle_details_screen.dart';
import 'package:taxi_driver/src/features/documents/screens/documents_screen.dart';
import 'package:taxi_driver/src/features/payouts/screens/payout_settings_screen.dart';
import 'package:taxi_driver/src/features/notifications/screens/notifications_screen.dart';
import 'package:taxi_driver/src/features/settings/screens/settings_screen.dart';
import 'package:taxi_driver/src/features/support/screens/driver_support_screen.dart';
import 'package:taxi_driver/src/features/profile/screens/terms_conditions_screen.dart';
import 'package:taxi_driver/src/features/profile/screens/data_security_screen.dart';
import 'package:taxi_driver/src/features/profile/screens/privacy_policy_screen.dart';
import 'package:taxi_driver/src/features/support/screens/contact_support_screen.dart';
import 'package:taxi_driver/src/features/auth/screens/signin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(BuildContext context, String driverId) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change Profile Photo'),
          content: const Text('Choose a source for your new profile photo'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text('Gallery'),
            ),
          ],
        ),
      );

      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // 1. Upload file
      final uploadResponse = await ApiService().uploadFile('uploads', File(image.path));
      
      if (uploadResponse['success'] == true) {
        final imageUrl = uploadResponse['data']['url'];
        
        // 2. Update user profile
        final updateResponse = await ApiService().patch('users/$driverId', {
          'avatar': imageUrl,
        });
        
        if (updateResponse['success'] == true) {
          // 3. Refresh Provider
          if (context.mounted) {
            await Provider.of<DriverProvider>(context, listen: false).refreshProfile();
          }
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated!')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              MainNavigationScreen.goToHome(context);
            }
          },
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<DriverProvider>(
        builder: (context, driverProvider, child) {
          final driver = driverProvider.driver;
          final driverId = driver?['_id'] ?? driver?['id'] ?? '';
          final driverName = driver?['name'] ?? 'Driver';
          final driverEmail = driver?['email'] ?? '';
          final driverPhone = driver?['phone'] ?? '';
          final driverRating = (driver?['rating'] ?? 4.9).toDouble();
          final totalTrips = driver?['totalTrips'] ?? 0;
          final driverStatus = driver?['status'] ?? 'active';
          final vehicleInfo = driverProvider.isFleetDriver 
              ? (driver?['vehicleId'] is Map ? driver!['vehicleId'] : null)
              : driver?['vehicle'];
          final avatarUrl = driver?['avatar'];
          final driverType = driver?['driverType'] ?? 'commission';
          final isSalaryBased = driverType == 'salary';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.black, Color(0xFF1A1A1A)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const PersonalInformationScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey.shade800,
                              backgroundImage: avatarUrl != null 
                                  ? NetworkImage(avatarUrl) 
                                  : null,
                              child: avatarUrl == null && !_isUploading
                                  ? const Icon(Icons.person, size: 40, color: Colors.white54)
                                  : null,
                            ),
                          ),
                          if (_isUploading)
                             const Positioned.fill(
                              child: Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploading ? null : () => _pickAndUploadImage(context, driverId),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: _isUploading
                                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : const Icon(Icons.camera_alt, size: 12, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        driverName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: List.generate(5, (index) => Icon(
                              index < driverRating.floor() ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            )),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            driverRating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($totalTrips trips)',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: driverStatus == 'active' 
                                  ? const Color(0xFF0369A1) // Blue for verified account
                                  : driverStatus == 'suspended'
                                      ? const Color(0xFFEF4444) // Red for suspended
                                      : const Color(0xFFFFA000), // Amber for pending
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  driverStatus == 'active' 
                                      ? Icons.verified 
                                      : driverStatus == 'suspended'
                                          ? Icons.block
                                          : Icons.pending,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  driverStatus == 'active' 
                                      ? 'Verified Driver' 
                                      : driverStatus == 'suspended'
                                          ? 'Account Suspended'
                                          : 'Pending Verification',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          if (driverProvider.isFleetDriver) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6D28D9), // Purple for fleet
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.business_center, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fleet Driver',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Menu Items
                _buildMenuItem(
                  icon: Icons.person,
                  title: 'Personal Information',
                  subtitle: driverEmail.isNotEmpty ? driverEmail : driverPhone,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PersonalInformationScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.directions_car,
                  title: driverProvider.isFleetDriver ? 'Assigned Vehicle' : 'Vehicle Details',
                  subtitle: vehicleInfo != null 
                      ? '${vehicleInfo['year'] ?? ''} ${vehicleInfo['make'] ?? ''} ${vehicleInfo['model'] ?? ''}${vehicleInfo['licensePlate'] != null ? ' • ${vehicleInfo['licensePlate']}' : ''}'.trim()
                      : (driverProvider.isFleetDriver ? 'Corporate Car Required' : 'No vehicle registered'),
                  footer: driverProvider.isFleetDriver && vehicleInfo != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFBAE6FD))),
                          child: const Text('Company Assigned', style: TextStyle(color: Color(0xFF0369A1), fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const VehicleDetailsScreen()),
                    );
                  },
                ),
            _buildMenuItem(
              icon: Icons.description,
              title: 'Documents',
              subtitle: 'License, insurance, registration',
              subtitleColor: Colors.grey.shade600,
              footer: const Text(
                'Insurance expires in 5 days',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              showBadge: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DocumentsScreen()),
                );
              },
            ),
            // Only show payout settings for commission-based drivers
            if (!isSalaryBased)
              _buildMenuItem(
                icon: Icons.credit_card,
                title: 'Payout Settings',
                subtitle: 'Bank accounts, payment history',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PayoutSettingsScreen()),
                  );
                },
              ),
            _buildMenuItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Sounds, alerts, messages',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.headset_mic,
              title: 'Support',
              subtitle: 'Help center, contact us, FAQs',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DriverSupportScreen()),
                );
              },
            ),
             _buildMenuItem(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'Language, map preferences, accessibility',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.contact_support,
              title: 'Contact Us',
              subtitle: 'Get help and support',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ContactSupportScreen()),
                );
              },
            ),

            const SizedBox(height: 24),

            // Legal & Privacy Section
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'Legal & Privacy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                   ),
                   const SizedBox(height: 16),
                   _buildLegalItem(context, Icons.shield_outlined, 'Privacy Policy', const PrivacyPolicyScreen()),
                   const Divider(),
                   _buildLegalItem(context, Icons.description_outlined, 'Terms & Conditions', const TermsConditionsScreen()),
                   const Divider(),
                   _buildLegalItem(context, Icons.lock_outline, 'Data & Security', const DataSecurityScreen()),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Info Section
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Driver App',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Version 3.2.1 (Build 1024)',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Last updated',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                      const Text(
                        'March 15, 2025',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  // Clear driver data
                  final driverProvider = Provider.of<DriverProvider>(context, listen: false);
                  driverProvider.logout();
                  
                  // Navigate to sign-in screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                    (route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE5E5), // Light Red
                  foregroundColor: const Color(0xFFEF4444), // Red
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
             const SizedBox(height: 50), // Add safe bottom padding
          ],
        ),
      );
    },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? subtitleColor,
    required VoidCallback onTap,
    Widget? footer,
    bool showBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F5FF), // Light Blue tint
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  Icon(icon, color: const Color(0xFF1E293B), size: 24),
                  if (showBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtitleColor ?? Colors.grey.shade600, fontSize: 13),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 4),
                    footer,
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalItem(BuildContext context, IconData icon, String title, Widget destination) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 18),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            const Spacer(),
            Icon(Icons.open_in_new, color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/api/api_service.dart';
import 'package:taxi_driver/src/core/providers/registration_provider.dart';
import 'package:taxi_driver/src/core/providers/driver_provider.dart';
import 'package:taxi_driver/src/features/navigation/main_navigation_screen.dart';

class ApplicationStatusScreen extends StatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  State<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  bool _notificationsEnabled = true;
  bool _isApproved = false;
  bool _isSubmitting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _submitRegistration();
  }

  Future<void> _submitRegistration() async {
    final registrationProvider = Provider.of<RegistrationProvider>(context, listen: false);
    final personalInfo = registrationProvider.personalInfo;
    final vehicleInfo = registrationProvider.vehicleInfo;
    final documents = registrationProvider.documents;

    print('🚀 Starting registration submission...');
    print('📝 Personal Info: $personalInfo');
    print('🚗 Vehicle Info: $vehicleInfo');
    print('📄 Documents: ${documents.keys.where((key) => documents[key] != null).toList()}');

    // Validate that we have the required data
    if (personalInfo.isEmpty) {
      setState(() {
        _isSubmitting = false;
        _error = 'Personal information is missing. Please go back and fill in all required fields.';
      });
      print('❌ Personal info is empty!');
      return;
    }

    if (personalInfo['phone'] == null || personalInfo['phone'].toString().isEmpty) {
      setState(() {
        _isSubmitting = false;
        _error = 'Phone number is required. Please go back and enter your phone number.';
      });
      print('❌ Phone is missing!');
      return;
    }

    if (personalInfo['password'] == null || personalInfo['password'].toString().isEmpty) {
      setState(() {
        _isSubmitting = false;
        _error = 'Password is required. Please go back and enter your password.';
      });
      print('❌ Password is missing!');
      return;
    }

    try {
      print('📞 Calling submitRegistration with phone: ${personalInfo['phone']}');
      
      final success = await registrationProvider.submitRegistration(
        personalInfo['phone'] ?? '',
        personalInfo['password'] ?? '',
      );

      print('✅ Registration submission result: $success');
      print('❌ Registration error: ${registrationProvider.error}');

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          if (success) {
            print('🎉 Registration successful!');
            // Simulate approval after 3 seconds for demo
            Timer(const Duration(seconds: 3), () async {
              if (mounted) {
                setState(() {
                  _isApproved = true;
                });
                
                // Auto-login to get token and populate DriverProvider
                try {
                  print('🔄 Attempting auto-login...');
                  final loginResponse = await ApiService().post('auth/login', {
                    'email': personalInfo['email'],
                    'password': personalInfo['password'],
                  });
                  
                  if (loginResponse['success'] == true && mounted) {
                     final driverData = Map<String, dynamic>.from(loginResponse['data']);
                     await Provider.of<DriverProvider>(context, listen: false).setDriver(driverData);
                     print('✅ Auto-login successful! Driver data set.');
                  } else {
                     print('⚠️ Auto-login failed: ${loginResponse['message']}');
                  }
                } catch (e) {
                    print('⚠️ Auto-login exception: $e');
                }
              }
            });
          } else {
            _error = registrationProvider.error ?? 'Registration failed. Please try again.';
            print('❌ Registration failed: $_error');
          }
        });
      }
    } catch (e) {
      print('💥 Exception during registration: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = 'Error: ${e.toString()}';
        });
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
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Application Status',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Centered Circular Status Icon
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _error != null 
                            ? Colors.red.withAlpha(12) 
                            : _isApproved 
                                ? Colors.green.withAlpha(12) 
                                : Colors.blue.withAlpha(12),
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _error != null 
                                ? Colors.red.withAlpha(25) 
                                : _isApproved 
                                    ? Colors.green.withAlpha(25) 
                                    : Colors.blue.withAlpha(25),
                          ),
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _error != null 
                                          ? Icons.error_outline 
                                          : _isApproved 
                                              ? Icons.check 
                                              : Icons.access_time_filled,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title and Subtitle
                  Text(
                    _error != null 
                        ? 'Registration Failed' 
                        : _isApproved 
                            ? 'Approved!' 
                            : _isSubmitting 
                                ? 'Submitting...' 
                                : 'Almost There!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error != null 
                        ? 'Please try again' 
                        : _isApproved 
                            ? 'You are ready to drive' 
                            : _isSubmitting 
                                ? 'Please wait...' 
                                : 'Application Under Review',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Error Box
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withAlpha(50)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 32),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Go Back'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Info Box
                  if (!_isApproved && _error == null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(color: Colors.grey.shade800, height: 1.5, fontSize: 13),
                          children: const [
                            TextSpan(text: 'Thank you for submitting your application! Our team is currently reviewing your documents and information. This process usually takes '),
                            TextSpan(
                              text: '2-3 business days.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  // Review Progress
                  const Text(
                    'Review Progress',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  
                  // Timeline Items
                  _buildTimelineItem(
                    icon: Icons.check,
                    iconBgColor: Colors.black,
                    iconColor: Colors.white,
                    title: 'Documents Submitted',
                    subtitle: 'All required documents received',
                    statusText: 'Completed',
                    statusColor: Colors.green,
                    isLast: false,
                    isCompleted: true,
                  ),
                  _buildTimelineItem(
                    icon: Icons.manage_search,
                    iconBgColor: _isApproved ? Colors.black : Colors.grey.shade600,
                    iconColor: Colors.white,
                    title: 'Background Verification',
                    subtitle: 'Verifying documents and conducting checks',
                    statusText: _isApproved ? 'Completed' : 'In Progress',
                    statusColor: _isApproved ? Colors.green : Colors.orange,
                    isLast: false,
                    isCompleted: _isApproved, // Completed if approved
                  ),
                   _buildTimelineItem(
                    icon: Icons.person_outline,
                    iconBgColor: _isApproved ? Colors.black : Colors.grey.shade300,
                    iconColor: Colors.white,
                    title: 'Final Approval',
                    subtitle: 'Final review and account activation',
                    statusText: _isApproved ? 'Approved' : 'Pending',
                    statusColor: _isApproved ? Colors.green : Colors.grey,
                    isLast: true,
                    isCompleted: _isApproved,
                  ),

                  const SizedBox(height: 24),
                  // Estimated Completion
                  if (!_isApproved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Estimated Completion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Within 2-3 business days', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               const Text('48-72h', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), fontSize: 14)),
                               const SizedBox(height: 2),
                               Text('Remaining', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                            ],
                          )
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  // Check Status / Go to Home Button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_isApproved) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: Icon(_isApproved ? Icons.home : Icons.refresh, color: Colors.white, size: 20),
                    label: Text(
                      _isApproved ? 'Go to Home' : 'Check Status',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isApproved ? const Color(0xFF10B981) : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Contact Support & View Application Buttons
                  if (!_isApproved)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.headset_mic_outlined, size: 18, color: Colors.black87),
                            label: const Text('Contact Support', style: TextStyle(color: Colors.black87, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.description_outlined, size: 18, color: Colors.black87),
                            label: const Text('View Application', style: TextStyle(color: Colors.black87, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                  // Status Notifications Toggle
                  if (!_isApproved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                           Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.all(Radius.circular(8))
                            ),
                            child: const Icon(Icons.notifications_active, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Status Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Get updates via SMS & Email', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _notificationsEnabled, 
                            onChanged: (val){ setState(() { _notificationsEnabled = val; }); },
                            activeColor: Colors.black,
                          )
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  // Need Help?
                  if (!_isApproved)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB), // Light yellow bg
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFEF3C7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.help_outline, size: 18, color: Colors.orange.shade800),
                              const SizedBox(width: 8),
                              Text(
                                'Need Help?',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'If you have any questions about your application status or need to update your documents, our support team is here to help.',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                               Icon(Icons.phone, size: 14, color: Colors.orange.shade900),
                               const SizedBox(width: 4),
                               Text('1-800-DRIVE-US', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 12)),
                               const SizedBox(width: 16),
                               Icon(Icons.email, size: 14, color: Colors.orange.shade900),
                               const SizedBox(width: 4),
                               Text('support@driveapp.com', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 40),
                  // Footer info
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text('Application ID: #DRV-2025-001234', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Submitted on March 15, 2025 at 2:30 PM', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      const SizedBox(height: 12),
                      if (!_isApproved)
                        Text(
                          'We\'ll notify you immediately once your application is approved',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
    required bool isLast,
    required bool isCompleted,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and line column
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.black, // Dark solid line as per design
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8), // Align text with top of icon roughly
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                     if (isCompleted) 
                       const Icon(Icons.check, size: 12, color: Colors.green),
                     if (!isCompleted && statusColor == Colors.orange)
                       const Icon(Icons.hourglass_empty, size: 12, color: Colors.orange),
                     if (!isCompleted && statusColor == Colors.grey)
                       const Icon(Icons.pending, size: 12, color: Colors.grey),
                     
                     if (isCompleted || statusColor == Colors.orange || statusColor == Colors.grey)
                        const SizedBox(width: 4),
                        
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (!isLast) const SizedBox(height: 24), // Spacing between items
              ],
            ),
          ),
        ],
      ),
    );
  }
}

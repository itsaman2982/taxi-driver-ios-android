import 'package:flutter/material.dart';
import 'package:taxi_driver/src/features/navigation/main_navigation_screen.dart';
import 'package:taxi_driver/src/features/notifications/screens/notifications_settings_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Today'),
          _buildNotificationItem(
            icon: Icons.local_offer,
            iconColor: const Color(0xFFF59E0B), // Amber
            title: 'Weekend Bonus Active!',
            body: 'Your ₹1,500 weekend bonus challenge has started. Complete 10 trips to unlock.',
            time: '2 hours ago',
            isUnread: true,
          ),
          _buildNotificationItem(
            icon: Icons.payments,
            iconColor: const Color(0xFF10B981), // Green
            title: 'Payment Received',
            body: 'You received a tip of ₹50 on your last trip from Sector 18.',
            time: '4 hours ago',
            isUnread: true,
          ),
          
          const SizedBox(height: 16),
          _buildSectionHeader('Yesterday'),
           _buildNotificationItem(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFEF4444), // Red
            title: 'Document Expiring Soon',
            body: 'Your Vehicle Insurance is expiring in 3 days. Please renew to avoid disruptions.',
            time: 'Yesterday, 10:00 AM',
            isUnread: false,
          ),
          _buildNotificationItem(
            icon: Icons.star,
            iconColor: const Color(0xFF3B82F6), // Blue
            title: 'New 5-Star Rating',
            body: 'Great job! A passenger rated you 5 stars: "Very polite and safe driver."',
            time: 'Yesterday, 8:45 AM',
            isUnread: false,
          ),
          _buildNotificationItem(
            icon: Icons.info_outline,
            iconColor: Colors.grey.shade700,
            title: 'System Maintenance',
            body: 'The driver app will undergo scheduled maintenance on Sunday, 2 AM - 4 AM.',
            time: 'Yesterday, 9:00 AM',
            isUnread: false,
          ),

          const SizedBox(height: 16),
          _buildSectionHeader('Last Week'),
          _buildNotificationItem(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF10B981),
            title: 'Weekly Payout Processed',
            body: 'Your weekly earnings of ₹8,450 have been transferred to your HDFC bank account.',
            time: 'Dec 20, 9:00 AM',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isUnread ? Colors.black : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          color: isUnread ? Colors.grey.shade600 : Colors.grey.shade500,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

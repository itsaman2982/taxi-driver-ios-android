import 'package:flutter/material.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  // State variables for switches
  bool _doNotDisturb = false;
  bool _soundForNewRequests = true;
  bool _vibrationForNewRequests = true;
  bool _passengerMessages = true;
  bool _navigationUpdates = false;
  bool _earningsSummary = true;
  bool _promotionsIncentives = true;
  bool _payoutConfirmation = true;
  bool _documentExpiration = true;
  bool _appUpdates = false;
  bool _securityAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ) : null,
        title: const Text(
          'Notifications Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // 1. Do Not Disturb
            _buildSettingCard(
              child: SwitchListTile(
                value: _doNotDisturb,
                onChanged: (val) => setState(() => _doNotDisturb = val),
                title: const Text('Do Not Disturb', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text('Pause all notifications except ride requests', style: TextStyle(fontSize: 12)),
                activeThumbColor: Colors.black,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),

            // 2. Ride Request Alerts
            _buildSectionCard(
              icon: Icons.directions_car,
              title: 'Ride Request Alerts',
              subtitle: 'Critical notifications for new ride requests',
              children: [
                _buildSwitchRow(
                  'Sound for New Requests',
                  'Play alert sound when new rides are available',
                  _soundForNewRequests,
                  (val) => setState(() => _soundForNewRequests = val),
                ),
                _buildSwitchRow(
                  'Vibration for New Requests',
                  'Vibrate device when new rides are available',
                  _vibrationForNewRequests,
                  (val) => setState(() => _vibrationForNewRequests = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. In-Trip Alerts
            _buildSectionCard(
              icon: Icons.notifications_active,
              title: 'In-Trip Alerts',
              subtitle: 'Notifications while you\'re driving',
              children: [
                _buildSwitchRow(
                  'Passenger Messages',
                  'Get notified when passengers send messages',
                  _passengerMessages,
                  (val) => setState(() => _passengerMessages = val),
                ),
                _buildSwitchRow(
                  'Navigation Updates',
                  'Route changes and traffic alerts',
                  _navigationUpdates,
                  (val) => setState(() => _navigationUpdates = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Account & Earnings
            _buildSectionCard(
              icon: Icons.currency_rupee,
              title: 'Account & Earnings',
              subtitle: 'Updates about your earnings and account',
              children: [
                _buildSwitchRow(
                  'Earnings Summary',
                  'Daily and weekly earnings reports',
                  _earningsSummary,
                  (val) => setState(() => _earningsSummary = val),
                ),
                _buildSwitchRow(
                  'Promotions & Incentives',
                  'Special offers and bonus opportunities',
                  _promotionsIncentives,
                  (val) => setState(() => _promotionsIncentives = val),
                ),
                _buildSwitchRow(
                  'Payout Confirmation',
                  'When payments are processed to your account',
                  _payoutConfirmation,
                  (val) => setState(() => _payoutConfirmation = val),
                ),
                _buildSwitchRow(
                  'Document Expiration Warnings',
                  'Important reminders before documents expire',
                  _documentExpiration,
                  (val) => setState(() => _documentExpiration = val),
                  isRecommended: true,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5. App & System Alerts
            _buildSectionCard(
              icon: Icons.smartphone,
              title: 'App & System Alerts',
              subtitle: 'Updates and security notifications',
              children: [
                _buildSwitchRow(
                  'App Updates & News',
                  'New features and platform announcements',
                  _appUpdates,
                  (val) => setState(() => _appUpdates = val),
                ),
                _buildSwitchRow(
                  'Security Alerts',
                  'Login attempts and account security',
                  _securityAlerts,
                  (val) => setState(() => _securityAlerts = val),
                  isRecommended: true,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. Sound Customization
            _buildSectionCard(
              icon: Icons.volume_up,
              title: 'Sound Customization',
              subtitle: 'Choose your alert sounds',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ride Request Sound', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('Current: Default Chime', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.music_note, size: 16),
                        label: const Text('Change', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Test Current Sound', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('Preview your selected alert sound', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Play', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged, {bool isRecommended = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.black,
              ),
            ],
          ),
          if (isRecommended)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Recommended',
                style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

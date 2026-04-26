// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:taxi_driver/src/features/settings/screens/about_screen.dart';
import 'package:taxi_driver/src/features/profile/screens/privacy_policy_screen.dart';
import 'package:taxi_driver/src/features/profile/screens/terms_conditions_screen.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showSelectionDialog(
    BuildContext context,
    String title,
    List<String> options,
    String currentValue,
    Function(String) onSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: currentValue,
                onChanged: (val) {
                  if (val != null) {
                    onSelected(val);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 30),
            children: [
              _buildSectionHeader('GENERAL PREFERENCES'),
              _buildListTile(
                icon: Icons.translate,
                title: 'Language',
                subtitle: settings.language,
                onTap: () => _showSelectionDialog(
                  context,
                  'Select Language',
                  ['English (US)', 'Spanish', 'French', 'Hindi', 'Gujarati'],
                  settings.language,
                  (val) => settings.setLanguage(val),
                ),
              ),
              _buildListTile(
                icon: Icons.navigation,
                title: 'Navigation App',
                subtitle: settings.navigationApp,
                onTap: () => _showSelectionDialog(
                  context,
                  'Navigation App',
                  ['Google Maps', 'Waze', 'Apple Maps'],
                  settings.navigationApp,
                  (val) => settings.setNavigationApp(val),
                ),
              ),
              _buildListTile(
                icon: Icons.map,
                title: 'Map Display',
                subtitle: settings.mapDisplay,
                onTap: () => _showSelectionDialog(
                  context,
                  'Map Display',
                  ['Standard, 2D', 'Standard, 3D View', 'Satellite', 'Hybrid'],
                  settings.mapDisplay,
                  (val) => settings.setMapDisplay(val),
                ),
              ),
              _buildListTile(
                icon: Icons.straighten,
                title: 'Units',
                subtitle: settings.units,
                onTap: () => _showSelectionDialog(
                  context,
                  'Distance Units',
                  ['Kilometers', 'Miles'],
                  settings.units,
                  (val) => settings.setUnits(val),
                ),
              ),
              _buildListTile(
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {},
              ),
              _buildSectionHeader('SOUND & VIBRATION'),
              _buildSwitchTile(
                icon: Icons.notifications_active,
                title: 'Ride Request Sound',
                subtitle: 'Classic Chime',
                value: settings.rideRequestSound,
                onChanged: (val) => settings.setRideRequestSound(val),
                activeColor: const Color(0xFF10B981),
              ),
              _buildSwitchTile(
                icon: Icons.chat_bubble,
                title: 'Message Sound',
                subtitle: settings.messageSound ? 'Enabled' : 'Disabled',
                value: settings.messageSound,
                onChanged: (val) => settings.setMessageSound(val),
                activeColor: const Color(0xFF10B981),
              ),
              _buildSwitchTile(
                icon: Icons.smartphone,
                title: 'Vibration for Alerts',
                subtitle: settings.vibration ? 'Enabled' : 'Disabled',
                value: settings.vibration,
                onChanged: (val) => settings.setVibration(val),
                activeColor: const Color(0xFF10B981),
              ),
              _buildSectionHeader('LEGAL & APP INFO'),
              _buildListTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Version 4.2.1',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutScreen()),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.description,
                title: 'Terms & Conditions',
                subtitle: 'View legal terms',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TermsConditionsScreen()),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'Data protection info',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen()),
                  );
                },
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.delete, size: 20),
                  label: const Text('Delete Account',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F5FF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color activeColor = Colors.grey,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F5FF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor:
            activeColor == Colors.grey ? Colors.grey.shade400 : activeColor,
        activeTrackColor: activeColor == const Color(0xFF10B981)
            ? const Color(0xFF10B981).withValues(alpha: 0.4)
            : Colors.grey.shade300,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade200,
      ),
    );
  }
}

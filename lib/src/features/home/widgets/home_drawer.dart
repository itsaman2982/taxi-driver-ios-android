import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/providers/driver_provider.dart';
import 'package:taxi_driver/src/features/profile/screens/profile_screen.dart';
import 'package:taxi_driver/src/features/earnings/screens/earnings_screen.dart';
import 'package:taxi_driver/src/features/trips/screens/trip_history_screen.dart';
import 'package:taxi_driver/src/features/payouts/screens/payout_settings_screen.dart';
import 'package:taxi_driver/src/features/documents/screens/documents_screen.dart';
import 'package:taxi_driver/src/features/support/screens/live_chat_screen.dart';
import 'package:taxi_driver/src/features/promotions/screens/promotions_screen.dart';
import 'package:taxi_driver/src/features/notifications/screens/notifications_screen.dart';
import 'package:taxi_driver/src/features/settings/screens/settings_screen.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // Header
          Consumer<DriverProvider>(
            builder: (context, provider, _) {
              final driver = provider.driver;
              final name = driver?['name'] ?? 'Driver';
              final rating = driver?['rating'] ?? 5.0;
              final avatar = driver?['profileImage'];

              return Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey,
                              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                              child: avatar == null ? const Icon(Icons.person, color: Colors.white) : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: Icon(Icons.circle, size: 10,  color: (driver?['isOnline'] ?? false) ? Colors.green : Colors.grey),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$rating Rating',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      ),
                      child: const Text('View Profile', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            },
          ),

          // Go Online Toggle
          Consumer<DriverProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.power_settings_new, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Go Online',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    Switch(
                      value: provider.driver?['isOnline'] ?? false,
                      onChanged: (value) => provider.toggleOnlineStatus(value),
                      activeThumbColor: Colors.black,
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  Icons.show_chart,
                  'Earnings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EarningsScreen()),
                    );
                  },
                ),

                _buildMenuItem(
                  Icons.history,
                  'Trip History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TripHistoryScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.credit_card,
                  'Payouts',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PayoutSettingsScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.description_outlined,
                  'Documents',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DocumentsScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.headset_mic_outlined,
                  'Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LiveChatScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.card_giftcard,
                  'Promotions',
                  badge: '3',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PromotionsScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.notifications_none,
                  'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.settings_outlined,
                  'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Invite Friend
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                ),
                 const SizedBox(width: 16),
                const Text(
                  'Invite a Friend',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '₹50',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                 const Spacer(),
                 const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Log Out
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: InkWell(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log Out', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final driverProvider = Provider.of<DriverProvider>(context, listen: false);
                  final navigator = Navigator.of(context);
                  driverProvider.logout();
                  navigator.popUntil((route) => route.isFirst);
                }
              },
              child: Row(
                children: [
                   Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout, color: Colors.red),
                   ),
                   const SizedBox(width: 16),
                   const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                   ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title,
      {String? badge, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: badge != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            )
          : const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap ?? () {},
    );
  }
}

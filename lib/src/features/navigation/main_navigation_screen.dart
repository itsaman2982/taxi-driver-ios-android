import 'package:flutter/material.dart';
import 'package:taxi_driver/src/features/home/screens/home_screen.dart';
import 'package:taxi_driver/src/features/trips/screens/trip_history_screen.dart';
import 'package:taxi_driver/src/features/notifications/screens/notifications_screen.dart';
import 'package:taxi_driver/src/features/profile/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  static final GlobalKey<MainNavigationScreenState> navigationKey = GlobalKey<MainNavigationScreenState>();

  static void goToHome(BuildContext context) {
    navigationKey.currentState?.setIndex(0);
  }

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  // Create separate navigation keys for each tab to maintain their own navigation stacks
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  Widget build(BuildContext context) {
    // PopScope (replaces WillPopScope in recent Flutter versions)
    // This allows us to handle the system back button
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Try to pop the current tab's navigator
        final NavigatorState? currentNavigator = _navigatorKeys[_currentIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
        } else {
          // If we can't pop the current tab, and we're not on the home tab, go to home tab
          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
          } else {
            // If we are on the home tab and can't pop, we can let the app exit or show a minimize/exit confirmation
            // For now, we'll just allow the system to exit if we can't pop anymore
            // To exit, we would need to set canPop to true, but since we are in a callback,
            // the system might already be handling it if we return true from a WillPopScope.
            // In PopScope, we might need a different approach to actually exit.
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildNavigator(0, const HomeScreen()),
            _buildNavigator(1, const TripHistoryScreen()),
            _buildNavigator(2, const NotificationsScreen()),
            _buildNavigator(3, const ProfileScreen()),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.access_time,
                    label: 'Rides',
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.notifications,
                    label: 'notification',
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.person,
                    label: 'Profile',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => child,
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        if (_currentIndex == index) {
          // If tapping the same tab, pop to first route
          _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

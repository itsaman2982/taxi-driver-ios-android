
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/providers/driver_provider.dart';
import 'package:taxi_driver/src/features/auth/screens/signin_screen.dart';
import 'package:taxi_driver/src/features/navigation/main_navigation_screen.dart';

class RootWrapper extends StatelessWidget {
  const RootWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, driverProvider, child) {
        if (!driverProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        if (driverProvider.isLoggedIn) {
          return MainNavigationScreen(key: MainNavigationScreen.navigationKey);
        } else {
          return const SignInScreen();
        }
      },
    );
  }
}

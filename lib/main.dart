import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/providers/driver_provider.dart';
import 'package:taxi_driver/src/core/providers/ride_provider.dart';
import 'package:taxi_driver/src/core/providers/earnings_provider.dart';
import 'package:taxi_driver/src/core/providers/registration_provider.dart';
import 'package:taxi_driver/src/core/providers/support_provider.dart';
import 'package:taxi_driver/src/core/providers/settings_provider.dart';
import 'package:taxi_driver/src/core/map/mappls_config.dart';
import 'package:taxi_driver/src/core/navigation/root_wrapper.dart';
import 'package:taxi_driver/src/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services but don't let them block the critical path if they take too long
  try {
    await MapplsConfig.initialize();
  } catch (e) {
    debugPrint('Mappls initialization error: $e');
  }

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notification initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ride Driver',
      theme: ThemeData(
        fontFamily: 'Lexend',
        textTheme: GoogleFonts.lexendTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final isTablet = mediaQuery.size.shortestSide > 600;
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: isTablet ? const TextScaler.linear(1.4) : const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      home: const RootWrapper(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'core/services/auth_service.dart';
import 'core/services/location_service.dart';
import 'core/services/incident_service.dart';
import 'core/services/sos_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/schedule_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        // Register all required services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<LocationService>(
          create:
              (context) => LocationService(
                Provider.of<AuthService>(context, listen: false),
              ),
        ),
        Provider<ScheduleService>(
          create:
              (context) => ScheduleService(
                Provider.of<AuthService>(context, listen: false),
              ),
        ),
        // Add other services with dependencies
        ProxyProvider<AuthService, LocationService>(
          update: (_, authService, __) => LocationService(authService),
        ),
        ProxyProvider2<AuthService, LocationService, IncidentService>(
          update:
              (_, authService, locationService, __) =>
                  IncidentService(authService, locationService),
        ),
        ProxyProvider2<AuthService, LocationService, SosService>(
          update:
              (_, authService, locationService, __) =>
                  SosService(authService, locationService),
        ),
        ProxyProvider<AuthService, NotificationService>(
          update: (_, authService, __) => NotificationService(authService),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracking System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      ),
      home: const AuthenticationWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Provider.of<AuthService>(context, listen: false).isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          // User is logged in, load user data and navigate to home
          final authService = Provider.of<AuthService>(context, listen: false);
          authService
              .checkAuthentication(); // No need to await, it'll update providers when done

          return const HomeScreen();
        }

        // User is not logged in, navigate to login
        return const LoginScreen();
      },
    );
  }
}

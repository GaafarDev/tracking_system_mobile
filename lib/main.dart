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

        // Fix: Remove duplicate LocationService registration and use ProxyProvider
        ProxyProvider<AuthService, LocationService>(
          // Initialize with proper error handling
          update: (_, authService, previousLocationService) {
            try {
              return previousLocationService ?? LocationService(authService);
            } catch (e) {
              debugPrint('Error initializing LocationService: $e');
              rethrow;
            }
          },
        ),

        ProxyProvider<AuthService, ScheduleService>(
          update: (_, authService, previousScheduleService) {
            try {
              return previousScheduleService ?? ScheduleService(authService);
            } catch (e) {
              debugPrint('Error initializing ScheduleService: $e');
              rethrow;
            }
          },
        ),

        // Fix: Ensure proper initialization of IncidentService
        ProxyProvider2<AuthService, LocationService, IncidentService>(
          update: (_, authService, locationService, previousIncidentService) {
            try {
              // Only create a new instance if needed
              return previousIncidentService ??
                  IncidentService(authService, locationService);
            } catch (e) {
              debugPrint('Error initializing IncidentService: $e');
              rethrow;
            }
          },
        ),

        // Fix: Ensure proper initialization of SosService
        ProxyProvider2<AuthService, LocationService, SosService>(
          update: (_, authService, locationService, previousSosService) {
            try {
              return previousSosService ??
                  SosService(authService, locationService);
            } catch (e) {
              debugPrint('Error initializing SosService: $e');
              rethrow;
            }
          },
        ),

        ProxyProvider<AuthService, NotificationService>(
          update: (_, authService, previousNotificationService) {
            try {
              return previousNotificationService ??
                  NotificationService(authService);
            } catch (e) {
              debugPrint('Error initializing NotificationService: $e');
              rethrow;
            }
          },
        ),
      ],
      child: const MyApp(),
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
          // Add error handling for authentication check
          try {
            authService.checkAuthentication();
          } catch (e) {
            debugPrint('Error checking authentication: $e');
            // You may want to handle authentication errors here
          }

          return const HomeScreen();
        }

        // User is not logged in, navigate to login
        return const LoginScreen();
      },
    );
  }
}

// lib/main.dart - Updated with Modern Theme
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'core/services/auth_service.dart';
import 'core/services/location_service.dart';
import 'core/services/incident_service.dart';
import 'core/services/sos_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/schedule_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/modern_login_screen.dart';
import 'features/home/screens/modern_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // Register all required services
        Provider<AuthService>(create: (_) => AuthService()),

        // Location Service with proper error handling
        ProxyProvider<AuthService, LocationService>(
          update: (_, authService, previousLocationService) {
            try {
              return previousLocationService ?? LocationService(authService);
            } catch (e) {
              debugPrint('Error initializing LocationService: $e');
              rethrow;
            }
          },
        ),

        // Schedule Service
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

        // Incident Service
        ProxyProvider2<AuthService, LocationService, IncidentService>(
          update: (_, authService, locationService, previousIncidentService) {
            try {
              return previousIncidentService ??
                  IncidentService(authService, locationService);
            } catch (e) {
              debugPrint('Error initializing IncidentService: $e');
              rethrow;
            }
          },
        ),

        // SOS Service
        ProxyProvider2<AuthService, LocationService, SosService>(
          update: (_, authService, locationService, previousSosService) {
            try {
              final sosService =
                  previousSosService ??
                  SosService(authService, locationService);
              // Initialize the service with cached token
              sosService.initialize();
              return sosService;
            } catch (e) {
              debugPrint('Error initializing SosService: $e');
              rethrow;
            }
          },
        ),

        // Notification Service
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
      title: 'Driver Tracking System',
      theme: AppTheme.lightTheme,
      home: const AuthenticationWrapper(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Provider.of<AuthService>(context, listen: false).isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryRed, AppTheme.darkRed],
                ),
              ),
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGold.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                      const Text(
                        'Driver Tracking',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),
                      Text(
                        'Loading your experience...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          // User is logged in, load user data and navigate to home
          final authService = Provider.of<AuthService>(context, listen: false);
          try {
            authService.checkAuthentication();
          } catch (e) {
            debugPrint('Error checking authentication: $e');
          }

          return const ModernHomeScreen();
        }

        // User is not logged in, navigate to login
        return const ModernLoginScreen();
      },
    );
  }
}

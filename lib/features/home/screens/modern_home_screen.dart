// lib/features/home/screens/modern_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../widgets/modern_app_drawer.dart';
import '../../incidents/screens/modern_report_incident_screen.dart';
import '../../sos/screens/modern_sos_screen.dart';
import '../../schedules/screens/modern_schedule_list_screen.dart';
import '../../notifications/screens/modern_notification_list_screen.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({Key? key}) : super(key: key);

  @override
  _ModernHomeScreenState createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen>
    with TickerProviderStateMixin {
  bool _isTracking = false;
  LocationData? _currentLocation;
  int _selectedVehicleId = 1;
  int _unreadNotifications = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _cardController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initServices();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _initServices() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );

    await locationService.initialize();

    locationService.locationStream.listen((locationData) {
      setState(() {
        _currentLocation = locationData;
      });
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkAuthentication();

    if (authService.currentDriver != null) {
      _selectedVehicleId = 1;
    }

    final unreadCount = await notificationService.refreshUnreadCount();
    setState(() {
      _unreadNotifications = unreadCount;
    });
  }

  void _toggleTracking() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );

    setState(() {
      _isTracking = !_isTracking;
    });

    if (_isTracking) {
      _pulseController.repeat(reverse: true);
      final success = await locationService.startLocationTracking(
        _selectedVehicleId,
      );

      if (success) {
        _showCustomSnackBar('Location tracking started', AppTheme.success);
      } else {
        setState(() {
          _isTracking = false;
        });
        _pulseController.stop();
        _showCustomSnackBar(
          'Failed to start location tracking',
          AppTheme.danger,
        );
      }
    } else {
      _pulseController.stop();
      locationService.stopLocationTracking();
      _showCustomSnackBar('Location tracking stopped', AppTheme.warning);
    }
  }

  void _showCustomSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getSnackBarIcon(color), color: Colors.white, size: 20),
            const SizedBox(width: AppTheme.spacingSmall),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        margin: const EdgeInsets.all(AppTheme.spacingMedium),
      ),
    );
  }

  IconData _getSnackBarIcon(Color color) {
    if (color == AppTheme.success) return Icons.check_circle;
    if (color == AppTheme.danger) return Icons.error;
    if (color == AppTheme.warning) return Icons.warning;
    return Icons.info;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.currentUser?.name ?? 'Driver';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      drawer: const ModernAppDrawer(),
      body: Container(
        decoration:
            AppTheme.backgroundGradient != null
                ? const BoxDecoration(gradient: AppTheme.backgroundGradient)
                : null,
        child: RefreshIndicator(
          onRefresh: _initServices,
          color: AppTheme.primaryRed,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: kToolbarHeight + 60,
              left: AppTheme.spacingMedium,
              right: AppTheme.spacingMedium,
              bottom: AppTheme.spacingMedium,
            ),
            child: AnimatedBuilder(
              animation: _cardController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _cardController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _cardController,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: _buildContent(userName),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(Icons.menu_rounded, color: Colors.black87),
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      ),
      actions: [
        // Notifications
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Colors.black87,
                ),
              ),
              onPressed: _navigateToNotifications,
            ),
            if (_unreadNotifications > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    _unreadNotifications > 9
                        ? '9+'
                        : _unreadNotifications.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppTheme.spacingSmall),
      ],
    );
  }

  Widget _buildContent(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section
        _buildWelcomeSection(userName),

        const SizedBox(height: AppTheme.spacingLarge),

        // Status Card
        _buildStatusCard(),

        const SizedBox(height: AppTheme.spacingLarge),

        // Quick Actions
        _buildQuickActions(),

        const SizedBox(height: AppTheme.spacingLarge),

        // Today's Schedule Preview
        _buildTodaySchedule(),
      ],
    );
  }

  Widget _buildWelcomeSection(String userName) {
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryGold,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'D',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(userName, style: AppTheme.heading2.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      size: 16,
                      color: AppTheme.primaryGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Have a safe journey today!',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isTracking ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient:
                            _isTracking
                                ? AppTheme.primaryGradient
                                : LinearGradient(
                                  colors: [
                                    Colors.grey[400]!,
                                    Colors.grey[500]!,
                                  ],
                                ),
                        shape: BoxShape.circle,
                        boxShadow:
                            _isTracking
                                ? [
                                  BoxShadow(
                                    color: AppTheme.primaryRed.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ]
                                : [],
                      ),
                      child: Icon(
                        _isTracking ? Icons.location_on : Icons.location_off,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tracking Status', style: AppTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      _isTracking ? 'Active Tracking' : 'Not Tracking',
                      style: AppTheme.heading3.copyWith(
                        color:
                            _isTracking ? AppTheme.success : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              GradientButton(
                text: _isTracking ? 'Stop' : 'Start',
                onPressed: _toggleTracking,
                gradient:
                    _isTracking
                        ? LinearGradient(
                          colors: [Colors.orange[600]!, Colors.orange[700]!],
                        )
                        : AppTheme.primaryGradient,
                width: 80,
                height: 40,
              ),
            ],
          ),

          if (_currentLocation != null) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            const Divider(),
            const SizedBox(height: AppTheme.spacingMedium),

            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Latitude',
                    value:
                        _currentLocation!.latitude?.toStringAsFixed(4) ?? 'N/A',
                    icon: Icons.my_location,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: InfoCard(
                    title: 'Longitude',
                    value:
                        _currentLocation!.longitude?.toStringAsFixed(4) ??
                        'N/A',
                    icon: Icons.location_on,
                  ),
                ),
              ],
            ),

            if (_currentLocation!.speed != null) ...[
              const SizedBox(height: AppTheme.spacingSmall),
              InfoCard(
                title: 'Current Speed',
                value:
                    '${(_currentLocation!.speed! * 3.6).toStringAsFixed(1)} km/h',
                icon: Icons.speed,
                color: AppTheme.info,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTheme.heading2),
        const SizedBox(height: AppTheme.spacingMedium),

        ActionCard(
          title: 'Report Incident',
          subtitle: 'Report any incidents or issues',
          icon: Icons.warning_amber_rounded,
          color: AppTheme.warning,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModernReportIncidentScreen(),
                ),
              ),
        ),

        const SizedBox(height: AppTheme.spacingMedium),

        ActionCard(
          title: 'Emergency SOS',
          subtitle: 'Send emergency alert',
          icon: Icons.emergency_rounded,
          color: AppTheme.danger,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModernSosScreen(),
                ),
              ),
        ),

        const SizedBox(height: AppTheme.spacingMedium),

        ActionCard(
          title: 'View Schedule',
          subtitle: 'Check your routes and times',
          icon: Icons.calendar_today_rounded,
          color: AppTheme.info,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModernScheduleListScreen(),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Today\'s Schedule', style: AppTheme.heading2),
            TextButton.icon(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModernScheduleListScreen(),
                    ),
                  ),
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryRed),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMedium),

        GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Morning Route', style: AppTheme.heading3),
                        const SizedBox(height: 4),
                        Text('08:00 AM - 12:00 PM', style: AppTheme.bodyMedium),
                      ],
                    ),
                  ),
                  StatusBadge(
                    text: 'Upcoming',
                    color: AppTheme.info,
                    icon: Icons.schedule,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              const Divider(),
              const SizedBox(height: AppTheme.spacingMedium),
              Row(
                children: [
                  Icon(Icons.route, color: Colors.grey[600], size: 16),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      'City Center Route - 15 stops',
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModernNotificationListScreen(),
      ),
    );

    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    final unreadCount = await notificationService.refreshUnreadCount();
    setState(() {
      _unreadNotifications = unreadCount;
    });
  }
}

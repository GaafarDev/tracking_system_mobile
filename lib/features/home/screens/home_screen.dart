import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../../incidents/screens/report_incident_screen.dart';
import '../../sos/screens/sos_screen.dart';
import '../../schedules/screens/schedule_list_screen.dart';
import '../../notifications/screens/notification_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isTracking = false;
  LocationData? _currentLocation;
  int _selectedVehicleId = 1; // Default vehicle ID, will be updated from API
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _initServices();
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

    // Initialize location service
    await locationService.initialize();

    // Subscribe to location updates
    locationService.locationStream.listen((locationData) {
      setState(() {
        _currentLocation = locationData;
      });
    });

    // Load driver info and get selected vehicle
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkAuthentication();
    if (authService.currentDriver != null) {
      // In a real app, you'd fetch the assigned vehicle from the API
      // For now, we'll use a default value
      _selectedVehicleId = 1;
    }

    // Check for unread notifications
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
      final success = await locationService.startLocationTracking(
        _selectedVehicleId,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location tracking started')),
        );
      } else {
        // If tracking failed, revert the state
        setState(() {
          _isTracking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start location tracking')),
        );
      }
    } else {
      locationService.stopLocationTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location tracking stopped')),
      );
    }
  }

  Future<void> _logout() async {
    // Stop tracking if active
    if (_isTracking) {
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );
      locationService.stopLocationTracking();
    }

    // Perform logout
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();

    // Navigate to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToIncidentReport() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ReportIncidentScreen()),
    );
  }

  void _navigateToSosScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SosScreen()));
  }

  void _navigateToSchedules() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ScheduleListScreen()));
  }

  void _navigateToNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NotificationListScreen()),
    );

    // Refresh unread count when returning from notifications
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    final unreadCount = await notificationService.refreshUnreadCount();
    setState(() {
      _unreadNotifications = unreadCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.currentUser?.name ?? 'Driver';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          // Notifications icon with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _navigateToNotifications,
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications > 9
                          ? '9+'
                          : _unreadNotifications.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _initServices,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Text(
                  'Welcome, $userName!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Status card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _isTracking
                                ? Icons.location_on
                                : Icons.location_off,
                            color: _isTracking ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isTracking
                                ? 'Tracking Active'
                                : 'Tracking Inactive',
                            style: TextStyle(
                              color: _isTracking ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_currentLocation != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Current Location:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${_currentLocation!.latitude?.toStringAsFixed(6)}, ' +
                              'Lng: ${_currentLocation!.longitude?.toStringAsFixed(6)}',
                        ),
                        if (_currentLocation!.speed != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Speed: ${(_currentLocation!.speed! * 3.6).toStringAsFixed(1)} km/h',
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick action buttons
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Track location button
                _buildActionButton(
                  icon: _isTracking ? Icons.pause : Icons.play_arrow,
                  label: _isTracking ? 'Stop Tracking' : 'Start Tracking',
                  color: _isTracking ? Colors.orange : Colors.green,
                  onTap: _toggleTracking,
                ),
                const SizedBox(height: 12),

                // Report incident button
                _buildActionButton(
                  icon: Icons.warning_amber,
                  label: 'Report Incident',
                  color: Colors.amber,
                  onTap: _navigateToIncidentReport,
                ),
                const SizedBox(height: 12),

                // SOS button
                _buildActionButton(
                  icon: Icons.emergency,
                  label: 'SOS Emergency',
                  color: Colors.red,
                  onTap: _navigateToSosScreen,
                ),
                const SizedBox(height: 12),

                // View schedule button
                _buildActionButton(
                  icon: Icons.calendar_today,
                  label: 'View Schedule',
                  color: Colors.blue,
                  onTap: _navigateToSchedules,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
        onPressed: onTap,
      ),
    );
  }
}

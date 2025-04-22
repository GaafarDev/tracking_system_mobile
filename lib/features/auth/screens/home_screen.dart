import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/drawer_menu.dart';
import '../../auth/screens/login_screen.dart';
import '../../incidents/screens/report_incident_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  bool _isTracking = false;
  LocationData? _currentLocation;
  int _selectedVehicleId = 1; // Default vehicle ID, should be fetched from API

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _currentLocation = currentLocation;
      });
    });
  }

  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
      if (_isTracking) {
        _locationService.startLocationTracking(_selectedVehicleId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location tracking started')));
      } else {
        _locationService.stopLocationTracking();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location tracking stopped')));
      }
    });
  }

  Future<void> _logout() async {
    final authService = AuthService();
    await authService.logout();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  void _reportIncident() {
    // Navigate to incident reporting screen
    // This would require you to create the ReportIncidentScreen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ReportIncidentScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Dashboard'),
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: _logout)],
      ),
      drawer: DrawerMenu(),
      body: Column(
        children: [
          // Status card
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _isTracking ? Icons.location_on : Icons.location_off,
                      color: _isTracking ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _isTracking ? 'Tracking Active' : 'Tracking Inactive',
                      style: TextStyle(
                        color: _isTracking ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_currentLocation != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'Current Location:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Lat: ${_currentLocation!.latitude?.toStringAsFixed(6)}, ' +
                        'Lng: ${_currentLocation!.longitude?.toStringAsFixed(6)}',
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
                    label: Text(
                      _isTracking ? 'Stop Tracking' : 'Start Tracking',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isTracking ? Colors.orange : Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _toggleTracking,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.warning),
                    label: Text('Report Incident'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _reportIncident,
                  ),
                ),
              ],
            ),
          ),

          // Placeholder for map or additional info
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Map will be displayed here',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_config.dart';
import 'auth_service.dart';

class LocationService {
  final Location _location = Location();
  Timer? _timer;
  final AuthService _authService = AuthService();

  // Start location tracking
  Future<void> startLocationTracking(int vehicleId) async {
    // Request permissions
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await _location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) return;
    }

    // Set up location settings
    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 10000, // 10 seconds
    );

    // Start periodic updates
    _timer = Timer.periodic(Duration(seconds: 30), (timer) async {
      await sendLocationToServer(vehicleId);
    });
  }

  // Send location data to server
  Future<void> sendLocationToServer(int vehicleId) async {
    try {
      LocationData locationData = await _location.getLocation();
      String? token = await _authService.getToken();

      if (token == null) {
        print('Not authenticated, cannot send location');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/location/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'speed': locationData.speed,
          'heading': locationData.heading,
          'vehicle_id': vehicleId,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to update location: ${response.body}');
      }
    } catch (e) {
      print('Error sending location: $e');
    }
  }

  // Stop location tracking
  void stopLocationTracking() {
    _timer?.cancel();
    _timer = null;
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import 'auth_service.dart';

class LocationService {
  final Location _location = Location();
  final AuthService _authService;

  Timer? _timer;
  LocationData? _lastLocation;
  final _locationStreamController = StreamController<LocationData>.broadcast();

  Stream<LocationData> get locationStream => _locationStreamController.stream;
  LocationData? get lastLocation => _lastLocation;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  LocationService(this._authService);

  // Initialize the location service
  Future<bool> initialize() async {
    // Check if running on web
    if (kIsWeb) {
      // Web-specific implementation
      try {
        _lastLocation = await _location.getLocation();
        return true;
      } catch (e) {
        print('Web location error: $e');
        return false;
      }
    } else {
      // Mobile implementation (existing code)
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return false;
      }

      // Check for location permission
      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
        if (permissionStatus != PermissionStatus.granted) return false;
      }

      // Set up location settings
      _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 10000, // 10 seconds
        distanceFilter: 5, // 5 meters
      );

      return true;
    }
  }

  // Start location tracking
  Future<bool> startLocationTracking(int vehicleId) async {
    if (_isTracking) return true;

    // Make sure location service is initialized
    bool isInitialized = await initialize();
    if (!isInitialized) return false;

    try {
      // Start listening to location updates
      _location.onLocationChanged.listen((LocationData currentLocation) {
        _lastLocation = currentLocation;
        _locationStreamController.add(currentLocation);
      });

      // Start periodic updates to the server
      _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        await sendLocationToServer(vehicleId);
      });

      _isTracking = true;
      return true;
    } catch (e) {
      print('Error starting location tracking: $e');
      return false;
    }
  }

  // Send location data to server
  Future<bool> sendLocationToServer(int vehicleId) async {
    try {
      if (_lastLocation == null) {
        _lastLocation = await _location.getLocation();
      }

      String? token = await _authService.getToken();
      if (token == null) {
        print('Not authenticated, cannot send location');
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateLocation}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': _lastLocation!.latitude,
          'longitude': _lastLocation!.longitude,
          'speed': _lastLocation!.speed,
          'heading': _lastLocation!.heading,
          'vehicle_id': vehicleId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update location: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending location: $e');
      return false;
    }
  }

  // Get current location once
  Future<LocationData?> getCurrentLocation() async {
    try {
      bool isInitialized = await initialize();
      if (!isInitialized) return null;

      return await _location.getLocation();
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Stop location tracking
  void stopLocationTracking() {
    _timer?.cancel();
    _timer = null;
    _isTracking = false;
  }

  // Dispose resources
  void dispose() {
    stopLocationTracking();
    _locationStreamController.close();
  }
}

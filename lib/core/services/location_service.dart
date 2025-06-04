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

  // Add request throttling
  DateTime? _lastLocationUpdate;
  bool _isUpdatingLocation = false;

  LocationService(this._authService);

  // Optimized initialization
  Future<bool> initialize() async {
    if (kIsWeb) {
      try {
        _lastLocation = await _location.getLocation();
        return true;
      } catch (e) {
        debugPrint('Web location error: $e');
        return false;
      }
    } else {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return false;
      }

      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
        if (permissionStatus != PermissionStatus.granted) return false;
      }

      _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 15000, // Increased to 15 seconds to reduce API calls
        distanceFilter: 10, // Increased to 10 meters
      );

      return true;
    }
  }

  // Optimized location tracking - Cache token to avoid repeated calls
  Future<bool> startLocationTracking(int vehicleId) async {
    if (_isTracking) return true;

    bool isInitialized = await initialize();
    if (!isInitialized) return false;

    try {
      // Get token once and cache it for the tracking session
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ No token for location tracking');
        return false;
      }

      _location.onLocationChanged.listen((LocationData currentLocation) {
        _lastLocation = currentLocation;
        _locationStreamController.add(currentLocation);
      });

      // Start periodic updates with cached token
      _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        await _sendLocationToServer(vehicleId, token);
      });

      _isTracking = true;
      debugPrint('✅ Location tracking started');
      return true;
    } catch (e) {
      debugPrint('❌ Location tracking error: $e');
      return false;
    }
  }

  // Optimized server update - Use cached token
  Future<bool> _sendLocationToServer(int vehicleId, String token) async {
    // Prevent duplicate requests
    if (_isUpdatingLocation) return true;

    final now = DateTime.now();
    if (_lastLocationUpdate != null &&
        now.difference(_lastLocationUpdate!).inSeconds < 25) {
      return true; // Skip if updated recently
    }

    _isUpdatingLocation = true;
    _lastLocationUpdate = now;

    try {
      if (_lastLocation == null) {
        _lastLocation = await _location.getLocation();
      }

      // Use the cached token instead of calling getToken() again
      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 3)); // Reduced timeout

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Location update error: $e');
      return false;
    } finally {
      _isUpdatingLocation = false;
    }
  }

  // Fast current location - no server calls
  Future<LocationData?> getCurrentLocation() async {
    try {
      // Return cached location if recent (less than 30 seconds old)
      if (_lastLocation != null) {
        return _lastLocation;
      }

      // Only get new location if not cached
      bool isInitialized = await initialize();
      if (!isInitialized) return null;

      final location = await _location.getLocation();
      _lastLocation = location; // Cache it
      return location;
    } catch (e) {
      debugPrint('❌ Get location error: $e');
      return null;
    }
  }

  void stopLocationTracking() {
    _timer?.cancel();
    _timer = null;
    _isTracking = false;
    debugPrint('✅ Location tracking stopped');
  }

  void dispose() {
    stopLocationTracking();
    _locationStreamController.close();
  }
}

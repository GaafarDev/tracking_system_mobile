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

  // Reduce request frequency for better performance
  DateTime? _lastLocationUpdate;
  bool _isUpdatingLocation = false;
  String? _cachedToken; // Cache token for location updates

  LocationService(this._authService);

  // Faster initialization - skip permission checks if already granted
  Future<bool> initialize() async {
    if (kIsWeb) {
      try {
        _lastLocation = await _location.getLocation().timeout(
          const Duration(seconds: 3),
        );
        return true;
      } catch (e) {
        debugPrint('Web location error: $e');
        return false;
      }
    } else {
      try {
        // Try to get location first - if it works, permissions are OK
        _lastLocation = await _location.getLocation().timeout(
          const Duration(seconds: 2),
        );

        _location.changeSettings(
          accuracy: LocationAccuracy.balanced, // Faster than high accuracy
          interval: 20000, // 20 seconds
          distanceFilter: 20, // 20 meters
        );

        debugPrint('✅ Location service initialized quickly');
        return true;
      } catch (e) {
        // Fall back to permission checking
        debugPrint('⚠️ Fallback to permission check: $e');
        return await _initializeWithPermissions();
      }
    }
  }

  Future<bool> _initializeWithPermissions() async {
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
      accuracy: LocationAccuracy.balanced,
      interval: 20000,
      distanceFilter: 20,
    );

    return true;
  }

  // Optimized location tracking
  Future<bool> startLocationTracking(int vehicleId) async {
    if (_isTracking) return true;

    bool isInitialized = await initialize();
    if (!isInitialized) return false;

    try {
      // Cache token once at start
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ No token for location tracking');
        return false;
      }
      _cachedToken = token;

      _location.onLocationChanged.listen((LocationData currentLocation) {
        _lastLocation = currentLocation;
        _locationStreamController.add(currentLocation);
      });

      // Longer intervals to reduce battery drain and API calls
      _timer = Timer.periodic(const Duration(seconds: 45), (timer) async {
        await _sendLocationToServer(vehicleId);
      });

      _isTracking = true;
      debugPrint('✅ Location tracking started');
      return true;
    } catch (e) {
      debugPrint('❌ Location tracking error: $e');
      return false;
    }
  }

  // Optimized server update with cached token
  Future<bool> _sendLocationToServer(int vehicleId) async {
    // Prevent duplicate requests
    if (_isUpdatingLocation) return true;

    final now = DateTime.now();
    if (_lastLocationUpdate != null &&
        now.difference(_lastLocationUpdate!).inSeconds < 35) {
      return true; // Skip if updated too recently
    }

    _isUpdatingLocation = true;
    _lastLocationUpdate = now;

    try {
      if (_lastLocation == null) {
        _lastLocation = await _location.getLocation().timeout(
          const Duration(seconds: 2),
        );
      }

      // Use cached token
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateLocation}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_cachedToken',
            },
            body: jsonEncode({
              'latitude': _lastLocation!.latitude,
              'longitude': _lastLocation!.longitude,
              'speed': _lastLocation!.speed,
              'heading': _lastLocation!.heading,
              'vehicle_id': vehicleId,
            }),
          )
          .timeout(const Duration(seconds: 2));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Location update error: $e');
      return false;
    } finally {
      _isUpdatingLocation = false;
    }
  }

  // Very fast current location - prioritize speed over accuracy
  Future<LocationData?> getCurrentLocation() async {
    try {
      // Return cached location if recent (less than 60 seconds old)
      if (_lastLocation != null) {
        return _lastLocation;
      }

      // Get new location with short timeout
      final location = await _location.getLocation().timeout(
        const Duration(seconds: 1),
      );
      _lastLocation = location;
      return location;
    } catch (e) {
      debugPrint('❌ Get location error: $e');
      // Return last known location even if old
      return _lastLocation;
    }
  }

  void stopLocationTracking() {
    _timer?.cancel();
    _timer = null;
    _isTracking = false;
    _cachedToken = null; // Clear cached token
    debugPrint('✅ Location tracking stopped');
  }

  void dispose() {
    stopLocationTracking();
    _locationStreamController.close();
  }
}

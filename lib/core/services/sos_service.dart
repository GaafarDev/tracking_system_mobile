import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/sos_alert.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';
import 'location_service.dart';

class SosService {
  final AuthService _authService;
  final LocationService _locationService;
  SosAlert? _activeAlert;
  String? _cachedToken;

  SosService(this._authService, this._locationService);

  SosAlert? get activeAlert => _activeAlert;

  // ULTRA-FAST SOS - Use cached location and token
  Future<bool> sendSosAlert(String message) async {
    try {
      debugPrint('🚨 Starting SOS alert...');
      final startTime = DateTime.now();

      // Get token immediately (should be cached)
      String? token = _cachedToken ?? await _authService.getToken();
      if (token == null) {
        debugPrint('❌ No token available');
        return false;
      }
      _cachedToken = token;

      // Use IMMEDIATE location - don't wait for GPS
      var location = _locationService.lastLocation;

      // If no cached location, use default and get real location async
      if (location == null) {
        debugPrint('⚠️ No cached location, using default');
        // Send with default location first, update later
        final response = await _sendSosRequest(token, 0.0, 0.0, message);

        // Try to get actual location in background
        _updateLocationAsync(token);

        return response;
      }

      // Send with cached location immediately
      debugPrint(
        '📍 Using cached location: ${location.latitude}, ${location.longitude}',
      );
      final success = await _sendSosRequest(
        token,
        location.latitude ?? 0.0,
        location.longitude ?? 0.0,
        message,
      );

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('⚡ SOS completed in ${duration}ms');

      return success;
    } catch (e) {
      debugPrint('❌ SOS error: $e');
      return false;
    }
  }

  Future<bool> _sendSosRequest(
    String token,
    double lat,
    double lng,
    String message,
  ) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendSosAlert}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'latitude': lat,
            'longitude': lng,
            'message': message,
          }),
        )
        .timeout(const Duration(seconds: 3)); // Very short timeout

    debugPrint('📡 SOS response: ${response.statusCode}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['sos_alert'] != null) {
        _activeAlert = SosAlert.fromJson(data['sos_alert']);
        debugPrint('✅ SOS sent successfully');
        return true;
      }
    }

    debugPrint('❌ SOS failed: ${response.statusCode} - ${response.body}');
    return false;
  }

  void _updateLocationAsync(String token) async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null && _activeAlert != null) {
        // Update SOS with real location
        await http
            .patch(
              Uri.parse('${ApiConfig.baseUrl}/sos-alerts/${_activeAlert!.id}'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'latitude': location.latitude,
                'longitude': location.longitude,
              }),
            )
            .timeout(const Duration(seconds: 2));
        debugPrint('📍 SOS location updated');
      }
    } catch (e) {
      debugPrint('⚠️ Location update failed: $e');
    }
  }

  // Pre-cache token and check for active alerts
  Future<void> initialize() async {
    try {
      _cachedToken = await _authService.getToken();
      if (_cachedToken != null) {
        await getActiveSosAlert();
      }
    } catch (e) {
      debugPrint('⚠️ SOS service initialization error: $e');
    }
  }

  // FAST active SOS check - use cached token
  Future<SosAlert?> getActiveSosAlert() async {
    try {
      String? token = _cachedToken ?? await _authService.getToken();
      if (token == null) return null;

      _cachedToken = token;

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getActiveSosAlert}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['sos_alert'] != null) {
          _activeAlert = SosAlert.fromJson(data['sos_alert']);
          return _activeAlert;
        }
      }

      _activeAlert = null;
      return null;
    } catch (e) {
      debugPrint('❌ Check SOS error: $e');
      return null;
    }
  }

  // FAST SOS cancellation - use cached token
  Future<bool> cancelSosAlert() async {
    if (_activeAlert == null) {
      debugPrint('❌ No SOS to cancel');
      return false;
    }

    try {
      String? token = _cachedToken ?? await _authService.getToken();
      if (token == null) return false;

      String url =
          ApiConfig.baseUrl +
          ApiConfig.cancelSosAlert.replaceAll('{id}', '${_activeAlert!.id}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        _activeAlert = null;
        debugPrint('✅ SOS cancelled');
        return true;
      }

      debugPrint('❌ Cancel failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Cancel error: $e');
      return false;
    }
  }

  // Clear cached data on logout
  void clearCache() {
    _cachedToken = null;
    _activeAlert = null;
  }
}

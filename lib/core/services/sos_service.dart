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
  bool _isSending = false; // Prevent multiple simultaneous sends

  SosService(this._authService, this._locationService);

  SosAlert? get activeAlert => _activeAlert;

  // ULTRA-FAST SOS - Send immediately with minimal validation
  Future<bool> sendSosAlert(String message) async {
    if (_isSending) {
      debugPrint('⚠️ SOS already in progress, ignoring duplicate request');
      return false;
    }

    _isSending = true;

    try {
      debugPrint('🚨 EMERGENCY SOS - Starting immediate send...');
      final startTime = DateTime.now();

      // Get token immediately (should be cached)
      String? token = _cachedToken ?? await _authService.getToken();
      if (token == null) {
        debugPrint('❌ No auth token - SOS failed');
        return false;
      }
      _cachedToken = token;

      // Use default location first - don't wait for GPS
      double lat = 0.0;
      double lng = 0.0;

      // Try to get cached location quickly
      final cachedLocation = _locationService.lastLocation;
      if (cachedLocation != null) {
        lat = cachedLocation.latitude ?? 0.0;
        lng = cachedLocation.longitude ?? 0.0;
        debugPrint('📍 Using cached location: $lat, $lng');
      } else {
        debugPrint('⚠️ No location cache - using default (0,0)');
      }

      // Send SOS immediately
      final success = await _sendSosRequest(token, lat, lng, message);

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('⚡ SOS completed in ${duration}ms');

      // If we used default location, try to update with real location in background
      if (lat == 0.0 && lng == 0.0) {
        _updateLocationAsync(token);
      }

      return success;
    } catch (e) {
      debugPrint('❌ SOS CRITICAL ERROR: $e');
      return false;
    } finally {
      _isSending = false;
    }
  }

  Future<bool> _sendSosRequest(
    String token,
    double lat,
    double lng,
    String message,
  ) async {
    try {
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
          .timeout(
            const Duration(seconds: 2),
          ); // Very short timeout for emergency

      debugPrint('📡 SOS response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sos_alert'] != null) {
          _activeAlert = SosAlert.fromJson(data['sos_alert']);
          debugPrint('✅ SOS sent successfully - Alert ID: ${_activeAlert!.id}');
          return true;
        }
      }

      debugPrint('❌ SOS failed: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('❌ SOS network error: $e');
      return false;
    }
  }

  void _updateLocationAsync(String token) async {
    try {
      debugPrint('📍 Updating SOS with real location...');
      final location = await _locationService.getCurrentLocation();
      if (location != null && _activeAlert != null) {
        // Update SOS with real location - don't wait for response
        http
            .patch(
              Uri.parse(
                '${ApiConfig.baseUrl}/api/sos-alerts/${_activeAlert!.id}',
              ),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'latitude': location.latitude,
                'longitude': location.longitude,
              }),
            )
            .timeout(const Duration(seconds: 2))
            .then((_) => debugPrint('📍 SOS location updated'))
            .catchError((e) => debugPrint('⚠️ Location update failed: $e'));
      }
    } catch (e) {
      debugPrint('⚠️ Background location update error: $e');
    }
  }

  // Pre-cache token for faster SOS
  Future<void> initialize() async {
    try {
      _cachedToken = await _authService.getToken();
      if (_cachedToken != null) {
        await getActiveSosAlert();
      }
      debugPrint('✅ SOS service initialized');
    } catch (e) {
      debugPrint('⚠️ SOS service initialization error: $e');
    }
  }

  // FAST active SOS check
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
          .timeout(const Duration(seconds: 2));

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

  // FAST SOS cancellation
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
          .timeout(const Duration(seconds: 2));

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
    _isSending = false;
  }
}

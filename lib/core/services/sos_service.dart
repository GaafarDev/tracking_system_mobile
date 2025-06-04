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
  String? _cachedToken; // Cache token to avoid repeated reads

  SosService(this._authService, this._locationService);

  SosAlert? get activeAlert => _activeAlert;

  // ULTRA-FAST SOS - Pre-cache token and location
  Future<bool> sendSosAlert(String message) async {
    try {
      debugPrint('🚨 Starting SOS alert...');

      // Get cached token immediately - no await needed if cached
      String? token = _cachedToken ?? await _authService.getToken();
      if (token == null) {
        debugPrint('❌ No token available');
        return false;
      }
      _cachedToken = token; // Cache for future use

      // Use last known location immediately (should be available from tracking)
      final location =
          _locationService.lastLocation ??
          await _locationService.getCurrentLocation();

      if (location == null) {
        debugPrint('❌ No location available');
        return false;
      }

      debugPrint(
        '📍 Using location: ${location.latitude}, ${location.longitude}',
      );

      // Send SOS with minimal payload - single API call
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendSosAlert}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'latitude': location.latitude,
              'longitude': location.longitude,
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 5)); // Reduced timeout

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
    } catch (e) {
      debugPrint('❌ SOS error: $e');
      return false;
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

      _cachedToken = token; // Update cache

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getActiveSosAlert}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 3)); // Very short timeout

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
          .timeout(const Duration(seconds: 3)); // Very short timeout

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

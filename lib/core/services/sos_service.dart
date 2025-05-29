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

  SosService(this._authService, this._locationService);

  SosAlert? get activeAlert => _activeAlert;

  // ULTRA-FAST SOS - Get token once and reuse
  Future<bool> sendSosAlert(String message) async {
    try {
      // Check if already have active alert (no API call needed)
      if (_activeAlert != null && _activeAlert!.isActive) {
        debugPrint('❌ Already have active SOS');
        return false;
      }

      // Get token ONCE
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ No token');
        return false;
      }

      // Get location (this should be fast since it's already initialized)
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        debugPrint('❌ No location');
        return false;
      }

      // Send SOS request - single API call
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
          .timeout(const Duration(seconds: 8)); // Shorter timeout

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sos_alert'] != null) {
          _activeAlert = SosAlert.fromJson(data['sos_alert']);
          debugPrint('✅ SOS sent');
          return true;
        }
      }

      debugPrint('❌ SOS failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ SOS error: $e');
      return false;
    }
  }

  // FAST active SOS check - Get token once
  Future<SosAlert?> getActiveSosAlert() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return null;

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getActiveSosAlert}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 5)); // Very short timeout

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

  // FAST SOS cancellation - Get token once
  Future<bool> cancelSosAlert() async {
    if (_activeAlert == null) {
      debugPrint('❌ No SOS to cancel');
      return false;
    }

    try {
      String? token = await _authService.getToken();
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
          .timeout(const Duration(seconds: 5)); // Very short timeout

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
}

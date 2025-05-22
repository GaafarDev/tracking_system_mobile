import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/sos_alert.dart';
import '../utils/api_config.dart';
import '../utils/api_utils.dart';
import 'auth_service.dart';
import 'location_service.dart';

class SosService {
  final AuthService _authService;
  final LocationService _locationService;
  SosAlert? _activeAlert;

  SosService(this._authService, this._locationService);

  SosAlert? get activeAlert => _activeAlert;

  // Send SOS alert
  Future<bool> sendSosAlert(String message) async {
    try {
      // Check if already have an active alert
      if (_activeAlert != null && _activeAlert!.isActive) {
        debugPrint('Already have an active SOS alert');
        return false;
      }

      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('Not authenticated, cannot send SOS alert');
        return false;
      }

      // Get current location
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation == null) {
        debugPrint('Could not get current location for SOS alert');
        return false;
      }

      debugPrint(
        'Sending SOS alert to ${ApiConfig.baseUrl}${ApiConfig.sendSosAlert}',
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendSosAlert}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
          'message': message,
        }),
      );

      debugPrint('SOS alert response status: ${response.statusCode}');
      debugPrint('SOS alert response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _activeAlert = SosAlert.fromJson(data['sos_alert']);
        return true;
      } else {
        debugPrint('Failed to send SOS alert: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending SOS alert: $e');
      return false;
    }
  }

  // Get active SOS alert if exists
  Future<SosAlert?> getActiveSosAlert() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('Not authenticated, cannot check SOS alerts');
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getActiveSosAlert}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data.containsKey('sos_alert')) {
          _activeAlert = SosAlert.fromJson(data['sos_alert']);
          return _activeAlert;
        }
        return null;
      } else {
        debugPrint(
          'Failed to get active SOS alert: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error checking active SOS alert: $e');
      return null;
    }
  }

  // Cancel active SOS alert
  Future<bool> cancelSosAlert() async {
    if (_activeAlert == null) {
      debugPrint('No active SOS alert to cancel');
      return false;
    }

    try {
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('Not authenticated, cannot cancel SOS alert');
        return false;
      }

      // Replace {id} in the URL with the actual SOS alert ID
      String url =
          ApiConfig.baseUrl +
          ApiConfig.cancelSosAlert.replaceAll('{id}', '${_activeAlert!.id}');

      debugPrint('Cancelling SOS alert: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _activeAlert = null;
        return true;
      } else {
        debugPrint(
          'Failed to cancel SOS alert: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error canceling SOS alert: $e');
      return false;
    }
  }

  // Check active SOS alert using safe API call
  Future<SosAlert?> checkActiveSOSAlert() async {
    String? token = await _authService.getToken();
    if (token == null) return null;

    final apiCall = http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/sos/active'), // Fixed URL path
      headers: {'Authorization': 'Bearer $token'},
    );

    final result = await safeApiCall(apiCall);
    if (result != null && result.containsKey('sos_alert')) {
      return SosAlert.fromJson(result['sos_alert']);
    }
    return null;
  }
}

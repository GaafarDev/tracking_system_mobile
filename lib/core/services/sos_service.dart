// Replace lib/core/services/sos_service.dart with this version:

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

  // Send SOS alert with detailed debugging
  Future<bool> sendSosAlert(String message) async {
    debugPrint('=== SOS ALERT START ===');

    try {
      // Check if already have an active alert
      if (_activeAlert != null && _activeAlert!.isActive) {
        debugPrint('❌ Already have an active SOS alert');
        return false;
      }

      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ Not authenticated, cannot send SOS alert');
        return false;
      }
      debugPrint('✅ Token found: ${token.substring(0, 20)}...');

      // Get current location
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation == null) {
        debugPrint('❌ Could not get current location for SOS alert');
        return false;
      }
      debugPrint(
        '✅ Location: ${currentLocation.latitude}, ${currentLocation.longitude}',
      );

      final url = '${ApiConfig.baseUrl}${ApiConfig.sendSosAlert}';
      debugPrint('🌐 Sending SOS to: $url');

      final requestBody = {
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
        'message': message,
      };
      debugPrint('📝 Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 SOS response status: ${response.statusCode}');
      debugPrint('📡 SOS response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['sos_alert'] != null) {
            _activeAlert = SosAlert.fromJson(data['sos_alert']);
            debugPrint('✅ SOS alert created successfully: ${_activeAlert!.id}');
            return true;
          } else {
            debugPrint('⚠️ Success response but no sos_alert data');
            return false;
          }
        } catch (e) {
          debugPrint('❌ Failed to parse SOS response: $e');
          return false;
        }
      } else {
        debugPrint('❌ SOS server error: ${response.statusCode}');
        debugPrint('Error body: ${response.body}');

        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          debugPrint('Parsed SOS error: $errorData');
        } catch (e) {
          debugPrint('Could not parse SOS error response: $e');
        }

        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception in sendSosAlert: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return false;
    } finally {
      debugPrint('=== SOS ALERT END ===');
    }
  }

  // Get active SOS alert if exists
  Future<SosAlert?> getActiveSosAlert() async {
    debugPrint('=== CHECKING ACTIVE SOS ===');

    try {
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ Not authenticated, cannot check SOS alerts');
        return null;
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.getActiveSosAlert}';
      debugPrint('🌐 Checking SOS at: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Active SOS status: ${response.statusCode}');
      debugPrint('📡 Active SOS body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data != null &&
              data.containsKey('sos_alert') &&
              data['sos_alert'] != null) {
            _activeAlert = SosAlert.fromJson(data['sos_alert']);
            debugPrint('✅ Found active SOS alert: ${_activeAlert!.id}');
            return _activeAlert;
          } else {
            debugPrint('✅ No active SOS alert found');
            _activeAlert = null;
            return null;
          }
        } catch (e) {
          debugPrint('❌ Failed to parse active SOS response: $e');
          return null;
        }
      } else {
        debugPrint(
          '❌ Failed to get active SOS alert: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception checking active SOS alert: $e');
      return null;
    }
  }

  // Cancel active SOS alert
  Future<bool> cancelSosAlert() async {
    debugPrint('=== CANCELLING SOS ===');

    if (_activeAlert == null) {
      debugPrint('❌ No active SOS alert to cancel');
      return false;
    }

    try {
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ Not authenticated, cannot cancel SOS alert');
        return false;
      }

      // Replace {id} in the URL with the actual SOS alert ID
      String url =
          ApiConfig.baseUrl +
          ApiConfig.cancelSosAlert.replaceAll('{id}', '${_activeAlert!.id}');

      debugPrint('🌐 Cancelling SOS at: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Cancel SOS status: ${response.statusCode}');
      debugPrint('📡 Cancel SOS body: ${response.body}');

      if (response.statusCode == 200) {
        _activeAlert = null;
        debugPrint('✅ SOS alert cancelled successfully');
        return true;
      } else {
        debugPrint(
          '❌ Failed to cancel SOS alert: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception canceling SOS alert: $e');
      return false;
    }
  }

  // Check active SOS alert using safe API call
  Future<SosAlert?> checkActiveSOSAlert() async {
    String? token = await _authService.getToken();
    if (token == null) return null;

    final apiCall = http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/sos/active'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    final result = await safeApiCall(apiCall);
    if (result != null &&
        result.containsKey('sos_alert') &&
        result['sos_alert'] != null) {
      return SosAlert.fromJson(result['sos_alert']);
    }
    return null;
  }
}

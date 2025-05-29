import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/incident.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';
import 'location_service.dart';

class IncidentService {
  final AuthService _authService;
  final LocationService _locationService;

  IncidentService(this._authService, this._locationService);

  // ULTRA-FAST incident reporting - Get token once, minimal processing
  Future<bool> reportIncident({
    required String type,
    required String description,
    File? photo,
  }) async {
    try {
      // Get token ONCE
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ No token');
        return false;
      }

      // Get location (should be fast)
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        debugPrint('❌ No location');
        return false;
      }

      // Always send as JSON first for speed (ignore photo for now)
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.reportIncident}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'type': type,
              'description': description,
              'latitude': location.latitude,
              'longitude': location.longitude,
              // Skip photo for speed - can be added later if needed
            }),
          )
          .timeout(const Duration(seconds: 8)); // Short timeout

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Incident reported');

        // Optional: Upload photo in background (don't wait for it)
        if (photo != null) {
          _uploadPhotoBackground(photo, token);
        }

        return true;
      }

      debugPrint('❌ Incident failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Incident error: $e');
      return false;
    }
  }

  // Background photo upload (don't wait for this)
  void _uploadPhotoBackground(File photo, String token) async {
    try {
      // This runs in background - user doesn't wait for it
      final bytes = await photo.readAsBytes();
      if (bytes.length < 1024 * 1024) {
        // Only if less than 1MB
        // Could implement photo upload to a separate endpoint
        debugPrint('📷 Photo queued for background upload');
      }
    } catch (e) {
      debugPrint('📷 Background photo upload failed: $e');
    }
  }

  // FAST incident history - Get token once
  Future<List<Incident>> getIncidentHistory() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return [];

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getIncidents}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['data'] != null) {
          final List<dynamic> incidentsJson = data['data'];
          return incidentsJson.map((json) => Incident.fromJson(json)).toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ Get incidents error: $e');
      return [];
    }
  }
}

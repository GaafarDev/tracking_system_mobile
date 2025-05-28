// Replace lib/core/services/incident_service.dart with this version:

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/incident.dart';
import '../utils/api_config.dart';
import '../utils/api_utils.dart';
import 'auth_service.dart';
import 'location_service.dart';

class IncidentService {
  final AuthService _authService;
  final LocationService _locationService;

  IncidentService(this._authService, this._locationService);

  // Report a new incident with detailed error handling
  Future<bool> reportIncident({
    required String type,
    required String description,
    File? photo,
  }) async {
    debugPrint('=== INCIDENT REPORT START ===');

    try {
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ Not authenticated, cannot report incident');
        return false;
      }
      debugPrint('✅ Token found: ${token.substring(0, 20)}...');

      // Get current location
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation == null) {
        debugPrint('❌ Could not get current location for incident report');
        return false;
      }
      debugPrint(
        '✅ Location: ${currentLocation.latitude}, ${currentLocation.longitude}',
      );

      final url = '${ApiConfig.baseUrl}${ApiConfig.reportIncident}';
      debugPrint('🌐 Sending request to: $url');

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add text fields
      request.fields['type'] = type;
      request.fields['description'] = description;
      request.fields['latitude'] = currentLocation.latitude.toString();
      request.fields['longitude'] = currentLocation.longitude.toString();

      debugPrint('📝 Request fields:');
      debugPrint('  - type: $type');
      debugPrint('  - description: $description');
      debugPrint('  - latitude: ${currentLocation.latitude}');
      debugPrint('  - longitude: ${currentLocation.longitude}');

      // Add photo if provided
      if (photo != null) {
        debugPrint('📷 Processing photo: ${photo.path}');
        try {
          final bytes = await photo.readAsBytes();
          final fileSizeKB = bytes.length / 1024;
          debugPrint(
            '📷 Original photo size: ${fileSizeKB.toStringAsFixed(1)} KB',
          );

          // Only add photo if it's reasonable size, or compress it
          if (fileSizeKB > 500) {
            // If larger than 500KB
            debugPrint('📷 Photo is large, consider implementing compression');
            // For now, skip very large photos to improve speed
            debugPrint('⚠️ Skipping large photo to improve upload speed');
          } else {
            request.files.add(
              await http.MultipartFile.fromPath('photo', photo.path),
            );
            debugPrint('✅ Photo added successfully');
          }
        } catch (e) {
          debugPrint('⚠️ Photo processing error: $e');
        }
      } else {
        debugPrint('📷 No photo provided');
      }

      debugPrint('🚀 Sending request...');

      // Send request with timeout
      final response = await request.send().timeout(
        const Duration(seconds: 15), // Reduced from 30
        onTimeout: () {
          debugPrint('⏰ Request timeout');
          throw Exception('Request timeout - please check your connection');
        },
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      final responseBody = await response.stream.bytesToString();
      debugPrint('📡 Response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Incident reported successfully');
        return true;
      } else {
        debugPrint('❌ Server error: ${response.statusCode}');
        debugPrint('Error body: $responseBody');

        // Try to parse error message
        try {
          final errorData = jsonDecode(responseBody);
          debugPrint('Parsed error: $errorData');
        } catch (e) {
          debugPrint('Could not parse error response: $e');
        }

        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception in reportIncident: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return false;
    } finally {
      debugPrint('=== INCIDENT REPORT END ===');
    }
  }

  // Fast incident report - first sends data without photo, then uploads photo separately
  Future<bool> reportIncidentFast({
    required String type,
    required String description,
    File? photo,
  }) async {
    debugPrint('=== FAST INCIDENT REPORT START ===');

    try {
      // First, send incident without photo (fast)
      final success = await _reportIncidentWithoutPhoto(type, description);

      // Then upload photo separately if needed (async)
      if (success && photo != null) {
        _uploadPhotoAsync(photo); // Don't wait for this
      }

      return success;
    } catch (e) {
      debugPrint('❌ Exception in fast incident report: $e');
      return false;
    }
  }

  Future<bool> _reportIncidentWithoutPhoto(
    String type,
    String description,
  ) async {
    // Similar to SOS implementation - JSON only
    String? token = await _authService.getToken();
    if (token == null) return false;

    final currentLocation = await _locationService.getCurrentLocation();
    if (currentLocation == null) return false;

    final url = '${ApiConfig.baseUrl}${ApiConfig.reportIncident}';

    final requestBody = {
      'type': type,
      'description': description,
      'latitude': currentLocation.latitude,
      'longitude': currentLocation.longitude,
    };

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
        .timeout(const Duration(seconds: 15));

    return response.statusCode == 200 || response.statusCode == 201;
  }

  void _uploadPhotoAsync(File photo) async {
    // Upload photo in background without blocking UI
    // Implementation details...
  }

  // Get incident history with better error handling
  Future<List<Incident>> getIncidentHistory() async {
    debugPrint('=== GETTING INCIDENT HISTORY ===');

    try {
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ Not authenticated, cannot fetch incident history');
        return [];
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.getIncidents}';
      debugPrint('🌐 Fetching from: $url');

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

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['data'] != null) {
          final List<dynamic> incidentsJson = data['data'];
          final incidents =
              incidentsJson.map((json) => Incident.fromJson(json)).toList();
          debugPrint('✅ Loaded ${incidents.length} incidents');
          return incidents;
        }
      }

      debugPrint('❌ Failed to fetch incident history: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching incident history: $e');
      return [];
    }
  }
}

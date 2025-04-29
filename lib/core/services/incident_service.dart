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

  // Report a new incident
  Future<bool> reportIncident({
    required String type,
    required String description,
    File? photo,
  }) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('Not authenticated, cannot report incident');
        return false;
      }

      // Get current location
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation == null) {
        debugPrint('Could not get current location for incident report');
        return false;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.reportIncident}'),
      );

      // Add authorization header
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Add text fields
      request.fields['type'] = type;
      request.fields['description'] = description;
      request.fields['latitude'] = currentLocation.latitude.toString();
      request.fields['longitude'] = currentLocation.longitude.toString();

      // Add photo if provided
      if (photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', photo.path),
        );
      }

      // Send request
      final response = await request.send();
      debugPrint('Incident report response status: ${response.statusCode}');

      final responseBody = await response.stream.bytesToString();
      debugPrint('Incident report response: $responseBody');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error reporting incident: $e');
      return false;
    }
  }

  // Get incident history
  Future<List<Incident>> getIncidentHistory() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('Not authenticated, cannot fetch incident history');
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getIncidents}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = await safeApiCall(Future.value(response));
        if (data != null && data['data'] != null) {
          final List<dynamic> incidentsJson = data['data'];
          return incidentsJson.map((json) => Incident.fromJson(json)).toList();
        }
      }

      debugPrint('Failed to fetch incident history: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Error fetching incident history: $e');
      return [];
    }
  }
}

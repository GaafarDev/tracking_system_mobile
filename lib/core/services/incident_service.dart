import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/incident.dart';
import '../utils/api_config.dart';
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
        print('Not authenticated, cannot report incident');
        return false;
      }

      // Get current location
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation == null) {
        print('Could not get current location for incident report');
        return false;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.reportIncident}'),
      );

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add text fields
      request.fields.addAll({
        'type': type,
        'description': description,
        'latitude': currentLocation.latitude.toString(),
        'longitude': currentLocation.longitude.toString(),
      });

      // Add photo if available
      if (photo != null) {
        final photoStream = http.ByteStream(photo.openRead());
        final photoLength = await photo.length();
        final multipartFile = http.MultipartFile(
          'photo',
          photoStream,
          photoLength,
          filename: photo.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Failed to report incident: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error reporting incident: $e');
      return false;
    }
  }

  // Get incident history
  Future<List<Incident>> getIncidentHistory() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        print('Not authenticated, cannot fetch incidents');
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/incidents'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> incidentsJson = jsonDecode(response.body)['data'];
        return incidentsJson.map((json) => Incident.fromJson(json)).toList();
      } else {
        print('Failed to fetch incidents: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching incidents: $e');
      return [];
    }
  }
}

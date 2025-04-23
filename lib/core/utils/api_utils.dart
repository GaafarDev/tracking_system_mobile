import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Safely handles API responses, dealing with non-JSON responses
Future<dynamic> safeApiCall(Future<http.Response> apiCall) async {
  try {
    final response = await apiCall;

    if (response.statusCode == 200) {
      // Check if response is actually JSON
      if (response.headers['content-type']?.contains('application/json') ==
          true) {
        return jsonDecode(response.body);
      } else {
        // If response starts with HTML tags, it's likely an error page
        if (response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          print(
            'Received HTML instead of JSON: ${response.body.substring(0, min(100, response.body.length))}...',
          );
          return null;
        }

        // Try to parse anyway in case content-type is wrong
        try {
          return jsonDecode(response.body);
        } catch (e) {
          print(
            'Failed to parse response: ${response.body.substring(0, min(100, response.body.length))}...',
          );
          return null;
        }
      }
    } else {
      print('Server error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('API error: $e');
    return null;
  }
}

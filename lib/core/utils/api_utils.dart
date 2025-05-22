import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Safely handles API responses, dealing with non-JSON responses
Future<dynamic> safeApiCall(Future<http.Response> apiCall) async {
  try {
    final response = await apiCall;

    // Log response for debugging
    debugPrint('API response status: ${response.statusCode}');
    debugPrint('API response headers: ${response.headers}');
    debugPrint(
      'API response body preview: ${response.body.substring(0, min(100, response.body.length))}...',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Check if response is actually JSON
      if (response.headers['content-type']?.contains('application/json') ==
          true) {
        return jsonDecode(response.body);
      } else {
        // If response starts with HTML tags, it's likely an error page
        if (response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          debugPrint(
            'Received HTML instead of JSON: ${response.body.substring(0, min(100, response.body.length))}...',
          );
          return null;
        }
        // Try to parse anyway in case content-type is wrong
        try {
          return jsonDecode(response.body);
        } catch (e) {
          debugPrint(
            'Failed to parse response: ${response.body.substring(0, min(100, response.body.length))}...',
          );
          return null;
        }
      }
    } else {
      debugPrint('API call failed with status: ${response.statusCode}');
      try {
        return jsonDecode(response.body);
      } catch (e) {
        debugPrint('Failed to parse error response: $e');
        return null;
      }
    }
  } catch (e) {
    debugPrint('API call exception: $e');
    return null;
  }
}

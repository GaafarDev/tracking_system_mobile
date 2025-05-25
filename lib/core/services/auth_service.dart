// Replace lib/core/services/auth_service.dart with this enhanced version:

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/driver.dart';
import '../utils/api_config.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  User? _currentUser;
  Driver? _currentDriver;

  User? get currentUser => _currentUser;
  Driver? get currentDriver => _currentDriver;

  // Enhanced login method with debugging
  Future<bool> login(String email, String password) async {
    debugPrint('=== LOGIN START ===');
    debugPrint('Email: $email');

    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.login}';
      debugPrint('🌐 Login URL: $url');

      final requestBody = {'email': email, 'password': password};
      debugPrint('📝 Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Login response status: ${response.statusCode}');
      debugPrint('📡 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save token with validation
        if (data['token'] != null) {
          final token = data['token'].toString();
          await _storage.write(key: 'auth_token', value: token);
          debugPrint('✅ Token saved: ${token.substring(0, 20)}...');
        } else {
          debugPrint('❌ No token in login response');
          return false;
        }

        // Parse user data
        if (data['user'] != null) {
          _currentUser = User.fromJson(data['user']);
          debugPrint('✅ User loaded: ${_currentUser!.name}');
        }

        // Parse driver data if available
        if (data['driver'] != null) {
          _currentDriver = Driver.fromJson(data['driver']);
          debugPrint('✅ Driver loaded: ${_currentDriver!.licenseNumber}');
        }

        debugPrint('✅ Login successful');
        return true;
      } else {
        debugPrint('❌ Login failed: ${response.statusCode}');
        debugPrint('Error body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Login exception: $e');
      return false;
    } finally {
      debugPrint('=== LOGIN END ===');
    }
  }

  // Enhanced token retrieval with validation
  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        debugPrint('🔑 Token retrieved: ${token.substring(0, 20)}...');
        // Validate token format
        if (token.contains('|') && token.length > 40) {
          debugPrint('✅ Token format looks valid');
          return token;
        } else {
          debugPrint('⚠️ Token format looks invalid: $token');
          return token; // Return anyway, let the server validate
        }
      } else {
        debugPrint('❌ No token found in storage');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  // Check authentication with enhanced debugging
  Future<bool> checkAuthentication() async {
    debugPrint('=== CHECKING AUTHENTICATION ===');

    final token = await getToken();
    if (token == null) {
      debugPrint('❌ No token available');
      return false;
    }

    try {
      final url = '${ApiConfig.baseUrl}/api/user';
      debugPrint('🌐 Auth check URL: $url');

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

      debugPrint('📡 Auth check status: ${response.statusCode}');
      debugPrint('📡 Auth check body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);
        debugPrint('✅ Authentication valid for user: ${_currentUser!.name}');

        // Fetch driver information if needed
        await _loadDriverInfo();

        return true;
      } else {
        // Token invalid or expired
        debugPrint('❌ Authentication failed: ${response.statusCode}');
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Authentication check error: $e');
      return false;
    }
  }

  // Load driver information with debugging
  Future<void> _loadDriverInfo() async {
    if (_currentUser == null) {
      debugPrint('❌ Cannot load driver info: no user loaded');
      return;
    }

    try {
      final token = await getToken();
      if (token == null) {
        debugPrint('❌ Cannot load driver info: no token');
        return;
      }

      final url = '${ApiConfig.baseUrl}/api/drivers/me';
      debugPrint('🌐 Loading driver from: $url');

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

      debugPrint('📡 Driver info status: ${response.statusCode}');
      debugPrint('📡 Driver info body: ${response.body}');

      if (response.statusCode == 200) {
        final driverData = jsonDecode(response.body);
        _currentDriver = Driver.fromJson(driverData);
        debugPrint('✅ Driver info loaded: ${_currentDriver!.licenseNumber}');
      } else {
        debugPrint('❌ Failed to load driver info: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Load driver info error: $e');
    }
  }

  // Logout method with cleanup
  Future<void> logout() async {
    debugPrint('=== LOGOUT START ===');

    try {
      String? token = await getToken();
      if (token != null) {
        final url = '${ApiConfig.baseUrl}${ApiConfig.logout}';
        debugPrint('🌐 Logout URL: $url');

        await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 30));

        debugPrint('✅ Logout request sent');
      }
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
    } finally {
      // Clear stored data regardless of logout success
      await _storage.delete(key: 'auth_token');
      _currentUser = null;
      _currentDriver = null;
      debugPrint('✅ Local data cleared');
      debugPrint('=== LOGOUT END ===');
    }
  }

  // Check if the user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final isLoggedIn = token != null;
    debugPrint('🔍 Is logged in: $isLoggedIn');
    return isLoggedIn;
  }
}

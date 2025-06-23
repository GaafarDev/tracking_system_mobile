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
  String? _cachedToken;

  User? get currentUser => _currentUser;
  Driver? get currentDriver => _currentDriver;

  // Optimized login method - reduced debugging
  Future<bool> login(String email, String password) async {
    debugPrint('🚀 Starting login for: $email');

    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.login}';
      final requestBody = {'email': email, 'password': password};

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save token and cache it
        if (data['token'] != null) {
          final token = data['token'].toString();
          await _storage.write(key: 'auth_token', value: token);
          _cachedToken = token; // Cache the token
          debugPrint('✅ Login successful');
        } else {
          debugPrint('❌ No token in response');
          return false;
        }

        // Parse user data
        if (data['user'] != null) {
          _currentUser = User.fromJson(data['user']);
        }

        // Parse driver data if available
        if (data['driver'] != null) {
          _currentDriver = Driver.fromJson(data['driver']);
        }

        return true;
      } else {
        debugPrint('❌ Login failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return false;
    }
  }

  // OPTIMIZED: Get token with caching to avoid repeated storage reads
  Future<String?> getToken() async {
    try {
      // Return cached token if available
      if (_cachedToken != null) {
        return _cachedToken;
      }

      // Only read from storage if not cached
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        _cachedToken = token; // Cache for future use
        return token;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  // Optimized authentication check - reduced debugging
  Future<bool> checkAuthentication() async {
    final token = await getToken();
    if (token == null) {
      debugPrint('❌ No token available');
      return false;
    }

    try {
      final url = '${ApiConfig.baseUrl}/api/user';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);

        // Load driver info if needed
        await _loadDriverInfo();

        debugPrint('✅ Authentication valid');
        return true;
      } else {
        debugPrint('❌ Authentication failed: ${response.statusCode}');
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Auth check error: $e');
      return false;
    }
  }

  // Optimized driver info loading - reduced debugging
  Future<void> _loadDriverInfo() async {
    if (_currentUser == null) return;

    try {
      final token = await getToken();
      if (token == null) return;

      final url = '${ApiConfig.baseUrl}/api/drivers/me';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final driverData = jsonDecode(response.body);
        _currentDriver = Driver.fromJson(driverData);
        debugPrint('✅ Driver info loaded');
      }
    } catch (e) {
      debugPrint('❌ Load driver error: $e');
    }
  }

  // Optimized logout - clear cache
  Future<void> logout() async {
    try {
      String? token = await getToken();
      if (token != null) {
        final url = '${ApiConfig.baseUrl}${ApiConfig.logout}';

        await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
    } finally {
      // Clear all cached data
      await _storage.delete(key: 'auth_token');
      _cachedToken = null;
      _currentUser = null;
      _currentDriver = null;
      debugPrint('✅ Logout completed');
    }
  }

  // Check if logged in using cached token
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}

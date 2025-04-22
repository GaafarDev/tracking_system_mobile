import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/driver.dart';
import '../utils/api_config.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  User? _currentUser;
  Driver? _currentDriver;

  User? get currentUser => _currentUser;
  Driver? get currentDriver => _currentDriver;

  // Login method
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save token
        await _storage.write(key: 'auth_token', value: data['token']);

        // Parse user data
        if (data['user'] != null) {
          _currentUser = User.fromJson(data['user']);
        }

        // Parse driver data if available
        if (data['driver'] != null) {
          _currentDriver = Driver.fromJson(data['driver']);
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Check login status and load user data
  Future<bool> checkAuthentication() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);

        // Fetch driver information if needed
        await _loadDriverInfo();

        return true;
      } else {
        // Token invalid or expired
        await logout();
        return false;
      }
    } catch (e) {
      print('Authentication check error: $e');
      return false;
    }
  }

  // Load driver information
  Future<void> _loadDriverInfo() async {
    if (_currentUser == null) return;

    try {
      final token = await getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/drivers/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final driverData = jsonDecode(response.body);
        _currentDriver = Driver.fromJson(driverData);
      }
    } catch (e) {
      print('Load driver info error: $e');
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      String? token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logout}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Clear stored data
      await _storage.delete(key: 'auth_token');
      _currentUser = null;
      _currentDriver = null;
    }
  }

  // Get the stored authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Check if the user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}

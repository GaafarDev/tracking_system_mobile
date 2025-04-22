import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/api_config.dart';

class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'auth_token', value: data['token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

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
      await _storage.delete(key: 'auth_token');
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}

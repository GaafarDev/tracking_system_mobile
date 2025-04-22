import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_notification.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

class NotificationService {
  final AuthService _authService;
  int _unreadCount = 0;

  NotificationService(this._authService);

  int get unreadCount => _unreadCount;

  // Get all notifications
  Future<List<AppNotification>> getNotifications() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        print('Not authenticated, cannot fetch notifications');
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getNotifications}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notificationsJson = data['data'];
        return notificationsJson
            .map((json) => AppNotification.fromJson(json))
            .toList();
      } else {
        print('Failed to fetch notifications: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Get unread notifications
  Future<List<AppNotification>> getUnreadNotifications() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        print('Not authenticated, cannot fetch unread notifications');
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getUnreadNotifications}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> notificationsJson = jsonDecode(response.body);
        final notifications =
            notificationsJson
                .map((json) => AppNotification.fromJson(json))
                .toList();
        _unreadCount = notifications.length;
        return notifications;
      } else {
        print('Failed to fetch unread notifications: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching unread notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        print('Not authenticated, cannot mark notification as read');
        return false;
      }

      final endpoint = ApiConfig.markNotificationRead.replaceAll(
        '{id}',
        notificationId.toString(),
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (_unreadCount > 0) _unreadCount--;
        return true;
      } else {
        print('Failed to mark notification as read: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Refresh unread count
  Future<int> refreshUnreadCount() async {
    final notifications = await getUnreadNotifications();
    _unreadCount = notifications.length;
    return _unreadCount;
  }
}

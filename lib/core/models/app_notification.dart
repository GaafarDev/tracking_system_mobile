class AppNotification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      isRead: json['is_read'] == true || json['is_read'] == 1,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Helper methods to categorize notifications
  bool get isScheduleNotification => type == 'schedule';
  bool get isWeatherNotification => type == 'weather';
  bool get isSosNotification => type == 'sos';

  // Get icon for notification type
  String get iconName {
    switch (type) {
      case 'schedule':
        return 'calendar';
      case 'weather':
        return 'cloud';
      case 'sos':
        return 'alert_triangle';
      case 'incident':
        return 'warning';
      default:
        return 'bell';
    }
  }

  // Get color for notification type
  String get colorHex {
    switch (type) {
      case 'schedule':
        return '#4CAF50'; // Green
      case 'weather':
        return '#2196F3'; // Blue
      case 'sos':
        return '#F44336'; // Red
      case 'incident':
        return '#FF9800'; // Orange
      default:
        return '#9E9E9E'; // Gray
    }
  }
}

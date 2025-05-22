class ApiConfig {
  // Use the correct base URL for your setup
  // For Flutter web running on localhost:5965 connecting to Laravel on 127.0.0.1:8000
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Auth endpoints
  static const String login = '/api/login';
  static const String logout = '/api/logout';

  // Driver endpoints
  static const String updateLocation = '/api/locations/update';

  // Incident endpoints
  static const String reportIncident = '/api/incidents/report';
  static const String getIncidents = '/api/incidents';

  // SOS endpoints
  static const String sendSosAlert = '/api/sos/send';
  static const String getActiveSosAlert = '/api/sos/active';
  static const String cancelSosAlert = '/api/sos/{id}/cancel';

  // Notifications endpoints
  static const String getNotifications = '/api/notifications';
  static const String getUnreadNotifications = '/api/notifications/unread';
  static const String markNotificationRead = '/api/notifications/{id}/read';

  // Weather updates
  static const String getWeatherUpdates = '/api/weather/latest';

  // Schedule endpoints
  static const String getSchedules = '/api/schedules';
}

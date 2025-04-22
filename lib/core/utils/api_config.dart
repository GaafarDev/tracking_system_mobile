class ApiConfig {
  // Base URL - Change this to your Laravel backend URL
  // For Android emulator, 10.0.2.2 points to host machine's localhost
  // For iOS simulator, use localhost or 127.0.0.1
  // For real devices, use your actual server IP or domain
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Auth endpoints
  static const String login = '/api/login';
  static const String logout = '/api/logout';

  // Driver endpoints
  static const String updateLocation = '/api/locations/update';

  // Incident endpoints
  static const String reportIncident = '/api/incidents/report';

  // SOS endpoints
  static const String sendSosAlert = '/api/sos/send';

  // Notifications endpoints
  static const String getNotifications = '/api/notifications';
  static const String getUnreadNotifications = '/api/notifications/unread';
  static const String markNotificationRead = '/api/notifications/{id}/read';

  // Weather updates
  static const String getWeatherUpdates = '/api/weather/latest';

  // Schedule endpoints
  static const String getSchedules = '/api/schedules';
}

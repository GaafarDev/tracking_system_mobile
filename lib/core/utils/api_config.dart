class ApiConfig {
  // Change this to your Laravel backend URL
  static const String baseUrl = 'http://10.0.2.2:8000';

  // API endpoints
  static const String login = '/api/login';
  static const String register = '/api/register';
  static const String logout = '/api/logout';
  static const String updateLocation = '/api/location/update';
  static const String reportIncident = '/api/incidents/report';
}

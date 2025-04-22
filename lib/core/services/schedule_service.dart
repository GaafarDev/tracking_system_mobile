import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/schedule.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

class ScheduleService {
  final AuthService _authService;

  ScheduleService(this._authService);

  // Get current driver's schedules
  Future<List<Schedule>> getSchedules() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        print('Not authenticated, cannot fetch schedules');
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getSchedules}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> schedulesJson = data['data'];
        final schedules =
            schedulesJson.map((json) => Schedule.fromJson(json)).toList();

        // Sort schedules by day of week and then by departure time
        schedules.sort((a, b) {
          // First sort by day of week
          if (a.dayIndex != b.dayIndex) {
            return a.dayIndex.compareTo(b.dayIndex);
          }

          // Then sort by departure time
          return a.departureTime.compareTo(b.departureTime);
        });

        return schedules;
      } else {
        print('Failed to fetch schedules: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching schedules: $e');
      return [];
    }
  }

  // Get today's schedules
  Future<List<Schedule>> getTodaySchedules() async {
    final allSchedules = await getSchedules();
    return allSchedules.where((schedule) => schedule.isToday).toList();
  }

  // Get schedules for specific day
  Future<List<Schedule>> getSchedulesForDay(String dayOfWeek) async {
    final allSchedules = await getSchedules();
    return allSchedules
        .where(
          (schedule) =>
              schedule.dayOfWeek.toLowerCase() == dayOfWeek.toLowerCase(),
        )
        .toList();
  }

  // Get schedule details
  Future<Schedule?> getScheduleDetails(int scheduleId) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) {
        print('Not authenticated, cannot fetch schedule details');
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getSchedules}/$scheduleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Schedule.fromJson(data);
      } else {
        print('Failed to fetch schedule details: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching schedule details: $e');
      return null;
    }
  }
}

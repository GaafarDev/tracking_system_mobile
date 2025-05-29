import 'dart:convert';
import 'package:flutter/material.dart';
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
      debugPrint('🔄 Starting to fetch schedules...');

      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ Not authenticated, cannot fetch schedules');
        return [];
      }

      debugPrint('✅ Token obtained: ${token.substring(0, 20)}...');
      debugPrint(
        '📡 Making request to: ${ApiConfig.baseUrl}${ApiConfig.getSchedules}',
      );

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getSchedules}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📨 Response received:');
      debugPrint('  Status Code: ${response.statusCode}');
      debugPrint('  Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          debugPrint('📊 Parsed JSON data keys: ${data.keys}');

          // Check if data field exists
          if (data['data'] == null) {
            debugPrint('⚠️ No "data" field in response');
            return [];
          }

          final List<dynamic> schedulesJson = data['data'];
          debugPrint('📋 Schedules array length: ${schedulesJson.length}');

          if (schedulesJson.isEmpty) {
            debugPrint(
              '⚠️ Empty schedules array - driver might have no schedules',
            );
            return [];
          }

          debugPrint('🔍 Processing schedules...');
          final schedules = <Schedule>[];

          for (int i = 0; i < schedulesJson.length; i++) {
            try {
              debugPrint('  Processing schedule $i: ${schedulesJson[i]}');
              final schedule = Schedule.fromJson(schedulesJson[i]);
              schedules.add(schedule);
              debugPrint('  ✅ Successfully parsed schedule ${schedule.id}');
            } catch (parseError) {
              debugPrint('  ❌ Error parsing schedule $i: $parseError');
              debugPrint('  Raw data: ${schedulesJson[i]}');
            }
          }

          debugPrint('✅ Successfully parsed ${schedules.length} schedules');

          // Sort schedules by day of week and then by departure time
          schedules.sort((a, b) {
            // First sort by day of week
            if (a.dayIndex != b.dayIndex) {
              return a.dayIndex.compareTo(b.dayIndex);
            }

            // Then sort by departure time
            return a.departureTime.compareTo(b.departureTime);
          });

          debugPrint(
            '✅ Schedules sorted and ready to return: ${schedules.length}',
          );
          return schedules;
        } catch (parseError) {
          debugPrint('❌ JSON parsing error: $parseError');
          debugPrint('Raw response body: ${response.body}');
          return [];
        }
      } else {
        debugPrint('❌ Failed to fetch schedules: ${response.statusCode}');
        debugPrint('Error response body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('💥 Error fetching schedules: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get today's schedules
  Future<List<Schedule>> getTodaySchedules() async {
    debugPrint('🔄 Fetching today\'s schedules...');
    final allSchedules = await getSchedules();
    final todaySchedules =
        allSchedules.where((schedule) => schedule.isToday).toList();
    debugPrint('📋 Found ${todaySchedules.length} schedules for today');
    return todaySchedules;
  }

  // Get schedules for specific day
  Future<List<Schedule>> getSchedulesForDay(String dayOfWeek) async {
    debugPrint('🔄 Fetching schedules for: $dayOfWeek');
    final allSchedules = await getSchedules();
    final daySchedules =
        allSchedules
            .where(
              (schedule) =>
                  schedule.dayOfWeek.toLowerCase() == dayOfWeek.toLowerCase(),
            )
            .toList();
    debugPrint('📋 Found ${daySchedules.length} schedules for $dayOfWeek');
    return daySchedules;
  }

  // Get schedule details
  Future<Schedule?> getScheduleDetails(int scheduleId) async {
    try {
      debugPrint('🔄 Fetching schedule details for ID: $scheduleId');

      String? token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ Not authenticated, cannot fetch schedule details');
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getSchedules}/$scheduleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📨 Schedule details response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('📊 Schedule details data: $data');
        return Schedule.fromJson(data);
      } else {
        debugPrint('❌ Failed to fetch schedule details: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Error fetching schedule details: $e');
      return null;
    }
  }
}

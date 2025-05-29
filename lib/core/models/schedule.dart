import 'dart:convert';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint

class Schedule {
  final int id;
  final int routeId;
  final int driverId;
  final int vehicleId;
  final String departureTime;
  final String arrivalTime;
  final String dayOfWeek;
  final bool isActive;
  final Route? route;
  final Vehicle? vehicle;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.routeId,
    required this.driverId,
    required this.vehicleId,
    required this.departureTime,
    required this.arrivalTime,
    required this.dayOfWeek,
    required this.isActive,
    this.route,
    this.vehicle,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      routeId: json['route_id'],
      driverId: json['driver_id'],
      vehicleId: json['vehicle_id'],
      departureTime: json['departure_time'],
      arrivalTime: json['arrival_time'],
      dayOfWeek: json['day_of_week'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
      route: json['route'] != null ? Route.fromJson(json['route']) : null,
      vehicle:
          json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Return day index for sorting (Monday = 0, Sunday = 6)
  int get dayIndex {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday':
        return 0;
      case 'tuesday':
        return 1;
      case 'wednesday':
        return 2;
      case 'thursday':
        return 3;
      case 'friday':
        return 4;
      case 'saturday':
        return 5;
      case 'sunday':
        return 6;
      default:
        return 7; // For unknown days
    }
  }

  // Format day name properly with capitalization
  String get displayDay {
    return dayOfWeek.substring(0, 1).toUpperCase() + dayOfWeek.substring(1);
  }

  // Check if schedule is for today
  bool get isToday {
    final now = DateTime.now();
    final today = now.weekday; // 1 = Monday, 7 = Sunday
    return today - 1 == dayIndex; // Adjust to match our index (0 = Monday)
  }

  // Format time range for display
  String get timeRange {
    return '$departureTime - $arrivalTime';
  }
}

class Route {
  final int id;
  final String name;
  final String? description;
  final List<Map<String, dynamic>>? waypoints;
  final List<Map<String, dynamic>>? stops;
  final double? distanceKm;
  final int? estimatedDurationMinutes;

  Route({
    required this.id,
    required this.name,
    this.description,
    this.waypoints,
    this.stops,
    this.distanceKm,
    this.estimatedDurationMinutes,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    // Helper function to parse waypoints/stops that might be strings or arrays
    List<Map<String, dynamic>>? parsePointsData(dynamic data) {
      if (data == null) return null;

      if (data is String) {
        // If it's a string, try to parse it as JSON
        if (data.isEmpty || data == '[]') return [];

        try {
          final decoded = jsonDecode(data);
          if (decoded is List) {
            return List<Map<String, dynamic>>.from(decoded);
          }
        } catch (e) {
          debugPrint('Error parsing points data: $e');
          return [];
        }
      } else if (data is List) {
        // If it's already a list, convert it
        return List<Map<String, dynamic>>.from(data);
      }

      return [];
    }

    return Route(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      waypoints: parsePointsData(json['waypoints']),
      stops: parsePointsData(json['stops']),
      distanceKm:
          json['distance_km'] != null
              ? double.parse(json['distance_km'].toString())
              : null,
      estimatedDurationMinutes: json['estimated_duration_minutes'],
    );
  }

  // Format duration for display
  String get formattedDuration {
    if (estimatedDurationMinutes == null) return 'N/A';

    final hours = estimatedDurationMinutes! ~/ 60;
    final minutes = estimatedDurationMinutes! % 60;

    if (hours > 0) {
      return '$hours h ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }

  // Get stop count
  int get stopCount {
    return stops?.length ?? 0;
  }
}

class Vehicle {
  final int id;
  final String plateNumber;
  final String model;
  final int capacity;
  final String type;
  final String status;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.model,
    required this.capacity,
    required this.type,
    required this.status,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      plateNumber: json['plate_number'],
      model: json['model'],
      capacity: json['capacity'],
      type: json['type'],
      status: json['status'],
    );
  }

  // Vehicle display name
  String get displayName {
    return '$model ($plateNumber)';
  }

  bool get isActive => status == 'active';
}

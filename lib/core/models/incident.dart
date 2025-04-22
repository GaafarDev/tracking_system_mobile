class Incident {
  final int id;
  final int driverId;
  final String type;
  final String description;
  final double latitude;
  final double longitude;
  final String? photoPath;
  final String status;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Incident({
    required this.id,
    required this.driverId,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.photoPath,
    required this.status,
    this.resolvedAt,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'],
      driverId: json['driver_id'],
      type: json['type'],
      description: json['description'],
      latitude:
          json['latitude'] is String
              ? double.parse(json['latitude'])
              : json['latitude'].toDouble(),
      longitude:
          json['longitude'] is String
              ? double.parse(json['longitude'])
              : json['longitude'].toDouble(),
      photoPath: json['photo_path'],
      status: json['status'],
      resolvedAt:
          json['resolved_at'] != null
              ? DateTime.parse(json['resolved_at'])
              : null,
      resolutionNotes: json['resolution_notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get displayType {
    switch (type) {
      case 'accident':
        return 'Accident';
      case 'breakdown':
        return 'Vehicle Breakdown';
      case 'road_obstruction':
        return 'Road Obstruction';
      case 'weather':
        return 'Weather Issue';
      default:
        return type
            .split('_')
            .map(
              (word) => word.substring(0, 1).toUpperCase() + word.substring(1),
            )
            .join(' ');
    }
  }

  String get displayStatus {
    switch (status) {
      case 'reported':
        return 'Reported';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status
            .split('_')
            .map(
              (word) => word.substring(0, 1).toUpperCase() + word.substring(1),
            )
            .join(' ');
    }
  }

  bool get isActive => status == 'reported' || status == 'in_progress';
  bool get isResolved => status == 'resolved' || status == 'closed';
}

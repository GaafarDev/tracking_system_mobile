class SosAlert {
  final int id;
  final int driverId;
  final double latitude;
  final double longitude;
  final String? message;
  final String status;
  final DateTime? respondedAt;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SosAlert({
    required this.id,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.message,
    required this.status,
    this.respondedAt,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    return SosAlert(
      id: json['id'],
      driverId: json['driver_id'],
      latitude:
          json['latitude'] is String
              ? double.parse(json['latitude'])
              : json['latitude'].toDouble(),
      longitude:
          json['longitude'] is String
              ? double.parse(json['longitude'])
              : json['longitude'].toDouble(),
      message: json['message'],
      status: json['status'],
      respondedAt:
          json['responded_at'] != null
              ? DateTime.parse(json['responded_at'])
              : null,
      resolvedAt:
          json['resolved_at'] != null
              ? DateTime.parse(json['resolved_at'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Helper properties
  bool get isActive => status == 'active';
  bool get isResponded => status == 'responded';
  bool get isResolved => status == 'resolved';

  String get displayStatus {
    switch (status) {
      case 'active':
        return 'Active';
      case 'responded':
        return 'Responded';
      case 'resolved':
        return 'Resolved';
      default:
        return status.substring(0, 1).toUpperCase() + status.substring(1);
    }
  }
}

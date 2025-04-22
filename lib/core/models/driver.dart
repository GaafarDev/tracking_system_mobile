class Driver {
  final int id;
  final int userId;
  final String licenseNumber;
  final String phoneNumber;
  final String? address;
  final String status;

  Driver({
    required this.id,
    required this.userId,
    required this.licenseNumber,
    required this.phoneNumber,
    this.address,
    required this.status,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      userId: json['user_id'],
      licenseNumber: json['license_number'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'license_number': licenseNumber,
      'phone_number': phoneNumber,
      'address': address,
      'status': status,
    };
  }

  bool get isActive => status == 'active';
}

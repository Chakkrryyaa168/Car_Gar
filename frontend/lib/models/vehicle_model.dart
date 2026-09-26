class VehicleModel {
  final String id;
  final String owner;
  final String? ownerName;
  final String? ownerPhone;
  final String licensePlate;
  final String vin;
  final String make;
  final String model;
  final int year;
  final String color;
  final bool isVerified;

  VehicleModel({
    required this.id,
    required this.owner,
    this.ownerName,
    this.ownerPhone,
    required this.licensePlate,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.isVerified,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? '',
      owner: json['owner'] ?? '',
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      licensePlate: json['license_plate'] ?? '',
      vin: json['vin'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? '2022') ?? 2022,
      color: json['color'] ?? '',
      isVerified: json['is_verified'] ?? false,
    );
  }

  String get displayName => '$year $make $model ($licensePlate)';
}

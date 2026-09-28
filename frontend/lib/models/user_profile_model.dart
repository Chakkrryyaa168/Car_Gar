import 'json_helpers.dart';

class UserProfileModel {
  final String id;
  final String? avatarUrl;
  final String address;
  final String emergencyContact;

  // Customer metadata
  final String secondaryPhone;
  final String preferredContactChannel;
  final String billingAddress;
  final String savedPaymentMethod;
  final String? defaultVehicleId;
  final String? defaultVehicleDisplay;
  final String communicationPreferences;

  // Staff metadata (Mechanic, Receptionist, Admin)
  final String employeeId;
  final String specialization;
  final String bio;

  // Admin / Employment records
  final String? dateJoinedCompany;
  final double hourlyRate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfileModel({
    required this.id,
    this.avatarUrl,
    required this.address,
    required this.emergencyContact,
    required this.secondaryPhone,
    required this.preferredContactChannel,
    required this.billingAddress,
    required this.savedPaymentMethod,
    this.defaultVehicleId,
    this.defaultVehicleDisplay,
    required this.communicationPreferences,
    required this.employeeId,
    required this.specialization,
    required this.bio,
    this.dateJoinedCompany,
    required this.hourlyRate,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] ?? '',
      avatarUrl: json['avatar_url'],
      address: json['address'] ?? '',
      emergencyContact: json['emergency_contact'] ?? '',
      secondaryPhone: json['secondary_phone'] ?? '',
      preferredContactChannel: json['preferred_contact_channel'] ?? 'App push',
      billingAddress: json['billing_address'] ?? '',
      savedPaymentMethod: json['saved_payment_method'] ?? 'CREDIT_CARD',
      defaultVehicleId: json['default_vehicle'],
      defaultVehicleDisplay: json['default_vehicle_display'],
      communicationPreferences: json['communication_preferences'] ?? 'ALL',
      employeeId: json['employee_id'] ?? '',
      specialization: json['specialization'] ?? '',
      bio: json['bio'] ?? '',
      dateJoinedCompany: json['date_joined_company'],
      hourlyRate: parseDouble(json['hourly_rate']),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'address': address,
      'emergency_contact': emergencyContact,
      'secondary_phone': secondaryPhone,
      'preferred_contact_channel': preferredContactChannel,
      'billing_address': billingAddress,
      'saved_payment_method': savedPaymentMethod,
      'default_vehicle': defaultVehicleId,
      'communication_preferences': communicationPreferences,
      'employee_id': employeeId,
      'specialization': specialization,
      'bio': bio,
      if (dateJoinedCompany != null) 'date_joined_company': dateJoinedCompany,
      'hourly_rate': hourlyRate,
    };
  }

  UserProfileModel copyWith({
    String? avatarUrl,
    String? address,
    String? emergencyContact,
    String? secondaryPhone,
    String? preferredContactChannel,
    String? billingAddress,
    String? savedPaymentMethod,
    String? defaultVehicleId,
    String? defaultVehicleDisplay,
    String? communicationPreferences,
    String? employeeId,
    String? specialization,
    String? bio,
    String? dateJoinedCompany,
    double? hourlyRate,
  }) {
    return UserProfileModel(
      id: id,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      preferredContactChannel: preferredContactChannel ?? this.preferredContactChannel,
      billingAddress: billingAddress ?? this.billingAddress,
      savedPaymentMethod: savedPaymentMethod ?? this.savedPaymentMethod,
      defaultVehicleId: defaultVehicleId ?? this.defaultVehicleId,
      defaultVehicleDisplay: defaultVehicleDisplay ?? this.defaultVehicleDisplay,
      communicationPreferences: communicationPreferences ?? this.communicationPreferences,
      employeeId: employeeId ?? this.employeeId,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
      dateJoinedCompany: dateJoinedCompany ?? this.dateJoinedCompany,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

import 'user_profile_model.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String? customerCode;
  final String? fcmToken;
  final bool isActive;
  final UserProfileModel? profile;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.customerCode,
    this.fcmToken,
    this.isActive = true,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: (json['role'] ?? 'CUSTOMER').toString().toUpperCase(),
      customerCode: json['customer_code'],
      fcmToken: json['fcm_token'],
      isActive: json['is_active'] ?? true,
      profile: json['profile'] != null ? UserProfileModel.fromJson(json['profile']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role,
      'customer_code': customerCode,
      'fcm_token': fcmToken,
      if (profile != null) 'profile': profile!.toJson(),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? customerCode,
    String? fcmToken,
    UserProfileModel? profile,
  }) {
    return UserModel(
      id: id,
      username: username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role,
      customerCode: customerCode ?? this.customerCode,
      fcmToken: fcmToken ?? this.fcmToken,
      isActive: isActive,
      profile: profile ?? this.profile,
    );
  }
}

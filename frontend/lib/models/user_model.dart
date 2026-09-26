class UserModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String? fcmToken;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.fcmToken,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: (json['role'] ?? 'CUSTOMER').toString().toUpperCase(),
      fcmToken: json['fcm_token'],
      isActive: json['is_active'] ?? true,
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
      'fcm_token': fcmToken,
    };
  }
}

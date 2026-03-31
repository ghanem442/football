class AdminUserModel {
  final String id;
  final String email;
  final String role;
  final bool isVerified;
  final int noShowCount;
  final String? suspendedUntil;
  final String createdAt;

  const AdminUserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.noShowCount,
    required this.suspendedUntil,
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      isVerified: json['isVerified'] ?? false,
      noShowCount: json['noShowCount'] ?? 0,
      suspendedUntil: json['suspendedUntil'],
      createdAt: json['createdAt'],
    );
  }
}
class AdminFieldModel {
  final String id;
  final String name;
  final String address;
  final String? status;
  final double? basePrice;
  final double? commissionRate;
  final String? ownerId;
  final String? ownerName;
  final String? ownerEmail;
  final String createdAt;
  final String? deletedAt;

  const AdminFieldModel({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
    required this.basePrice,
    required this.commissionRate,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.createdAt,
    required this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isActive =>
      (status ?? '').trim().toUpperCase() == 'ACTIVE' && deletedAt == null;

  factory AdminFieldModel.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    final ownerMap =
        owner is Map<String, dynamic> ? owner : <String, dynamic>{};

    return AdminFieldModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      status: json['status']?.toString(),
      basePrice: _toDoubleOrNull(json['basePrice']),
      commissionRate: _toDoubleOrNull(json['commissionRate']),
      ownerId: ownerMap['id']?.toString(),
      ownerName: ownerMap['name']?.toString(),
      ownerEmail: ownerMap['email']?.toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      deletedAt: json['deletedAt']?.toString(),
    );
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
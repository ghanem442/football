class AdminWithdrawalRequestOwnerModel {
  final String id;
  final String? name;
  final String? email;

  const AdminWithdrawalRequestOwnerModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory AdminWithdrawalRequestOwnerModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminWithdrawalRequestOwnerModel(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class AdminWithdrawalRequestModel {
  final String id;
  final double amount;
  final String status;
  final String paymentMethod;
  final String? accountDetails;
  final String? payoutId;
  final String? rejectionReason;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AdminWithdrawalRequestOwnerModel? owner;

  const AdminWithdrawalRequestModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.accountDetails,
    required this.payoutId,
    required this.rejectionReason,
    required this.processedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.owner,
  });

  bool get isPending => status.trim().toUpperCase() == 'PENDING';
  bool get isApproved => status.trim().toUpperCase() == 'APPROVED';
  bool get isRejected => status.trim().toUpperCase() == 'REJECTED';

  factory AdminWithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime parseDate(dynamic value) {
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    final rawOwner = json['owner'];
    final owner = rawOwner is Map
        ? AdminWithdrawalRequestOwnerModel.fromJson(
            Map<String, dynamic>.from(rawOwner),
          )
        : null;

    return AdminWithdrawalRequestModel(
      id: (json['id'] ?? '').toString(),
      amount: asDouble(json['amount']),
      status: (json['status'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      accountDetails: json['accountDetails']?.toString(),
      payoutId: json['payoutId']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      processedAt: parseNullableDate(json['processedAt']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      owner: owner,
    );
  }
}
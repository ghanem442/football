class AdminWalletTransactionMetadata {
  final String? actorRole;
  final String? transactionPurpose;

  const AdminWalletTransactionMetadata({
    required this.actorRole,
    required this.transactionPurpose,
  });

  factory AdminWalletTransactionMetadata.fromJson(Map<String, dynamic> json) {
    return AdminWalletTransactionMetadata(
      actorRole: json['actorRole']?.toString(),
      transactionPurpose: json['transactionPurpose']?.toString(),
    );
  }
}

class AdminWalletTransactionModel {
  final String id;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final String? type;
  final double amount;
  final double? balanceBefore;
  final double? balanceAfter;
  final String? description;
  final String? reference;
  final String? createdAt;
  final AdminWalletTransactionMetadata? metadata;

  const AdminWalletTransactionModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    required this.reference,
    required this.createdAt,
    required this.metadata,
  });

  factory AdminWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final user = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : <String, dynamic>{};

    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? AdminWalletTransactionMetadata.fromJson(
            Map<String, dynamic>.from(rawMetadata),
          )
        : null;

    return AdminWalletTransactionModel(
      id: (json['id'] ?? '').toString(),
      userId: user['id']?.toString() ?? json['userId']?.toString(),
      userEmail: user['email']?.toString() ?? json['userEmail']?.toString(),
      userName: user['name']?.toString() ?? json['userName']?.toString(),
      type: json['type']?.toString(),
      amount: _toDouble(json['amount']) ?? 0.0,
      balanceBefore: _toDouble(json['balanceBefore']),
      balanceAfter: _toDouble(json['balanceAfter']),
      description: json['description']?.toString(),
      reference: json['reference']?.toString(),
      createdAt: json['createdAt']?.toString(),
      metadata: metadata,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
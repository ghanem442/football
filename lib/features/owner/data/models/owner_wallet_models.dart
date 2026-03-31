class OwnerWalletModel {
  final String id;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OwnerWalletModel({
    required this.id,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  String get currency => 'EGP';

  factory OwnerWalletModel.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime parseDate(dynamic value) {
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return OwnerWalletModel(
      id: (json['id'] ?? '').toString(),
      balance: asDouble(json['balance']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

class OwnerWalletTransactionMetadata {
  final String? actorRole;
  final String? transactionPurpose;

  const OwnerWalletTransactionMetadata({
    required this.actorRole,
    required this.transactionPurpose,
  });

  factory OwnerWalletTransactionMetadata.fromJson(Map<String, dynamic> json) {
    return OwnerWalletTransactionMetadata(
      actorRole: json['actorRole']?.toString(),
      transactionPurpose: json['transactionPurpose']?.toString(),
    );
  }
}

class OwnerWalletTransactionModel {
  final String id;
  final String type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? reference;
  final String? description;
  final DateTime createdAt;
  final OwnerWalletTransactionMetadata? metadata;

  const OwnerWalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.reference,
    required this.description,
    required this.createdAt,
    required this.metadata,
  });

  String? get actorRole => metadata?.actorRole;
  String? get transactionPurpose => metadata?.transactionPurpose;

  bool get isIncoming {
    final purpose = (transactionPurpose ?? '').trim().toUpperCase();
    final rawType = type.trim().toUpperCase();

    return purpose == 'OWNER_ONLINE_SHARE' ||
        purpose == 'OWNER_WITHDRAWAL_REVERSAL' ||
        rawType == 'CREDIT' ||
        rawType == 'DEPOSIT' ||
        rawType == 'REFUND';
  }

  bool get isOutgoing {
    final purpose = (transactionPurpose ?? '').trim().toUpperCase();
    final rawType = type.trim().toUpperCase();

    return purpose == 'OWNER_WITHDRAWAL' ||
        purpose == 'REFUND_REVERSAL' ||
        rawType == 'DEBIT' ||
        rawType == 'WITHDRAWAL' ||
        rawType == 'BOOKING_PAYMENT' ||
        rawType == 'PAYOUT' ||
        rawType == 'COMMISSION_DEDUCTION';
  }

  factory OwnerWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? OwnerWalletTransactionMetadata.fromJson(
            Map<String, dynamic>.from(rawMetadata),
          )
        : null;

    return OwnerWalletTransactionModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      amount: asDouble(json['amount']),
      balanceBefore: asDouble(json['balanceBefore']),
      balanceAfter: asDouble(json['balanceAfter']),
      reference: json['reference']?.toString(),
      description: json['description']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      metadata: metadata,
    );
  }
}

class OwnerWalletTransactionsPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const OwnerWalletTransactionsPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory OwnerWalletTransactionsPagination.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, int fallback) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return OwnerWalletTransactionsPagination(
      page: asInt(json['page'], 1),
      limit: asInt(json['limit'], 10),
      total: asInt(json['total'], 0),
      totalPages: asInt(json['totalPages'], 1),
    );
  }
}

class OwnerWalletTransactionsPageResult {
  final bool success;
  final List<OwnerWalletTransactionModel> transactions;
  final OwnerWalletTransactionsPagination pagination;
  final String? message;

  const OwnerWalletTransactionsPageResult({
    required this.success,
    required this.transactions,
    required this.pagination,
    required this.message,
  });

  factory OwnerWalletTransactionsPageResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};

    final rawTransactions = data['transactions'];
    final rawPagination = data['pagination'];

    final transactions = rawTransactions is List
        ? rawTransactions
              .whereType<Map>()
              .map(
                (e) => OwnerWalletTransactionModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : <OwnerWalletTransactionModel>[];

    final pagination = rawPagination is Map
        ? OwnerWalletTransactionsPagination.fromJson(
            Map<String, dynamic>.from(rawPagination),
          )
        : const OwnerWalletTransactionsPagination(
            page: 1,
            limit: 10,
            total: 0,
            totalPages: 1,
          );

    String? resolvedMessage;
    final rawMessage = json['message'];
    if (rawMessage is Map) {
      final ar = rawMessage['ar']?.toString().trim();
      final en = rawMessage['en']?.toString().trim();
      resolvedMessage = (ar != null && ar.isNotEmpty)
          ? ar
          : ((en != null && en.isNotEmpty) ? en : null);
    } else {
      final text = rawMessage?.toString().trim();
      if (text != null && text.isNotEmpty) {
        resolvedMessage = text;
      }
    }

    return OwnerWalletTransactionsPageResult(
      success: json['success'] == true,
      transactions: transactions,
      pagination: pagination,
      message: resolvedMessage,
    );
  }
}

class OwnerWithdrawalBankDetails {
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankCode;
  final String? accountHolderName;
  final String? iban;
  final String? swiftCode;

  const OwnerWithdrawalBankDetails({
    this.bankAccountNumber,
    this.bankName,
    this.bankCode,
    this.accountHolderName,
    this.iban,
    this.swiftCode,
  });

  Map<String, dynamic> toJson() {
    return {
      if (bankAccountNumber != null && bankAccountNumber!.trim().isNotEmpty)
        'bankAccountNumber': bankAccountNumber!.trim(),
      if (bankName != null && bankName!.trim().isNotEmpty)
        'bankName': bankName!.trim(),
      if (bankCode != null && bankCode!.trim().isNotEmpty)
        'bankCode': bankCode!.trim(),
      if (accountHolderName != null && accountHolderName!.trim().isNotEmpty)
        'accountHolderName': accountHolderName!.trim(),
      if (iban != null && iban!.trim().isNotEmpty) 'iban': iban!.trim(),
      if (swiftCode != null && swiftCode!.trim().isNotEmpty)
        'swiftCode': swiftCode!.trim(),
    };
  }
}

class OwnerWithdrawalMobileWalletDetails {
  final String phoneNumber;
  final String? walletProvider;
  final String? name;

  const OwnerWithdrawalMobileWalletDetails({
    required this.phoneNumber,
    this.walletProvider,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber.trim(),
      if (walletProvider != null && walletProvider!.trim().isNotEmpty)
        'walletProvider': walletProvider!.trim(),
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
    };
  }
}

class OwnerCreateWithdrawalRequest {
  final double amount;
  final String paymentMethod;
  final String accountDetails;
  final String? gateway;
  final OwnerWithdrawalBankDetails? bankDetails;
  final OwnerWithdrawalMobileWalletDetails? mobileWalletDetails;

  const OwnerCreateWithdrawalRequest({
    required this.amount,
    required this.paymentMethod,
    required this.accountDetails,
    this.gateway,
    this.bankDetails,
    this.mobileWalletDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentMethod': paymentMethod,
      'accountDetails': accountDetails,
      if (gateway != null && gateway!.trim().isNotEmpty) 'gateway': gateway!.trim(),
      if (bankDetails != null) 'bankDetails': bankDetails!.toJson(),
      if (mobileWalletDetails != null)
        'mobileWalletDetails': mobileWalletDetails!.toJson(),
    };
  }
}

class OwnerWithdrawalRequestModel {
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
  final double? balanceBefore;
  final double? balanceAfter;

  const OwnerWithdrawalRequestModel({
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
    required this.balanceBefore,
    required this.balanceAfter,
  });

  bool get isPending => status.trim().toUpperCase() == 'PENDING';
  bool get isApproved => status.trim().toUpperCase() == 'APPROVED';
  bool get isRejected => status.trim().toUpperCase() == 'REJECTED';

  factory OwnerWithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    double? asNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

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

    return OwnerWithdrawalRequestModel(
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
      balanceBefore: asNullableDouble(json['balanceBefore']),
      balanceAfter: asNullableDouble(json['balanceAfter']),
    );
  }
}

class OwnerWithdrawalRequestsPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const OwnerWithdrawalRequestsPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory OwnerWithdrawalRequestsPagination.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, int fallback) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return OwnerWithdrawalRequestsPagination(
      page: asInt(json['page'], 1),
      limit: asInt(json['limit'], 10),
      total: asInt(json['total'], 0),
      totalPages: asInt(json['totalPages'], 1),
    );
  }
}

class OwnerWithdrawalRequestsPageResult {
  final bool success;
  final List<OwnerWithdrawalRequestModel> requests;
  final OwnerWithdrawalRequestsPagination pagination;
  final String? message;

  const OwnerWithdrawalRequestsPageResult({
    required this.success,
    required this.requests,
    required this.pagination,
    required this.message,
  });

  factory OwnerWithdrawalRequestsPageResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};

    final rawRequests = data['requests'];
    final rawPagination = data['pagination'];

    final requests = rawRequests is List
        ? rawRequests
              .whereType<Map>()
              .map(
                (e) => OwnerWithdrawalRequestModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : <OwnerWithdrawalRequestModel>[];

    final pagination = rawPagination is Map
        ? OwnerWithdrawalRequestsPagination.fromJson(
            Map<String, dynamic>.from(rawPagination),
          )
        : const OwnerWithdrawalRequestsPagination(
            page: 1,
            limit: 10,
            total: 0,
            totalPages: 1,
          );

    String? resolvedMessage;
    final rawMessage = json['message'];
    if (rawMessage is Map) {
      final ar = rawMessage['ar']?.toString().trim();
      final en = rawMessage['en']?.toString().trim();
      resolvedMessage = (ar != null && ar.isNotEmpty)
          ? ar
          : ((en != null && en.isNotEmpty) ? en : null);
    } else {
      final text = rawMessage?.toString().trim();
      if (text != null && text.isNotEmpty) {
        resolvedMessage = text;
      }
    }

    return OwnerWithdrawalRequestsPageResult(
      success: json['success'] == true,
      requests: requests,
      pagination: pagination,
      message: resolvedMessage,
    );
  }
}

class OwnerCreateWithdrawalResponse {
  final bool success;
  final OwnerWithdrawalRequestModel request;
  final String? message;

  const OwnerCreateWithdrawalResponse({
    required this.success,
    required this.request,
    required this.message,
  });

  factory OwnerCreateWithdrawalResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};

    String? resolvedMessage;
    final rawMessage = json['message'];
    if (rawMessage is Map) {
      final ar = rawMessage['ar']?.toString().trim();
      final en = rawMessage['en']?.toString().trim();
      resolvedMessage = (ar != null && ar.isNotEmpty)
          ? ar
          : ((en != null && en.isNotEmpty) ? en : null);
    } else {
      final text = rawMessage?.toString().trim();
      if (text != null && text.isNotEmpty) {
        resolvedMessage = text;
      }
    }

    return OwnerCreateWithdrawalResponse(
      success: json['success'] == true,
      request: OwnerWithdrawalRequestModel.fromJson(data),
      message: resolvedMessage,
    );
  }
}

class OwnerWithdrawalStatusResult {
  final bool success;
  final String payoutId;
  final String status;
  final double amount;
  final String currency;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? failureReason;

  const OwnerWithdrawalStatusResult({
    required this.success,
    required this.payoutId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.completedAt,
    required this.failureReason,
  });

  bool get isPending => status == 'PENDING';
  bool get isSuccess => status == 'SUCCESS';
  bool get isFailed => status == 'FAILED';
  bool get isCancelled => status == 'CANCELLED';

  factory OwnerWithdrawalStatusResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};

    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return OwnerWithdrawalStatusResult(
      success: json['success'] == true,
      payoutId: (data['payoutId'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      amount: asDouble(data['amount']),
      currency: (data['currency'] ?? 'EGP').toString(),
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(data['completedAt']?.toString() ?? ''),
      failureReason: data['failureReason']?.toString(),
    );
  }
}
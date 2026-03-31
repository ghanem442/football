class AdminBookingModel {
  final String id;
  final String? bookingCode;

  final String status;
  final String? paymentStatus;

  final String? playerId;
  final String? playerName;
  final String? playerEmail;
  final String? playerPhone;

  final String? fieldId;
  final String? fieldName;
  final String? fieldAddress;

  final String? ownerId;
  final String? ownerName;
  final String? ownerEmail;

  final DateTime? scheduledDate;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;

  final double? totalPrice;
  final double? depositAmount;
  final double? remainingAmount;
  final double? commissionAmount;
  final double? commissionRate;
  final double? ownerRevenue;
  final double? refundAmount;

  final bool isCheckedIn;
  final DateTime? checkedInAt;

  final bool hasQr;
  final String? qrToken;
  final bool qrUsed;
  final DateTime? qrUsedAt;

  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminBookingModel({
    required this.id,
    required this.bookingCode,
    required this.status,
    required this.paymentStatus,
    required this.playerId,
    required this.playerName,
    required this.playerEmail,
    required this.playerPhone,
    required this.fieldId,
    required this.fieldName,
    required this.fieldAddress,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.scheduledDate,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.totalPrice,
    required this.depositAmount,
    required this.remainingAmount,
    required this.commissionAmount,
    required this.commissionRate,
    required this.ownerRevenue,
    required this.refundAmount,
    required this.isCheckedIn,
    required this.checkedInAt,
    required this.hasQr,
    required this.qrToken,
    required this.qrUsed,
    required this.qrUsedAt,
    required this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminBookingModel.fromJson(Map<String, dynamic> json) {
    final player = json['player'] is Map
        ? Map<String, dynamic>.from(json['player'] as Map)
        : <String, dynamic>{};

    final field = json['field'] is Map
        ? Map<String, dynamic>.from(json['field'] as Map)
        : <String, dynamic>{};

    final owner = json['owner'] is Map
        ? Map<String, dynamic>.from(json['owner'] as Map)
        : <String, dynamic>{};

    final scheduledDate = _parseDate(json['date']);
    final scheduledStart = _combineDateAndTime(json['date'], json['startTime']);
    var scheduledEnd = _combineDateAndTime(json['date'], json['endTime']);

    if (scheduledStart != null &&
        scheduledEnd != null &&
        !scheduledEnd.isAfter(scheduledStart)) {
      scheduledEnd = scheduledEnd.add(const Duration(days: 1));
    }

    return AdminBookingModel(
      id: (json['id'] ?? '').toString(),
      bookingCode: json['bookingCode']?.toString(),
      status: (json['status'] ?? '').toString(),
      paymentStatus: json['paymentStatus']?.toString(),

      playerId: player['id']?.toString(),
      playerName: player['name']?.toString(),
      playerEmail: player['email']?.toString(),
      playerPhone: player['phone']?.toString(),

      fieldId: field['id']?.toString(),
      fieldName: field['name']?.toString(),
      fieldAddress: field['address']?.toString(),

      ownerId: owner['id']?.toString(),
      ownerName: owner['name']?.toString(),
      ownerEmail: owner['email']?.toString(),

      scheduledDate: scheduledDate,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,

      totalPrice: _toDoubleOrNull(json['totalPrice']),
      depositAmount: _toDoubleOrNull(json['depositAmount']),
      remainingAmount: _toDoubleOrNull(json['remainingAmount']),
      commissionAmount: _toDoubleOrNull(json['commissionAmount']),
      commissionRate: _toDoubleOrNull(json['commissionRate']),
      ownerRevenue: _toDoubleOrNull(json['ownerRevenue']),
      refundAmount: _toDoubleOrNull(json['refundAmount']),

      isCheckedIn: json['isCheckedIn'] == true,
      checkedInAt: _parseDate(json['checkedInAt']),

      hasQr: json['hasQr'] == true,
      qrToken: json['qrToken']?.toString(),
      qrUsed: json['qrUsed'] == true,
      qrUsedAt: _parseDate(json['qrUsedAt']),

      cancelledAt: _parseDate(json['cancelledAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _combineDateAndTime(dynamic dateValue, dynamic timeValue) {
    final date = _parseDate(dateValue);
    if (date == null) return null;
    if (timeValue == null) return date;

    final raw = timeValue.toString().trim();
    if (raw.isEmpty) return date;

    final fullDateTime = DateTime.tryParse(raw);
    if (fullDateTime != null) return fullDateTime.toLocal();

    final normalized = raw.replaceAll('.', ':');
    final parts = normalized.split(':');
    if (parts.length < 2) return date;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final second = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
      second,
    ).toLocal();
  }
}
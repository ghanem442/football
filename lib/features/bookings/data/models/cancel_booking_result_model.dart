class CancelBookingMessageModel {
  final String? en;
  final String? ar;

  const CancelBookingMessageModel({
    required this.en,
    required this.ar,
  });

  factory CancelBookingMessageModel.fromJson(dynamic json) {
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      return CancelBookingMessageModel(
        en: map['en']?.toString(),
        ar: map['ar']?.toString(),
      );
    }

    if (json is String) {
      return CancelBookingMessageModel(
        en: json,
        ar: json,
      );
    }

    return const CancelBookingMessageModel(
      en: null,
      ar: null,
    );
  }
}

class CancelBookingRefundModel {
  final double amount;
  final num percentage;

  const CancelBookingRefundModel({
    required this.amount,
    required this.percentage,
  });

  factory CancelBookingRefundModel.fromJson(dynamic json) {
    if (json is! Map) {
      return const CancelBookingRefundModel(
        amount: 0,
        percentage: 0,
      );
    }

    final map = Map<String, dynamic>.from(json);

    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    num asNum(dynamic value) {
      if (value is num) return value;
      return num.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CancelBookingRefundModel(
      amount: asDouble(map['amount']),
      percentage: asNum(map['percentage']),
    );
  }
}

class CancelBookingResultBookingModel {
  final String id;
  final String status;

  const CancelBookingResultBookingModel({
    required this.id,
    required this.status,
  });

  factory CancelBookingResultBookingModel.fromJson(dynamic json) {
    if (json is! Map) {
      return const CancelBookingResultBookingModel(
        id: '',
        status: '',
      );
    }

    final map = Map<String, dynamic>.from(json);

    return CancelBookingResultBookingModel(
      id: (map['id'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
    );
  }
}

class CancelBookingResultDataModel {
  final CancelBookingResultBookingModel booking;
  final CancelBookingRefundModel refund;

  const CancelBookingResultDataModel({
    required this.booking,
    required this.refund,
  });

  factory CancelBookingResultDataModel.fromJson(dynamic json) {
    if (json is! Map) {
      return const CancelBookingResultDataModel(
        booking: CancelBookingResultBookingModel(id: '', status: ''),
        refund: CancelBookingRefundModel(amount: 0, percentage: 0),
      );
    }

    final map = Map<String, dynamic>.from(json);

    return CancelBookingResultDataModel(
      booking: CancelBookingResultBookingModel.fromJson(map['booking']),
      refund: CancelBookingRefundModel.fromJson(map['refund']),
    );
  }
}

class CancelBookingResultModel {
  final CancelBookingResultDataModel data;
  final CancelBookingMessageModel message;

  const CancelBookingResultModel({
    required this.data,
    required this.message,
  });

  CancelBookingRefundModel get refund => data.refund;

  String? get messageEn => message.en;
  String? get messageAr => message.ar;

  factory CancelBookingResultModel.fromJson(Map<String, dynamic> json) {
    return CancelBookingResultModel(
      data: CancelBookingResultDataModel.fromJson(json['data']),
      message: CancelBookingMessageModel.fromJson(json['message']),
    );
  }
}
class AdminSystemSettingsModel {
  final double globalCommissionPercentage;
  final double depositPercentage;
  final int cancellationRefundWindowHours;

  const AdminSystemSettingsModel({
    required this.globalCommissionPercentage,
    required this.depositPercentage,
    required this.cancellationRefundWindowHours,
  });

  factory AdminSystemSettingsModel.fromJson(Map<String, dynamic> json) {
    return AdminSystemSettingsModel(
      globalCommissionPercentage: _toDouble(json['globalCommissionPercentage']) ?? 0,
      depositPercentage: _toDouble(json['depositPercentage']) ?? 0,
      cancellationRefundWindowHours:
          _toInt(json['cancellationRefundWindowHours']) ?? 0,
    );
  }

  AdminSystemSettingsModel copyWith({
    double? globalCommissionPercentage,
    double? depositPercentage,
    int? cancellationRefundWindowHours,
  }) {
    return AdminSystemSettingsModel(
      globalCommissionPercentage:
          globalCommissionPercentage ?? this.globalCommissionPercentage,
      depositPercentage: depositPercentage ?? this.depositPercentage,
      cancellationRefundWindowHours: cancellationRefundWindowHours ??
          this.cancellationRefundWindowHours,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
class AdminDashboardModel {
  final int activeBookings;
  final int pendingPayments;
  final int totalUsers;
  final int totalFields;
  final int totalBookings;
  final double todayRevenue;
  final double todayCommission;

  const AdminDashboardModel({
    required this.activeBookings,
    required this.pendingPayments,
    required this.totalUsers,
    required this.totalFields,
    required this.totalBookings,
    required this.todayRevenue,
    required this.todayCommission,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      activeBookings: _toInt(json['activeBookings']) ?? 0,
      pendingPayments: _toInt(json['pendingPayments']) ?? 0,
      totalUsers: _toInt(json['totalUsers']) ?? 0,
      totalFields: _toInt(json['totalFields']) ?? 0,
      totalBookings: _toInt(json['totalBookings']) ?? 0,
      todayRevenue: _toDouble(json['todayRevenue']) ?? 0,
      todayCommission: _toDouble(json['todayCommission']) ?? 0,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
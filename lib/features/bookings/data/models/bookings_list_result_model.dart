import 'booking_model.dart';

class BookingsListResult {
  final List<BookingModel> bookings;
  final PaginationModel pagination;

  const BookingsListResult({
    required this.bookings,
    required this.pagination,
  });

  factory BookingsListResult.fromJson(Map<String, dynamic> json) {
    final root = Map<String, dynamic>.from(json);
    final data = (root['data'] is Map)
        ? Map<String, dynamic>.from(root['data'] as Map)
        : <String, dynamic>{};

    final rawList = (data['bookings'] as List?) ?? const [];
    final rawPag = (data['pagination'] is Map)
        ? Map<String, dynamic>.from(data['pagination'] as Map)
        : <String, dynamic>{};

    final list = rawList
        .whereType<Map>()
        .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return BookingsListResult(
      bookings: list,
      pagination: PaginationModel.fromJson(rawPag),
    );
  }
}

class PaginationModel {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginationModel({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;

    return PaginationModel(
      total: asInt(json['total']),
      page: asInt(json['page']),
      limit: asInt(json['limit']),
      totalPages: asInt(json['totalPages']),
    );
  }
}
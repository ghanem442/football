import 'package:football/features/fields/data/models/field_model.dart';

class OwnerFieldsMetaModel {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const OwnerFieldsMetaModel({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory OwnerFieldsMetaModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;

    return OwnerFieldsMetaModel(
      total: asInt(json['total']),
      page: asInt(json['page']),
      limit: asInt(json['limit']),
      totalPages: asInt(json['totalPages']),
    );
  }
}

class OwnerFieldsResponseModel {
  final bool success;
  final List<FieldModel> data;
  final OwnerFieldsMetaModel meta;

  const OwnerFieldsResponseModel({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory OwnerFieldsResponseModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List? ?? [];
    final rawMeta = json['meta'];

    return OwnerFieldsResponseModel(
      success: json['success'] == true,
      data: rawList
          .whereType<Map>()
          .map((e) => FieldModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      meta: rawMeta is Map
          ? OwnerFieldsMetaModel.fromJson(Map<String, dynamic>.from(rawMeta))
          : const OwnerFieldsMetaModel(
              total: 0,
              page: 1,
              limit: 10,
              totalPages: 0,
            ),
    );
  }
}
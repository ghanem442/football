import 'package:freezed_annotation/freezed_annotation.dart';

import 'pagination_meta.dart';

export 'pagination_meta.dart';

part 'paginated_response.freezed.dart';
part 'paginated_response.g.dart';

@freezed
class BilingualMessage with _$BilingualMessage {
  const factory BilingualMessage({
    required String en,
    required String ar,
  }) = _BilingualMessage;

  /// ✅ يدوي (بدون _$BilingualMessageFromJson)
  factory BilingualMessage.fromJson(Map<String, dynamic> json) {
    return BilingualMessage(
      en: (json['en'] ?? '').toString(),
      ar: (json['ar'] ?? json['en'] ?? '').toString(),
    );
  }
}

/// ✅ Converter: يقبل String أو Map
class BilingualMessageConverter
    implements JsonConverter<BilingualMessage, Object?> {
  const BilingualMessageConverter();

  @override
  BilingualMessage fromJson(Object? json) {
    if (json is String) {
      return BilingualMessage(en: json, ar: json);
    }
    if (json is Map<String, dynamic>) {
      return BilingualMessage.fromJson(json);
    }
    if (json is Map) {
      final map = json.map((k, v) => MapEntry(k.toString(), v));
      return BilingualMessage.fromJson(map);
    }
    return const BilingualMessage(en: '', ar: '');
  }

  @override
  Object? toJson(BilingualMessage object) => {
        'en': object.en,
        'ar': object.ar,
      };
}

@Freezed(genericArgumentFactories: true)
class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    required bool success,
    required List<T> data,
    required PaginationMeta meta,
    @BilingualMessageConverter() required BilingualMessage message,
    required String timestamp,
  }) = _PaginatedResponse<T>;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);
}
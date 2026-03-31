import 'bilingual_message.dart';
import 'pagination_meta.dart';

class FieldsResponse<T> {
  final bool success;
  final List<T> data; // ✅ list مباشرة
  final PaginationMeta meta;
  final BilingualMessage message;
  final String timestamp;

  const FieldsResponse({
    required this.success,
    required this.data,
    required this.meta,
    required this.message,
    required this.timestamp,
  });
}
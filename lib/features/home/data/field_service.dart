import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_provider.dart';

final fieldServiceProvider = Provider<FieldService>((ref) {
  final api = ref.read(apiClientProvider);
  return FieldService(api);
});

class FieldService {
  final dynamic api;

  FieldService(this.api);

  Future<dynamic> getFields() async {
    final response = await api.get(
      '/fields',
      queryParameters: {
        'page': 1,
        'limit': 10,
      },
    );

    return response.data;
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/api_client.dart';
import 'api_config.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: ApiConfig.baseUrl,
  );
});
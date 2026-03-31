import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';

import '../repositories/admin_fields_repository.dart';

final adminFieldsRepositoryProvider = Provider<AdminFieldsRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return AdminFieldsRepository(api);
});
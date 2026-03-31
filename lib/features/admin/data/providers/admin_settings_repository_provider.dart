import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';

import '../repositories/admin_settings_repository.dart';

final adminSettingsRepositoryProvider = Provider<AdminSettingsRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return AdminSettingsRepository(api);
});
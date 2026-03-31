import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';

import '../repositories/admin_dashboard_repository.dart';

final adminDashboardRepositoryProvider =
    Provider<AdminDashboardRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return AdminDashboardRepository(api);
});
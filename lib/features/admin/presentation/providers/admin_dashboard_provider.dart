import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_dashboard_model.dart';
import '../../data/providers/admin_dashboard_repository_provider.dart';

final adminDashboardProvider =
    FutureProvider<AdminDashboardModel>((ref) async {
  final repo = ref.read(adminDashboardRepositoryProvider);
  return repo.getDashboard();
});
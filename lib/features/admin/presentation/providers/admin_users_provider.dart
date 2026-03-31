import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';

import '../../data/models/admin_user_model.dart';
import '../../data/repositories/admin_users_repository.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return AdminUsersRepository(api);
});

final adminUsersProvider = FutureProvider<List<AdminUserModel>>((ref) async {
  final repo = ref.read(adminUsersRepositoryProvider);
  return repo.getUsers();
});
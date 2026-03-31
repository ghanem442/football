import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';

import '../../data/auth_repository.dart';
import '../controllers/login_controller.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthRepository(api);
});

final loginControllerProvider =
    AsyncNotifierProvider<LoginController, void>(LoginController.new);
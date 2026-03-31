import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';

import '../repositories/admin_platform_wallet_repository.dart';

final adminPlatformWalletRepositoryProvider =
    Provider<AdminPlatformWalletRepository>((ref) {
      final api = ref.read(apiClientProvider);
      return AdminPlatformWalletRepository(api);
    });
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';

import '../repositories/admin_wallet_repository.dart';

final adminWalletRepositoryProvider = Provider<AdminWalletRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return AdminWalletRepository(api);
});
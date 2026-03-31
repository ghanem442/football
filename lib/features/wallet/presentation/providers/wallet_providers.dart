import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';

import '../../data/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return WalletRepository(api);
});

class WalletUiState {
  final WalletModel wallet;
  final List<WalletTransactionModel> transactions;
  final WalletPaginationModel pagination;
  final String? selectedType;

  const WalletUiState({
    required this.wallet,
    required this.transactions,
    required this.pagination,
    required this.selectedType,
  });

  double get balance => wallet.balanceAsDouble;

  List<WalletTransactionModel> get allTransactions {
    final list = [...transactions];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  double get totalIncoming {
    return allTransactions
        .where((e) => e.isIncoming)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalOutgoing {
    return allTransactions
        .where((e) => e.isOutgoing)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  WalletUiState copyWith({
    WalletModel? wallet,
    List<WalletTransactionModel>? transactions,
    WalletPaginationModel? pagination,
    String? selectedType,
    bool clearSelectedType = false,
  }) {
    return WalletUiState(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      pagination: pagination ?? this.pagination,
      selectedType: clearSelectedType
          ? null
          : (selectedType ?? this.selectedType),
    );
  }
}

class WalletNotifier extends AsyncNotifier<WalletUiState> {
  static const int _defaultLimit = 20;

  @override
  Future<WalletUiState> build() async {
    return _load(
      page: 1,
      limit: _defaultLimit,
      type: null,
    );
  }

  Future<WalletUiState> _load({
    required int page,
    required int limit,
    required String? type,
  }) async {
    final repo = ref.read(walletRepositoryProvider);

    final wallet = await repo.getWallet();
    final txRes = await repo.getTransactions(
      page: page,
      limit: limit,
      type: type,
    );

    return WalletUiState(
      wallet: wallet,
      transactions: txRes.transactions,
      pagination: txRes.pagination,
      selectedType: type,
    );
  }

  Future<void> refreshWallet() async {
    final currentType = state.valueOrNull?.selectedType;

    state = const AsyncLoading<WalletUiState>();

    try {
      final data = await _load(
        page: 1,
        limit: _defaultLimit,
        type: currentType,
      );
      state = AsyncData<WalletUiState>(data);
    } catch (e, st) {
      state = AsyncError<WalletUiState>(e, st);
    }
  }

  Future<void> setTypeFilter(String? type) async {
    state = const AsyncLoading<WalletUiState>();

    try {
      final data = await _load(
        page: 1,
        limit: _defaultLimit,
        type: type,
      );
      state = AsyncData<WalletUiState>(data);
    } catch (e, st) {
      state = AsyncError<WalletUiState>(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.pagination.hasMore) return;

    final nextPage = current.pagination.page + 1;
    final repo = ref.read(walletRepositoryProvider);

    try {
      final txRes = await repo.getTransactions(
        page: nextPage,
        limit: current.pagination.limit,
        type: current.selectedType,
      );

      final merged = <String, WalletTransactionModel>{
        for (final item in current.transactions) item.id: item,
        for (final item in txRes.transactions) item.id: item,
      }.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = AsyncData<WalletUiState>(
        current.copyWith(
          transactions: merged,
          pagination: txRes.pagination,
        ),
      );
    } catch (e, st) {
      state = AsyncError<WalletUiState>(e, st);
    }
  }

  Future<void> clearFilter() async {
    await setTypeFilter(null);
  }
}

final walletProvider = AsyncNotifierProvider<WalletNotifier, WalletUiState>(
  WalletNotifier.new,
);
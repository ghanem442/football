import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_wallet_transaction_model.dart';
import '../../data/providers/admin_wallet_repository_provider.dart';

class AdminWalletState {
  final bool isLoading;
  final String? error;
  final List<AdminWalletTransactionModel> transactions;
  final String? type;
  final DateTime? startDate;
  final DateTime? endDate;

  const AdminWalletState({
    required this.isLoading,
    required this.error,
    required this.transactions,
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  factory AdminWalletState.initial() {
    return const AdminWalletState(
      isLoading: false,
      error: null,
      transactions: [],
      type: null,
      startDate: null,
      endDate: null,
    );
  }

  AdminWalletState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<AdminWalletTransactionModel>? transactions,
    String? type,
    bool clearType = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return AdminWalletState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      transactions: transactions ?? this.transactions,
      type: clearType ? null : (type ?? this.type),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  bool get hasFilters =>
      type != null || startDate != null || endDate != null;
}

class AdminWalletNotifier extends Notifier<AdminWalletState> {
  @override
  AdminWalletState build() {
    Future.microtask(loadTransactions);
    return AdminWalletState.initial();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(adminWalletRepositoryProvider);

      final transactions = await repo.getTransactions(
        type: state.type,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      state = state.copyWith(
        isLoading: false,
        transactions: transactions,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> setType(String? value) async {
    state = value == null
        ? state.copyWith(clearType: true)
        : state.copyWith(type: value);
    await loadTransactions();
  }

  Future<void> setDateRange({
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
    );
    await loadTransactions();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      clearType: true,
      clearStartDate: true,
      clearEndDate: true,
    );
    await loadTransactions();
  }

  Future<void> refresh() async {
    await loadTransactions();
  }
}

final adminWalletProvider =
    NotifierProvider<AdminWalletNotifier, AdminWalletState>(
  AdminWalletNotifier.new,
);
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';
import 'package:football/features/admin/data/models/admin_withdrawal_request_model.dart';
import 'package:football/features/admin/data/repositories/admin_withdrawal_requests_repository.dart';

final adminWithdrawalRequestsRepositoryProvider =
    Provider<AdminWithdrawalRequestsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AdminWithdrawalRequestsRepository(api);
});

class AdminWithdrawalRequestsState {
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final List<AdminWithdrawalRequestModel> requests;
  final String? status;

  const AdminWithdrawalRequestsState({
    required this.isLoading,
    required this.isProcessing,
    required this.error,
    required this.requests,
    required this.status,
  });

  factory AdminWithdrawalRequestsState.initial() {
    return const AdminWithdrawalRequestsState(
      isLoading: false,
      isProcessing: false,
      error: null,
      requests: [],
      status: null,
    );
  }

  AdminWithdrawalRequestsState copyWith({
    bool? isLoading,
    bool? isProcessing,
    String? error,
    bool clearError = false,
    List<AdminWithdrawalRequestModel>? requests,
    String? status,
    bool clearStatus = false,
  }) {
    return AdminWithdrawalRequestsState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      requests: requests ?? this.requests,
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  bool get hasFilters => status != null;
}

class AdminWithdrawalRequestsNotifier
    extends Notifier<AdminWithdrawalRequestsState> {
  @override
  AdminWithdrawalRequestsState build() {
    Future.microtask(loadRequests);
    return AdminWithdrawalRequestsState.initial();
  }

  Future<void> loadRequests() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(adminWithdrawalRequestsRepositoryProvider);

      final requests = await repo.getRequests(
        status: state.status,
      );

      state = state.copyWith(
        isLoading: false,
        requests: requests,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> setStatus(String? value) async {
    state = value == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(status: value);
    await loadRequests();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      clearStatus: true,
    );
    await loadRequests();
  }

  Future<void> refresh() async {
    await loadRequests();
  }

  Future<void> approveRequest(String id) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final repo = ref.read(adminWithdrawalRequestsRepositoryProvider);
      final updated = await repo.approveRequest(id);

      final next = state.requests
          .map((e) => e.id == updated.id ? updated : e)
          .toList();

      state = state.copyWith(
        isProcessing: false,
        requests: next,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> rejectRequest({
    required String id,
    required String reason,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final repo = ref.read(adminWithdrawalRequestsRepositoryProvider);
      final updated = await repo.rejectRequest(
        id: id,
        reason: reason,
      );

      final next = state.requests
          .map((e) => e.id == updated.id ? updated : e)
          .toList();

      state = state.copyWith(
        isProcessing: false,
        requests: next,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }
}

final adminWithdrawalRequestsProvider = NotifierProvider<
  AdminWithdrawalRequestsNotifier,
  AdminWithdrawalRequestsState
>(
  AdminWithdrawalRequestsNotifier.new,
);
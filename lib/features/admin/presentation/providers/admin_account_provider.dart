import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';
import 'package:football/features/admin/data/repositories/admin_account_repository.dart';
import 'package:football/features/auth/presentation/providers/auth_session_provider.dart';

final adminAccountRepositoryProvider = Provider<AdminAccountRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AdminAccountRepository(api);
});

class AdminAccountState {
  final bool isUpdatingProfile;
  final bool isChangingPassword;
  final String? error;

  const AdminAccountState({
    required this.isUpdatingProfile,
    required this.isChangingPassword,
    required this.error,
  });

  factory AdminAccountState.initial() {
    return const AdminAccountState(
      isUpdatingProfile: false,
      isChangingPassword: false,
      error: null,
    );
  }

  AdminAccountState copyWith({
    bool? isUpdatingProfile,
    bool? isChangingPassword,
    String? error,
    bool clearError = false,
  }) {
    return AdminAccountState(
      isUpdatingProfile: isUpdatingProfile ?? this.isUpdatingProfile,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminAccountNotifier extends Notifier<AdminAccountState> {
  @override
  AdminAccountState build() {
    return AdminAccountState.initial();
  }

  Future<void> updateProfile({
    String? email,
    String? name,
  }) async {
    state = state.copyWith(
      isUpdatingProfile: true,
      clearError: true,
    );

    try {
      final repo = ref.read(adminAccountRepositoryProvider);

      final result = await repo.updateProfile(
        email: email,
        name: name,
      );

      ref.read(authSessionProvider.notifier).saveUser(
            email: result.email,
            isVerified: result.isVerified,
            name: result.name,
            role: result.role,
            id: result.id,
          );

      state = state.copyWith(
        isUpdatingProfile: false,
      );
    } catch (e) {
      state = state.copyWith(
        isUpdatingProfile: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isChangingPassword: true,
      clearError: true,
    );

    try {
      final repo = ref.read(adminAccountRepositoryProvider);

      final message = await repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      state = state.copyWith(
        isChangingPassword: false,
      );

      return message;
    } catch (e) {
      state = state.copyWith(
        isChangingPassword: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }
}

final adminAccountProvider =
    NotifierProvider<AdminAccountNotifier, AdminAccountState>(
  AdminAccountNotifier.new,
);
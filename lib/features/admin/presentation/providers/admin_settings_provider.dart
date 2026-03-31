import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_system_settings_model.dart';
import '../../data/providers/admin_settings_repository_provider.dart';

class AdminSettingsState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final AdminSystemSettingsModel? settings;

  const AdminSettingsState({
    required this.isLoading,
    required this.isSaving,
    required this.error,
    required this.settings,
  });

  factory AdminSettingsState.initial() {
    return const AdminSettingsState(
      isLoading: false,
      isSaving: false,
      error: null,
      settings: null,
    );
  }

  AdminSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    AdminSystemSettingsModel? settings,
  }) {
    return AdminSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      settings: settings ?? this.settings,
    );
  }
}

class AdminSettingsNotifier extends Notifier<AdminSettingsState> {
  @override
  AdminSettingsState build() {
    Future.microtask(loadSettings);
    return AdminSettingsState.initial();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(adminSettingsRepositoryProvider);
      final settings = await repo.getSettings();

      state = state.copyWith(
        isLoading: false,
        settings: settings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> saveSettings({
    required double globalCommissionPercentage,
    required double depositPercentage,
    required int cancellationRefundWindowHours,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final repo = ref.read(adminSettingsRepositoryProvider);

      await repo.updateSettings(
        globalCommissionPercentage: globalCommissionPercentage,
        depositPercentage: depositPercentage,
        cancellationRefundWindowHours: cancellationRefundWindowHours,
      );

      final updated = AdminSystemSettingsModel(
        globalCommissionPercentage: globalCommissionPercentage,
        depositPercentage: depositPercentage,
        cancellationRefundWindowHours: cancellationRefundWindowHours,
      );

      state = state.copyWith(
        isSaving: false,
        settings: updated,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadSettings();
  }
}

final adminSettingsProvider =
    NotifierProvider<AdminSettingsNotifier, AdminSettingsState>(
  AdminSettingsNotifier.new,
);
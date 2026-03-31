import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_field_model.dart';
import '../../data/providers/admin_fields_repository_provider.dart';

class AdminFieldsState {
  final bool isLoading;
  final String? error;
  final List<AdminFieldModel> fields;
  final String search;
  final String? status;

  const AdminFieldsState({
    required this.isLoading,
    required this.error,
    required this.fields,
    required this.search,
    required this.status,
  });

  factory AdminFieldsState.initial() {
    return const AdminFieldsState(
      isLoading: false,
      error: null,
      fields: [],
      search: '',
      status: null,
    );
  }

  AdminFieldsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<AdminFieldModel>? fields,
    String? search,
    String? status,
    bool clearStatus = false,
  }) {
    return AdminFieldsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      fields: fields ?? this.fields,
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

class AdminFieldsNotifier extends Notifier<AdminFieldsState> {
  @override
  AdminFieldsState build() {
    Future.microtask(loadFields);
    return AdminFieldsState.initial();
  }

  Future<void> loadFields() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(adminFieldsRepositoryProvider);
      final fields = await repo.getFields(
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        status: state.status,
      );

      state = state.copyWith(
        isLoading: false,
        fields: fields,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
  }

  Future<void> applySearch(String value) async {
    state = state.copyWith(search: value);
    await loadFields();
  }

  Future<void> setStatus(String? value) async {
    state = value == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(status: value);
    await loadFields();
  }

  Future<void> refresh() async {
    await loadFields();
  }
}

final adminFieldsProvider =
    NotifierProvider<AdminFieldsNotifier, AdminFieldsState>(
  AdminFieldsNotifier.new,
);
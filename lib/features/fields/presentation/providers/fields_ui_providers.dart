import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/field_model.dart';
import '../providers/fields_providers.dart';

/// UI controls
final fieldsPageProvider = StateProvider<int>((ref) => 1);
final fieldsLimitProvider = StateProvider<int>((ref) => 20);

/// Pagination controller: holds the accumulated list and supports loadMore.
final fieldsPaginationControllerProvider =
    AsyncNotifierProvider<FieldsPaginationController, List<FieldModel>>(
  FieldsPaginationController.new,
);

/// If you want a simple provider that the UI reads as "the list":
final fieldsPaginatedProvider = Provider<AsyncValue<List<FieldModel>>>(
  (ref) => ref.watch(fieldsPaginationControllerProvider),
);

class FieldsPaginationController extends AsyncNotifier<List<FieldModel>> {
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<FieldModel>> build() async {
    // When limit changes, this notifier rebuilds and fetches first page again.
    final limit = ref.watch(fieldsLimitProvider);

    // Keep page state in sync with UI provider
    ref.read(fieldsPageProvider.notifier).state = 1;

    return _fetchPage(
      page: 1,
      limit: limit,
      reset: true,
    );
  }

  Future<void> refreshFirstPage() async {
    final limit = ref.read(fieldsLimitProvider);
    ref.read(fieldsPageProvider.notifier).state = 1;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _fetchPage(page: 1, limit: limit, reset: true);
    });
  }

  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    if (!_hasMore) return;

    final repo = ref.read(fieldsRepositoryProvider);
    final limit = ref.read(fieldsLimitProvider);

    final current = state.value ?? <FieldModel>[];
    final currentPage = ref.read(fieldsPageProvider);

    _isLoadingMore = true;

    try {
      final nextPage = currentPage + 1;

      final res = await repo.getFields(page: nextPage, limit: limit);
      final newItems = res.data;

      // Update hasMore based on meta if available, fallback to "newItems not empty"
      final meta = res.meta;
      _hasMore = meta.page < meta.totalPages;
    
      // update page
      ref.read(fieldsPageProvider.notifier).state = nextPage;

      // append
      state = AsyncData([...current, ...newItems]);
    } catch (e, st) {
      // keep current list, but expose error
      state = AsyncError(e, st);
      // then restore list so UI doesn't go empty (optional behavior)
      state = AsyncData(current);
      rethrow;
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<List<FieldModel>> _fetchPage({
    required int page,
    required int limit,
    required bool reset,
  }) async {
    final repo = ref.read(fieldsRepositoryProvider);
    final res = await repo.getFields(page: page, limit: limit);

    final meta = res.meta;
    _hasMore = meta.page < meta.totalPages;
  
    return reset ? res.data : [...(state.value ?? []), ...res.data];
  }
}
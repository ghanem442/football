import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/models/paginated_response.dart';
import '../../data/models/field_model.dart';
import 'fields_providers.dart';

enum FieldsBrowseMode { adminAll, ownerMine, playerNearby }

class BrowseFieldsState {
  const BrowseFieldsState({
    required this.mode,
    required this.items,
    required this.meta, // ✅ بقت required (غير nullable)
    required this.isLoadingMore,
    this.ownerId,
    this.latitude,
    this.longitude,
    this.radiusKm,
    required this.page,
    required this.limit,
  });

  final FieldsBrowseMode mode;
  final List<FieldModel> items;

  // ✅ /fields بيرجع meta دايمًا
  final PaginationMeta meta;

  final bool isLoadingMore;

  // parameters
  final String? ownerId;
  final double? latitude;
  final double? longitude;
  final int? radiusKm;

  final int page;
  final int limit;

  BrowseFieldsState copyWith({
    FieldsBrowseMode? mode,
    List<FieldModel>? items,
    PaginationMeta? meta,
    bool? isLoadingMore,
    String? ownerId,
    double? latitude,
    double? longitude,
    int? radiusKm,
    int? page,
    int? limit,
  }) {
    return BrowseFieldsState(
      mode: mode ?? this.mode,
      items: items ?? this.items,
      meta: meta ?? this.meta,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      ownerId: ownerId ?? this.ownerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  static BrowseFieldsState initialAdmin({int limit = 10}) => BrowseFieldsState(
        mode: FieldsBrowseMode.adminAll,
        items: const [],
        meta: const PaginationMeta(
          total: 0,
          page: 1,
          limit: 10,
          totalPages: 0,
        ),
        isLoadingMore: false,
        ownerId: null,
        latitude: null,
        longitude: null,
        radiusKm: null,
        page: 1,
        limit: limit,
      );
}

final browseFieldsProvider =
    AsyncNotifierProvider<BrowseFieldsController, BrowseFieldsState>(
  BrowseFieldsController.new,
);

class BrowseFieldsController extends AsyncNotifier<BrowseFieldsState> {
  @override
  Future<BrowseFieldsState> build() async {
    final repo = ref.read(fieldsRepositoryProvider);
    final init = BrowseFieldsState.initialAdmin(limit: 10);

    final resp = await repo.getFields(page: 1, limit: init.limit);
    return init.copyWith(items: resp.data, meta: resp.meta);
  }

  // Admin: /fields?page&limit
  Future<void> loadAdminAll({int limit = 10}) async {
    state = const AsyncLoading();
    final repo = ref.read(fieldsRepositoryProvider);

    final resp = await repo.getFields(page: 1, limit: limit);

    state = AsyncData(
      BrowseFieldsState.initialAdmin(limit: limit).copyWith(
        items: resp.data,
        meta: resp.meta,
      ),
    );
  }

  // Owner: /fields?ownerId=...&page&limit
  Future<void> loadOwnerMine({required String ownerId, int limit = 10}) async {
    state = const AsyncLoading();
    final repo = ref.read(fieldsRepositoryProvider);

    final resp = await repo.getFields(page: 1, limit: limit, ownerId: ownerId);

    state = AsyncData(
      BrowseFieldsState(
        mode: FieldsBrowseMode.ownerMine,
        items: resp.data,
        meta: resp.meta,
        isLoadingMore: false,
        ownerId: ownerId,
        latitude: null,
        longitude: null,
        radiusKm: null,
        page: 1,
        limit: limit,
      ),
    );
  }

  // Player: /fields/search?latitude&longitude&radiusKm (مفيش pagination)
  Future<void> loadPlayerNearby({
    required double latitude,
    required double longitude,
    int radiusKm = 5,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(fieldsRepositoryProvider);

    final resp = await repo.searchFields(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );

    // هنا مفيش meta من الباك، فنعمل meta افتراضي
    final fakeMeta = PaginationMeta(
      total: resp.data.length,
      page: 1,
      limit: resp.data.length,
      totalPages: 1,
    );

    state = AsyncData(
      BrowseFieldsState(
        mode: FieldsBrowseMode.playerNearby,
        items: resp.data,
        meta: fakeMeta,
        isLoadingMore: false,
        ownerId: null,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        page: 1,
        limit: resp.data.length,
      ),
    );
  }

  // Pagination: only for admin/owner (/fields)
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.mode == FieldsBrowseMode.playerNearby) return;
    if (current.isLoadingMore) return;

    if (current.meta.page >= current.meta.totalPages) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final repo = ref.read(fieldsRepositoryProvider);
    final nextPage = current.page + 1;

    final resp = await repo.getFields(
      page: nextPage,
      limit: current.limit,
      ownerId:
          current.mode == FieldsBrowseMode.ownerMine ? current.ownerId : null,
    );

    final merged = [...current.items, ...resp.data];

    state = AsyncData(
      current.copyWith(
        items: merged,
        meta: resp.meta,
        page: nextPage,
        isLoadingMore: false,
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => build());
      return;
    }

    if (current.mode == FieldsBrowseMode.playerNearby) {
      await loadPlayerNearby(
        latitude: current.latitude ?? 0,
        longitude: current.longitude ?? 0,
        radiusKm: current.radiusKm ?? 5,
      );
    } else if (current.mode == FieldsBrowseMode.ownerMine) {
      await loadOwnerMine(ownerId: current.ownerId ?? '', limit: current.limit);
    } else {
      await loadAdminAll(limit: current.limit);
    }
  }
}
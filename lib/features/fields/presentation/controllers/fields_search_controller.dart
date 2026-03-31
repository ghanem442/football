import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/field_model.dart';
import '../providers/fields_providers.dart';

class FieldsSearchController extends AsyncNotifier<List<FieldModel>> {
  @override
  Future<List<FieldModel>> build() async {
    final repo = ref.read(fieldsRepositoryProvider);
    final resp = await repo.getFields(page: 1, limit: 10);
    return resp.data;
  }

  Future<void> search({
    String? query,
    double? latitude,
    double? longitude,
    int? radiusKm,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repo = ref.read(fieldsRepositoryProvider);
      final resp = await repo.searchFields(
        query: query,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      return resp.data;
    });
  }
}

final fieldsSearchControllerProvider =
    AsyncNotifierProvider<FieldsSearchController, List<FieldModel>>(
  FieldsSearchController.new,
);
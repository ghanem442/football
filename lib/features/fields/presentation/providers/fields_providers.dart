import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';
import '../../data/fields_repository.dart';
import '../../data/models/field_model.dart';

final fieldsRepositoryProvider = Provider<FieldsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return FieldsRepository(api);
});

final fieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  final repo = ref.watch(fieldsRepositoryProvider);

  final resp = await repo.getFields(
    page: 1,
    limit: 50,
  );

  return resp.data;
});

final fieldByIdProvider =
    FutureProvider.family<FieldModel, String>((ref, fieldId) async {
  final repo = ref.watch(fieldsRepositoryProvider);
  return repo.getFieldById(fieldId);
});
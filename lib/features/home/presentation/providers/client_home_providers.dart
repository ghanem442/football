import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../fields/data/models/field_model.dart';
import '../../../fields/presentation/providers/fields_providers.dart';

class ClientHomeParams {
  final double latitude;
  final double longitude;
  final int radiusKm;

  const ClientHomeParams({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });
}

final clientHomeParamsProvider = StateProvider<ClientHomeParams>((ref) {
  // مؤقتًا (لحد ما نركب geolocator)
  return const ClientHomeParams(latitude: 30.0444, longitude: 31.2357, radiusKm: 10);
});

final clientSearchQueryProvider = StateProvider<String>((ref) => "");

final clientFieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  final repo = ref.read(fieldsRepositoryProvider);
  final p = ref.read(clientHomeParamsProvider);

  final res = await repo.searchFields(
    latitude: p.latitude,
    longitude: p.longitude,
    radiusKm: p.radiusKm,
  );

  return res.data;
});

final clientFilteredFieldsProvider = Provider<AsyncValue<List<FieldModel>>>((ref) {
  final q = ref.watch(clientSearchQueryProvider).trim().toLowerCase();
  final asyncFields = ref.watch(clientFieldsProvider);

  return asyncFields.whenData((fields) {
    if (q.isEmpty) return fields;

    return fields.where((f) {
      final name = f.name.toLowerCase();
      final address = f.address.toLowerCase();
      return name.contains(q) || address.contains(q);
    }).toList();
  });
});
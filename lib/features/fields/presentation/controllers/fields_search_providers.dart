import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fields_search_controller.dart';
import '../../data/models/field_model.dart';

final fieldsSearchControllerProvider =
    AsyncNotifierProvider<FieldsSearchController, List<FieldModel>>(
  FieldsSearchController.new,
);
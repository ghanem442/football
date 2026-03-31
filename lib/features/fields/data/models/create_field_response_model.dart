import 'package:football/core/network/models/bilingual_message.dart';
import 'package:football/features/fields/data/models/field_model.dart';

class CreateFieldResponseModel {
  final bool success;
  final FieldModel data;
  final BilingualMessage? message;
  final String? timestamp;

  const CreateFieldResponseModel({
    required this.success,
    required this.data,
    this.message,
    this.timestamp,
  });

  factory CreateFieldResponseModel.fromJson(Map<String, dynamic> json) {
    final dataNode = json['data'];
    if (dataNode is! Map) {
      throw Exception('Invalid response: data is not a field object');
    }

    final messageNode = json['message'];

    return CreateFieldResponseModel(
      success: json['success'] == true,
      data: FieldModel.fromJson(Map<String, dynamic>.from(dataNode)),
      message: messageNode is Map<String, dynamic>
          ? BilingualMessage.fromJson(messageNode)
          : (messageNode is Map
              ? BilingualMessage.fromJson(
                  Map<String, dynamic>.from(messageNode),
                )
              : null),
      timestamp: json['timestamp']?.toString(),
    );
  }
}
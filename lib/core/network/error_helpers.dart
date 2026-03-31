import 'package:dio/dio.dart';

class EmailNotVerifiedPayload {
  final String? email;
  final String? messageEn;
  final String? messageAr;
  final String? resendEndpoint;

  const EmailNotVerifiedPayload({
    this.email,
    this.messageEn,
    this.messageAr,
    this.resendEndpoint,
  });
}

EmailNotVerifiedPayload? parseEmailNotVerified(Object error) {
  if (error is! DioException) return null;

  final data = error.response?.data;
  if (data is! Map) return null;

  // backend shape:
  // {
  //  statusCode: 400,
  //  message: {
  //    code: "EMAIL_NOT_VERIFIED",
  //    message: {en, ar},
  //    resendEndpoint,
  //    email
  //  }
  // }
  final msg = data['message'];
  if (msg is! Map) return null;

  final code = msg['code']?.toString();
  if (code != 'EMAIL_NOT_VERIFIED') return null;

  final innerMsg = msg['message'];
  String? en;
  String? ar;
  if (innerMsg is Map) {
    en = innerMsg['en']?.toString();
    ar = innerMsg['ar']?.toString();
  }

  return EmailNotVerifiedPayload(
    email: msg['email']?.toString(),
    resendEndpoint: msg['resendEndpoint']?.toString(),
    messageEn: en,
    messageAr: ar,
  );
}
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

const String _hostFromEnv =
    String.fromEnvironment('API_HOST', defaultValue: '');

const int _portFromEnv =
    int.fromEnvironment('API_PORT', defaultValue: 3000);

String resolveApiBaseUrl() {
  final host = _hostFromEnv.trim().isNotEmpty ? _hostFromEnv.trim() : null;
  const port = _portFromEnv;

  if (kIsWeb) {
    return 'http://${host ?? 'localhost'}:$port/api/v1/';
  }

  if (Platform.isAndroid) {
    final effectiveHost = host ?? '10.0.2.2';
    return 'http://$effectiveHost:$port/api/v1/';
  }

  if (Platform.isIOS) {
    final effectiveHost = host ?? 'localhost';
    return 'http://$effectiveHost:$port/api/v1/';
  }

  return 'http://${host ?? 'localhost'}:$port/api/v1/';
}

String resolveApiOrigin() {
  final host = _hostFromEnv.trim().isNotEmpty ? _hostFromEnv.trim() : null;
  const port = _portFromEnv;

  if (kIsWeb) {
    return 'http://${host ?? 'localhost'}:$port';
  }

  if (Platform.isAndroid) {
    final effectiveHost = host ?? '10.0.2.2';
    return 'http://$effectiveHost:$port';
  }

  if (Platform.isIOS) {
    final effectiveHost = host ?? 'localhost';
    return 'http://$effectiveHost:$port';
  }

  return 'http://${host ?? 'localhost'}:$port';
}
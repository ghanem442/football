import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'base_url.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    Interceptor? authInterceptor,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: _normalizeBaseUrl(baseUrl ?? resolveApiBaseUrl()),
            responseType: ResponseType.json,
            validateStatus: _validateStatus,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            sendTimeout: kIsWeb ? null : const Duration(seconds: 20),
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
          ),
        ) {
    _log('API BASE URL -> ${dio.options.baseUrl}');

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _log('REQUEST -> ${options.method} ${options.uri}');
          _log('HEADERS -> ${options.headers}');
          _log('QUERY -> ${options.queryParameters}');
          _log('DATA -> ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _log(
            'RESPONSE -> ${response.statusCode} ${response.requestOptions.uri}',
          );
          _log('DATA -> ${response.data}');
          handler.next(response);
        },
        onError: (e, handler) {
          _log('ERROR -> ${e.type} | ${e.message}');
          _log('REQUEST -> ${e.requestOptions.method} ${e.requestOptions.uri}');
          _log('STATUS -> ${e.response?.statusCode}');
          _log('DATA -> ${e.response?.data}');
          handler.next(e);
        },
      ),
    );

    if (authInterceptor != null) {
      dio.interceptors.add(authInterceptor);
    }
  }

  final Dio dio;

  static String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Base URL cannot be empty');
    }
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  static bool _validateStatus(int? status) {
    return status != null && status < 600;
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  String _fixPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Request path cannot be empty');
    }
    return trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.get(
      _fixPath(path),
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.post(
      _fixPath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.put(
      _fixPath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.patch(
      _fixPath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.delete(
      _fixPath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
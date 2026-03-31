import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:football/core/network/api_client.dart';

import 'models/booking_model.dart';
import 'models/bookings_list_result_model.dart';
import 'models/cancel_booking_result_model.dart';
import 'models/payment_result_model.dart';
import 'models/time_slot_model.dart';

class BookingsRepository {
  final ApiClient api;

  BookingsRepository(this.api);

  Future<List<TimeSlotModel>> getTimeSlots({
    required String fieldId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final resolvedFieldId = fieldId.trim();

    final queryParams = <String, dynamic>{
      'fieldId': resolvedFieldId,
      'startDate': _isoDate(startDate),
      'endDate': _isoDate(endDate),
      'page': 1,
      'limit': 100,
    };

    if (kDebugMode) {
      debugPrint('================ TIME SLOTS REQUEST ================');
      debugPrint('[TIME_SLOTS] GET /time-slots');
      debugPrint('[TIME_SLOTS] query=$queryParams');
      debugPrint('[TIME_SLOTS] fieldId=$resolvedFieldId');
      debugPrint('[TIME_SLOTS] startDate=${_isoDate(startDate)}');
      debugPrint('[TIME_SLOTS] endDate=${_isoDate(endDate)}');
    }

    try {
      final res = await api.dio.get(
        'time-slots',
        queryParameters: queryParams,
      );

      final root = Map<String, dynamic>.from(res.data as Map);
      final data = root['data'];
      final list = (data is List) ? data : const [];

      if (kDebugMode) {
        debugPrint('[TIME_SLOTS] status=${res.statusCode}');
        debugPrint('[TIME_SLOTS] full response=$root');
        debugPrint('[TIME_SLOTS] data count=${list.length}');
        if (list.isEmpty) {
          debugPrint('[TIME_SLOTS] WARNING: backend returned empty slots list');
        }
        debugPrint('===================================================');
      }

      return list
          .whereType<Map>()
          .map((e) => TimeSlotModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      final message = _extractDioMessage(
        e,
        fallback: 'Failed to load time slots',
      );

      if (kDebugMode) {
        debugPrint('[TIME_SLOTS] DioException status=${e.response?.statusCode}');
        debugPrint('[TIME_SLOTS] DioException data=${e.response?.data}');
        debugPrint('[TIME_SLOTS] DioException message=$message');
      }

      throw Exception(message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TIME_SLOTS] unexpected error=$e');
      }
      throw Exception('Failed to load time slots');
    }
  }

  Future<BookingModel> createBooking({
    required String timeSlotId,
  }) async {
    final resolvedTimeSlotId = timeSlotId.trim();

    try {
      final res = await api.dio.post(
        'bookings',
        data: {'timeSlotId': resolvedTimeSlotId},
      );

      if (kDebugMode) {
        debugPrint('[CREATE_BOOKING] status=${res.statusCode}');
        debugPrint('[CREATE_BOOKING] raw response=${res.data}');
      }

      final root = _asMap(res.data);
      if (root == null) {
        throw Exception('Invalid booking response');
      }

      if (root['success'] == false) {
        final msg = _extractErrorMessage(root);

        if (kDebugMode) {
          debugPrint('[CREATE_BOOKING] backend rejected request');
          debugPrint('[CREATE_BOOKING] parsed error=$msg');
          debugPrint('[CREATE_BOOKING] full root=$root');
        }

        throw Exception(msg);
      }

      final rawData = root['data'];
      if (rawData is! Map) {
        if (kDebugMode) {
          debugPrint('[CREATE_BOOKING] invalid data payload: $rawData');
        }
        throw Exception('Invalid booking response');
      }

      final data = Map<String, dynamic>.from(rawData);
      return BookingModel.fromJson(data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (kDebugMode) {
        debugPrint('[CREATE_BOOKING] DioException status=$statusCode');
        debugPrint('[CREATE_BOOKING] DioException data=$data');
        debugPrint('[CREATE_BOOKING] DioException message=${e.message}');
      }

      throw Exception(
        _extractDioMessage(
          e,
          fallback: 'Failed to create booking',
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CREATE_BOOKING] unexpected error=$e');
      }
      rethrow;
    }
  }

  Future<BookingModel> getBookingById({
    required String bookingId,
  }) async {
    final resolvedBookingId = bookingId.trim();

    if (kDebugMode) {
      debugPrint('[BOOKING_BY_ID] GET /bookings/$resolvedBookingId');
    }

    try {
      final res = await api.dio.get('bookings/$resolvedBookingId');

      if (kDebugMode) {
        debugPrint('[BOOKING_BY_ID] status=${res.statusCode}');
        debugPrint('[BOOKING_BY_ID] response=${res.data}');
      }

      final root = _asMap(res.data);
      if (root == null) {
        throw Exception('Invalid booking response');
      }

      if (root['success'] == false) {
        throw Exception(_extractErrorMessage(root));
      }

      final rawData = root['data'];
      if (rawData is! Map) {
        throw Exception('Invalid booking response');
      }

      final data = Map<String, dynamic>.from(rawData);
      return BookingModel.fromJson(data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[BOOKING_BY_ID] DioException status=${e.response?.statusCode}');
        debugPrint('[BOOKING_BY_ID] DioException data=${e.response?.data}');
      }

      throw Exception(
        _extractDioMessage(
          e,
          fallback: 'Failed to load booking',
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BOOKING_BY_ID] unexpected error=$e');
      }
      rethrow;
    }
  }

  Future<QrCodeModel> getQrCode({
    required String bookingId,
  }) async {
    final resolvedBookingId = bookingId.trim();

    if (kDebugMode) {
      debugPrint('[BOOKING_QR] GET /bookings/$resolvedBookingId/qr');
    }

    try {
      final res = await api.dio.get('bookings/$resolvedBookingId/qr');

      if (kDebugMode) {
        debugPrint('[BOOKING_QR] status=${res.statusCode}');
        debugPrint('[BOOKING_QR] response=${res.data}');
      }

      final root = _asMap(res.data);
      if (root == null) {
        throw Exception('Invalid QR response');
      }

      if (root['success'] == false) {
        throw Exception(_extractErrorMessage(root));
      }

      final rawData = root['data'];
      if (rawData is! Map) {
        throw Exception('Invalid QR response');
      }

      final data = Map<String, dynamic>.from(rawData);
      return QrCodeModel.fromJson(data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[BOOKING_QR] DioException status=${e.response?.statusCode}');
        debugPrint('[BOOKING_QR] DioException data=${e.response?.data}');
      }

      throw Exception(
        _extractDioMessage(
          e,
          fallback: 'Failed to load QR code',
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BOOKING_QR] unexpected error=$e');
      }
      rethrow;
    }
  }

  Future<PaymentResultModel> initiateDepositPayment({
    required String bookingId,
  }) async {
    final resolvedBookingId = bookingId.trim();

    final payload = <String, dynamic>{
      'bookingId': resolvedBookingId,
    };

    if (kDebugMode) {
      debugPrint('[PAYMENT] POST /payments/deposit/init');
      debugPrint('[PAYMENT] request payload=$payload');
    }

    try {
      final res = await api.dio.post(
        'payments/deposit/init',
        data: payload,
      );

      if (kDebugMode) {
        debugPrint('[PAYMENT] status=${res.statusCode}');
        debugPrint('[PAYMENT] response=${res.data}');
      }

      return PaymentResultModel.fromAny(res.data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (kDebugMode) {
        debugPrint('[PAYMENT] DioException status=$statusCode');
        debugPrint('[PAYMENT] DioException data=$data');
        debugPrint('[PAYMENT] DioException message=${e.message}');
      }

      if (data is Map) {
        return PaymentResultModel.fromAny(data);
      }

      if (data is String && data.trim().isNotEmpty) {
        return PaymentResultModel(
          success: false,
          data: null,
          error: PaymentErrorModel(
            code: statusCode?.toString() ?? 'PAYMENT_FAILED',
            message: const {},
            plainMessage: data.trim(),
          ),
          message: data.trim(),
          status: statusCode?.toString(),
          raw: {
            'statusCode': statusCode,
            'data': data,
          },
        );
      }

      return PaymentResultModel(
        success: false,
        data: null,
        error: PaymentErrorModel(
          code: statusCode?.toString() ?? 'PAYMENT_FAILED',
          message: const {},
          plainMessage: e.message,
        ),
        message: e.message,
        status: statusCode?.toString(),
        raw: {
          'statusCode': statusCode,
          'data': data,
          'dioMessage': e.message,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PAYMENT] unexpected error=$e');
      }

      return PaymentResultModel(
        success: false,
        data: null,
        error: PaymentErrorModel(
          code: 'PAYMENT_PARSE_ERROR',
          message: const {},
          plainMessage: e.toString(),
        ),
        message: e.toString(),
        status: 'PAYMENT_PARSE_ERROR',
        raw: {
          'error': e.toString(),
        },
      );
    }
  }

  Future<PaymentResultModel> initiateWalletPayment({
    required String bookingId,
  }) {
    return initiateDepositPayment(bookingId: bookingId.trim());
  }

  Future<CancelBookingResultModel> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    final resolvedBookingId = bookingId.trim();

    try {
      final res = await api.dio.patch(
        'bookings/$resolvedBookingId/cancel',
        data: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );

      if (kDebugMode) {
        debugPrint('[CANCEL] status=${res.statusCode}');
        debugPrint('[CANCEL] response=${res.data}');
      }

      final root = Map<String, dynamic>.from(res.data as Map);
      return CancelBookingResultModel.fromJson(root);
    } on DioException catch (e) {
      final data = e.response?.data;

      if (kDebugMode) {
        debugPrint('[CANCEL] DioException status=${e.response?.statusCode}');
        debugPrint('[CANCEL] DioException data=$data');
      }

      if (data is Map) {
        final parsed = CancelBookingResultModel.fromJson(
          Map<String, dynamic>.from(data),
        );

        final message =
            parsed.messageAr ??
            parsed.messageEn ??
            _extractErrorMessage(Map<String, dynamic>.from(data));

        throw Exception(message);
      }

      if (data is String && data.trim().isNotEmpty) {
        throw Exception(data.trim());
      }

      if (e.message != null && e.message!.trim().isNotEmpty) {
        throw Exception(e.message!.trim());
      }

      throw Exception('Failed to cancel booking');
    }
  }

  Future<BookingsListResult> getMyBookings({
    String? status,
    String? category,
    String? fieldId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 10,
  }) async {
    final resolvedStatus = status?.trim();
    final resolvedCategory = category?.trim();
    final resolvedFieldId = fieldId?.trim();

    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (resolvedStatus != null && resolvedStatus.isNotEmpty)
        'status': resolvedStatus,
      if (resolvedCategory != null && resolvedCategory.isNotEmpty)
        'category': resolvedCategory,
      if (resolvedFieldId != null && resolvedFieldId.isNotEmpty)
        'fieldId': resolvedFieldId,
      if (startDate != null) 'startDate': _isoDate(startDate),
      if (endDate != null) 'endDate': _isoDate(endDate),
    };

    if (kDebugMode) {
      debugPrint('[MY_BOOKINGS] GET /bookings/my');
      debugPrint('[MY_BOOKINGS] query=$queryParameters');
    }

    try {
      final res = await api.dio.get(
        'bookings/my',
        queryParameters: queryParameters,
      );

      if (kDebugMode) {
        debugPrint('[MY_BOOKINGS] status=${res.statusCode}');
        debugPrint('[MY_BOOKINGS] response=${res.data}');
      }

      final root = Map<String, dynamic>.from(res.data as Map);
      return BookingsListResult.fromJson(root);
    } on DioException catch (e) {
      final data = e.response?.data;

      if (kDebugMode) {
        debugPrint('[MY_BOOKINGS] DioException status=${e.response?.statusCode}');
        debugPrint('[MY_BOOKINGS] DioException data=$data');
      }

      throw Exception(
        _extractDioMessage(
          e,
          fallback: 'Failed to load bookings',
        ),
      );
    }
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  String _extractDioMessage(
    DioException e, {
    required String fallback,
  }) {
    final data = e.response?.data;

    if (data is Map) {
      return _extractErrorMessage(Map<String, dynamic>.from(data));
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (e.message != null && e.message!.trim().isNotEmpty) {
      return e.message!.trim();
    }

    return fallback;
  }

  String _extractErrorMessage(Map<String, dynamic> root) {
    final error = root['error'];

    if (error is Map) {
      final mapError = Map<String, dynamic>.from(error);

      final msg = _extractLocalizedText(mapError['message']);
      if (msg.isNotEmpty) return msg;

      final details = mapError['details'];

      if (details is List && details.isNotEmpty) {
        for (final item in details) {
          if (item is Map) {
            final detailMessage = _extractLocalizedText(item['message']);
            if (detailMessage.isNotEmpty) return detailMessage;
          }

          final text = item?.toString().trim();
          if (text != null && text.isNotEmpty) return text;
        }
      }

      if (details is String && details.trim().isNotEmpty) {
        return details.trim();
      }

      final code = mapError['code']?.toString().trim();
      if (code != null && code.isNotEmpty) return code;
    }

    final errors = root['errors'];
    if (errors is List && errors.isNotEmpty) {
      final joined = errors
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .join(', ');
      if (joined.isNotEmpty) return joined;
    }

    final message = _extractLocalizedText(root['message']);
    if (message.isNotEmpty) return message;

    return 'Failed to load bookings';
  }

  String _extractLocalizedText(dynamic value) {
    if (value is Map) {
      final ar = value['ar']?.toString().trim();
      final en = value['en']?.toString().trim();

      if (ar != null && ar.isNotEmpty) return ar;
      if (en != null && en.isNotEmpty) return en;
    }

    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;

    return '';
  }

  String _isoDate(DateTime d) {
    final x = d.toLocal();
    final mm = x.month.toString().padLeft(2, '0');
    final dd = x.day.toString().padLeft(2, '0');
    return '${x.year}-$mm-$dd';
  }
}
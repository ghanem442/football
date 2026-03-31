import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/network/providers.dart';
import 'package:football/features/bookings/data/booking_repository.dart';

import '../../data/models/booking_model.dart';
import '../../data/models/bookings_list_result_model.dart';
import '../../data/models/cancel_booking_result_model.dart';
import '../../data/models/payment_result_model.dart';
import '../../data/models/time_slot_model.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return BookingsRepository(api);
});

final timeSlotsProvider =
    FutureProvider.family<List<TimeSlotModel>, TimeSlotsQuery>((ref, q) async {
  ref.keepAlive();

  final repo = ref.watch(bookingsRepositoryProvider);

  final slots = await repo.getTimeSlots(
    fieldId: q.fieldId,
    startDate: q.startDate,
    endDate: q.endDate,
  );

  return slots;
});

final createBookingProvider =
    FutureProvider.family<BookingModel, String>((ref, timeSlotId) async {
  final repo = ref.watch(bookingsRepositoryProvider);
  final booking = await repo.createBooking(timeSlotId: timeSlotId);
  return booking;
});

final bookingByIdProvider =
    FutureProvider.family<BookingModel, String>((ref, bookingId) async {
  final repo = ref.watch(bookingsRepositoryProvider);
  return repo.getBookingById(bookingId: bookingId);
});

final bookingQrProvider =
    FutureProvider.family<QrCodeModel, String>((ref, bookingId) async {
  final repo = ref.watch(bookingsRepositoryProvider);
  return repo.getQrCode(bookingId: bookingId);
});

final initiateDepositPaymentProvider =
    FutureProvider.family<PaymentResultModel, String>((ref, bookingId) async {
  final repo = ref.watch(bookingsRepositoryProvider);
  return repo.initiateDepositPayment(bookingId: bookingId);
});

final initiateWalletPaymentProvider = initiateDepositPaymentProvider;

final cancelBookingProvider =
    FutureProvider.family<CancelBookingResultModel, CancelBookingParams>(
  (ref, p) async {
    final repo = ref.watch(bookingsRepositoryProvider);
    return repo.cancelBooking(
      bookingId: p.bookingId,
      reason: p.reason,
    );
  },
);

final myBookingsProvider =
    FutureProvider.family<BookingsListResult, MyBookingsQuery>((ref, q) async {
  final repo = ref.watch(bookingsRepositoryProvider);
  return repo.getMyBookings(
    status: q.status,
    category: q.category,
    fieldId: q.fieldId,
    startDate: q.startDate,
    endDate: q.endDate,
    page: q.page,
    limit: q.limit,
  );
});

class CancelBookingParams {
  final String bookingId;
  final String? reason;

  const CancelBookingParams({
    required this.bookingId,
    this.reason,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CancelBookingParams &&
          runtimeType == other.runtimeType &&
          bookingId == other.bookingId &&
          (reason ?? '') == (other.reason ?? '');

  @override
  int get hashCode => bookingId.hashCode ^ (reason ?? '').hashCode;
}

class TimeSlotsQuery {
  final String fieldId;
  final DateTime startDate;
  final DateTime endDate;

  const TimeSlotsQuery({
    required this.fieldId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlotsQuery &&
          runtimeType == other.runtimeType &&
          fieldId == other.fieldId &&
          _sameDay(startDate, other.startDate) &&
          _sameDay(endDate, other.endDate);

  @override
  int get hashCode =>
      fieldId.hashCode ^ _dayHash(startDate) ^ _dayHash(endDate);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int _dayHash(DateTime d) => (d.year * 10000 + d.month * 100 + d.day);
}

class MyBookingsQuery {
  final String? status;
  final String? category;
  final String? fieldId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;

  const MyBookingsQuery({
    this.status,
    this.category,
    this.fieldId,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 10,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyBookingsQuery &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          category == other.category &&
          fieldId == other.fieldId &&
          page == other.page &&
          limit == other.limit &&
          _sameDay(startDate, other.startDate) &&
          _sameDay(endDate, other.endDate);

  @override
  int get hashCode =>
      (status ?? '').hashCode ^
      (category ?? '').hashCode ^
      (fieldId ?? '').hashCode ^
      page.hashCode ^
      limit.hashCode ^
      _dayHash(startDate) ^
      _dayHash(endDate);

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int _dayHash(DateTime? d) =>
      d == null ? 0 : (d.year * 10000 + d.month * 100 + d.day);
}
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_booking_model.dart';
import '../../data/providers/admin_bookings_repository_provider.dart';

class AdminBookingsState {
  final bool isLoading;
  final String? error;
  final List<AdminBookingModel> bookings;
  final String search;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;

  const AdminBookingsState({
    required this.isLoading,
    required this.error,
    required this.bookings,
    required this.search,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory AdminBookingsState.initial() {
    return const AdminBookingsState(
      isLoading: false,
      error: null,
      bookings: [],
      search: '',
      status: null,
      startDate: null,
      endDate: null,
    );
  }

  AdminBookingsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<AdminBookingModel>? bookings,
    String? search,
    String? status,
    bool clearStatus = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return AdminBookingsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      bookings: bookings ?? this.bookings,
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  bool get hasFilters =>
      search.trim().isNotEmpty ||
      status != null ||
      startDate != null ||
      endDate != null;
}

class AdminBookingsNotifier extends Notifier<AdminBookingsState> {
  @override
  AdminBookingsState build() {
    Future.microtask(loadBookings);
    return AdminBookingsState.initial();
  }

  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(adminBookingsRepositoryProvider);

      final bookings = await repo.getBookings(
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        status: state.status,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      state = state.copyWith(
        isLoading: false,
        bookings: bookings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> applySearch(String value) async {
    state = state.copyWith(search: value);
    await loadBookings();
  }

  Future<void> setStatus(String? value) async {
    state = value == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(status: value);
    await loadBookings();
  }

  Future<void> setDateRange({
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
    );
    await loadBookings();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      search: '',
      clearStatus: true,
      clearStartDate: true,
      clearEndDate: true,
    );
    await loadBookings();
  }

  Future<void> refresh() async {
    await loadBookings();
  }
}

final adminBookingsProvider =
    NotifierProvider<AdminBookingsNotifier, AdminBookingsState>(
  AdminBookingsNotifier.new,
);
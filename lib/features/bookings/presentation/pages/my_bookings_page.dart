import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/booking_providers.dart';
import '../../data/models/booking_model.dart';
import 'booking_confirmation_page.dart';

class MyBookingsPage extends ConsumerStatefulWidget {
  const MyBookingsPage({super.key});

  @override
  ConsumerState<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends ConsumerState<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const int _limit = 20;

  static const List<String> _categories = [
    'upcoming',
    'cancelled',
    'played',
    'expired',
  ];

  static const List<String> _labels = [
    'Upcoming',
    'Cancelled',
    'Played',
    'Expired',
  ];

  String? _cancellingBookingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  MyBookingsQuery _currentQuery() {
    final category = _categories[_tabController.index];

    return MyBookingsQuery(
      category: category,
      status: _mapCategoryToStatus(category),
      page: 1,
      limit: _limit,
    );
  }

  String? _mapCategoryToStatus(String category) {
    switch (category) {
      case 'upcoming':
        return 'CONFIRMED,PENDING_PAYMENT,CHECKED_IN';
      case 'cancelled':
        return 'CANCELLED,CANCELLED_REFUNDED,CANCELLED_NO_REFUND';
      case 'played':
        return 'PLAYED,COMPLETED';
      case 'expired':
        return 'EXPIRED_NO_SHOW,NO_SHOW,PAYMENT_FAILED';
      default:
        return null;
    }
  }

  Future<void> _refresh() async {
    final query = _currentQuery();
    ref.invalidate(myBookingsProvider(query));
    await ref.read(myBookingsProvider(query).future);
  }

  void _invalidateAllBookingTabs() {
    for (final category in _categories) {
      ref.invalidate(
        myBookingsProvider(
          MyBookingsQuery(
            category: category,
            status: _mapCategoryToStatus(category),
            page: 1,
            limit: _limit,
          ),
        ),
      );
    }
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    if (!booking.canCancel || _cancellingBookingId != null) return;

    final result =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Booking?'),
            content: Text(
              booking.willGetRefund
                  ? 'Are you sure you want to cancel ${booking.bookingNumberDisplay}?\n\nA refund will be returned to your wallet.'
                  : 'Are you sure you want to cancel ${booking.bookingNumberDisplay}?\n\nThis booking is no longer eligible for refund.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
        ) ??
        false;

    if (!result || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _cancellingBookingId = booking.id;
    });

    try {
      final cancelResult = await ref.read(
        cancelBookingProvider(
          CancelBookingParams(
            bookingId: booking.id,
            reason: 'Cancelled by player',
          ),
        ).future,
      );

      _invalidateAllBookingTabs();
      ref.invalidate(bookingByIdProvider(booking.id));
      ref.invalidate(bookingQrProvider(booking.id));

      if (!mounted) return;

      final refund = cancelResult.refund;
      final message = (cancelResult.messageAr?.trim().isNotEmpty == true)
          ? cancelResult.messageAr!.trim()
          : (cancelResult.messageEn?.trim().isNotEmpty == true)
              ? cancelResult.messageEn!.trim()
              : 'Booking cancelled successfully';

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            refund.amount > 0
                ? '$message • Refund ${_refundPercentage(refund.percentage)}% (${_formatMoney(refund.amount)} EGP)'
                : message,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancellingBookingId = null;
        });
      }
    }
  }

  String _extractErrorMessage(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '').trim();
    if (text.isNotEmpty) return text;
    return 'Failed to cancel booking';
  }

  String _refundPercentage(num value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  bool _shouldShowQr(BookingModel booking) {
    final status = booking.statusUpper;
    if (status != 'CONFIRMED' && status != 'CHECKED_IN') {
      return false;
    }
    return booking.canShowQr;
  }

  @override
  Widget build(BuildContext context) {
    final query = _currentQuery();
    final bookingsAsync = ref.watch(myBookingsProvider(query));

    final switchKey = ValueKey(
      'tab_${_tabController.index}_${query.category ?? "unknown"}',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Home',
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Cancelled'),
            Tab(text: 'Played'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: bookingsAsync.when(
            loading: () => _LoadingSkeleton(key: switchKey),
            error: (e, _) => _ErrorState(
              key: switchKey,
              onRetry: _refresh,
              message: _extractErrorMessage(e),
            ),
            data: (result) {
              final bookings = result.bookings;

              if (bookings.isEmpty) {
                return _EmptyState(
                  key: ValueKey('empty_${query.category}'),
                  title: _labels[_tabController.index],
                );
              }

              return ListView.builder(
                key: switchKey,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final isCancelling = _cancellingBookingId == booking.id;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 220 + (index * 35)),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) {
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 10),
                          child: child,
                        ),
                      );
                    },
                    child: _BookingCard(
                      booking: booking,
                      isCancelling: isCancelling,
                      canShowQr: _shouldShowQr(booking),
                      onCancel: booking.canCancel && !isCancelling
                          ? () => _cancelBooking(booking)
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onCancel;
  final bool canShowQr;
  final bool isCancelling;

  const _BookingCard({
    required this.booking,
    required this.onCancel,
    required this.canShowQr,
    required this.isCancelling,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldName = booking.fieldDisplayName;
    final status = booking.statusUpper;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          context.go(
            '/booking-confirmation',
            extra: BookingConfirmationArgs(booking: booking),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      booking.bookingNumberDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: _StatusBadge(status: status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                fieldName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if ((booking.fieldAddress ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  booking.fieldAddress!.trim(),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_formatDate(booking.scheduledDate))),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_formatTime(booking.scheduledStart)} - ${_formatTime(booking.scheduledEnd)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_formatMoney(booking.depositAsDouble)} EGP deposit',
                    ),
                  ),
                ],
              ),
              if (booking.remainingAsDouble > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_formatMoney(booking.remainingAsDouble)} EGP remaining at field',
                      ),
                    ),
                  ],
                ),
              ],
              if (booking.paymentGateway != null &&
                  booking.paymentGateway!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.credit_card, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Payment: ${booking.paymentGateway} • ${booking.paymentStatus ?? "-"}',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      context.go(
                        '/booking-confirmation',
                        extra: BookingConfirmationArgs(booking: booking),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Details'),
                  ),
                  if (booking.canCancel)
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: isCancelling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        isCancelling
                            ? 'Cancelling...'
                            : booking.willGetRefund
                                ? 'Cancel + Refund'
                                : 'Cancel',
                      ),
                    ),
                  if (canShowQr)
                    FilledButton.tonalIcon(
                      onPressed: () {
                        context.push('/booking/${booking.id}/qr');
                      },
                      icon: const Icon(Icons.qr_code_2, size: 18),
                      label: Text(booking.qrIsUsed ? 'QR Used' : 'Show QR'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'CONFIRMED':
        bg = Colors.green.withAlpha(30);
        fg = Colors.green;
        label = 'Confirmed';
        break;
      case 'PENDING_PAYMENT':
        bg = Colors.orange.withAlpha(38);
        fg = Colors.orange;
        label = 'Pending Payment';
        break;
      case 'CHECKED_IN':
        bg = Colors.blueGrey.withAlpha(38);
        fg = Colors.blueGrey.shade900;
        label = 'Checked In';
        break;
      case 'COMPLETED':
        bg = Colors.blue.withAlpha(30);
        fg = Colors.blue;
        label = 'Completed';
        break;
      case 'PLAYED':
        bg = Colors.blue.withAlpha(30);
        fg = Colors.blue;
        label = 'Played';
        break;
      case 'CANCELLED_REFUNDED':
        bg = Colors.red.withAlpha(30);
        fg = Colors.red;
        label = 'Cancelled + Refunded';
        break;
      case 'CANCELLED_NO_REFUND':
        bg = Colors.red.withAlpha(30);
        fg = Colors.red;
        label = 'Cancelled';
        break;
      case 'CANCELLED':
        bg = Colors.red.withAlpha(30);
        fg = Colors.red;
        label = 'Cancelled';
        break;
      case 'EXPIRED_NO_SHOW':
        bg = Colors.grey.withAlpha(38);
        fg = Colors.grey.shade800;
        label = 'Expired';
        break;
      case 'NO_SHOW':
        bg = Colors.grey.withAlpha(38);
        fg = Colors.grey.shade800;
        label = 'No Show';
        break;
      case 'PAYMENT_FAILED':
        bg = Colors.deepOrange.withAlpha(35);
        fg = Colors.deepOrange;
        label = 'Payment Failed';
        break;
      case 'PARTIALLY_REFUNDED':
        bg = Colors.orange.withAlpha(30);
        fg = Colors.orange;
        label = 'Partially Refunded';
        break;
      case 'REFUND_FAILED':
        bg = Colors.red.withAlpha(40);
        fg = Colors.red;
        label = 'Refund Failed';
        break;
      default:
        bg = Colors.grey.withAlpha(38);
        fg = Colors.grey.shade800;
        label = status.replaceAll('_', ' ');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;

  const _EmptyState({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: ValueKey('empty_state_$title'),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        const Icon(Icons.event_busy, size: 60, color: Colors.grey),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No $title bookings found',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;

  const _ErrorState({
    super.key,
    required this.onRetry,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('error_state'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 110),
        const Icon(Icons.error_outline, size: 60, color: Colors.red),
        const SizedBox(height: 12),
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget box({double h = 14, double w = double.infinity, double r = 10}) {
      return Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: theme.dividerColor.withAlpha(40),
          borderRadius: BorderRadius.circular(r),
        ),
      );
    }

    Widget card() {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: box(h: 16, w: 160)),
                const SizedBox(width: 10),
                box(h: 24, w: 110, r: 999),
              ],
            ),
            const SizedBox(height: 14),
            box(h: 14, w: 220),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: box(h: 14, w: 140))]),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: box(h: 14, w: 180))]),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: box(h: 14, w: 130))]),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                box(h: 36, w: 100, r: 999),
                box(h: 36, w: 120, r: 999),
                box(h: 36, w: 110, r: 999),
              ],
            ),
          ],
        ),
      );
    }

    return ListView(
      key: const ValueKey('loading_state'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [card(), card(), card()],
    );
  }
}

String _formatDate(DateTime d) {
  final x = d.toLocal();
  final dd = x.day.toString().padLeft(2, '0');
  final mm = x.month.toString().padLeft(2, '0');
  final yyyy = x.year.toString();
  return '$dd/$mm/$yyyy';
}

String _formatTime(DateTime d) {
  final x = d.toLocal();
  int h = x.hour;
  final m = x.minute.toString().padLeft(2, '0');
  final ampm = h >= 12 ? 'PM' : 'AM';
  h = h % 12;
  if (h == 0) h = 12;
  return '$h:$m $ampm';
}

String _formatMoney(double value) {
  if (value == value.truncateToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}
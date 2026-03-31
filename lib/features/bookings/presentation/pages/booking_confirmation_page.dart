import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/core/theme/app_theme.dart';
import 'package:football/features/fields/data/models/field_model.dart';
import 'package:football/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/booking_model.dart';
import '../../data/models/payment_result_model.dart';
import '../providers/booking_providers.dart';

class BookingConfirmationArgs {
  final BookingModel booking;
  final FieldModel? field;

  const BookingConfirmationArgs({
    required this.booking,
    this.field,
  });
}

class BookingConfirmationPage extends ConsumerStatefulWidget {
  final BookingConfirmationArgs? args;

  const BookingConfirmationPage({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<BookingConfirmationPage> createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState
    extends ConsumerState<BookingConfirmationPage>
    with WidgetsBindingObserver {
  Timer? _timer;
  Duration? _remaining;

  bool _paying = false;
  bool _cancelling = false;
  bool _refreshingAfterPayment = false;
  bool _awaitingPaymentReturn = false;

  static const _allBookingsQueries = [
    MyBookingsQuery(page: 1, limit: 20),
    MyBookingsQuery(category: 'upcoming', page: 1, limit: 20),
    MyBookingsQuery(category: 'cancelled', page: 1, limit: 20),
    MyBookingsQuery(category: 'played', page: 1, limit: 20),
    MyBookingsQuery(category: 'expired', page: 1, limit: 20),
    MyBookingsQuery(status: 'CONFIRMED', page: 1, limit: 20),
    MyBookingsQuery(status: 'PENDING_PAYMENT', page: 1, limit: 20),
    MyBookingsQuery(status: 'CANCELLED_REFUNDED', page: 1, limit: 20),
    MyBookingsQuery(status: 'CANCELLED_NO_REFUND', page: 1, limit: 20),
    MyBookingsQuery(status: 'PLAYED', page: 1, limit: 20),
    MyBookingsQuery(status: 'EXPIRED_NO_SHOW', page: 1, limit: 20),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingPaymentReturn) {
      _awaitingPaymentReturn = false;
      unawaited(_refreshAfterPaymentReturn());
    }
  }

  void _startCountdown() {
    final deadline = widget.args?.booking.paymentDeadline;
    if (deadline == null) return;

    void tick() {
      final diff = deadline.difference(DateTime.now());
      if (!mounted) return;
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }

    tick();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _invalidateAllBookings() {
    for (final query in _allBookingsQueries) {
      ref.invalidate(myBookingsProvider(query));
    }
  }

  Map<String, dynamic>? _rootFromDio(Object e) {
    if (e is! DioException) return null;
    final data = e.response?.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  String? _errorCode(Object e) {
    final root = _rootFromDio(e);
    if (root == null) return null;

    final err = root['error'];
    if (err is! Map) return null;

    return err['code']?.toString();
  }

  String _errorMessageAr(Object e) {
    const fallback = 'حدث خطأ، حاول مرة أخرى';

    if (e is PaymentResultModel) {
      return e.userMessageAr;
    }

    final root = _rootFromDio(e);
    if (root == null) {
      final text = e.toString().replaceFirst('Exception: ', '').trim();
      return text.isEmpty ? fallback : text;
    }

    final err = root['error'];
    if (err is Map) {
      final msg = err['message'];

      if (msg is Map) {
        final msgMap = Map<String, dynamic>.from(msg);

        final ar = msgMap['ar']?.toString();
        if (ar != null && ar.trim().isNotEmpty) return ar.trim();

        final en = msgMap['en']?.toString();
        if (en != null && en.trim().isNotEmpty) return en.trim();
      }

      if (msg is String && msg.trim().isNotEmpty) {
        return msg.trim();
      }

      final code = err['code']?.toString();
      if (code != null && code.trim().isNotEmpty) return code.trim();
    }

    final rootMessage = root['message']?.toString();
    if (rootMessage != null && rootMessage.trim().isNotEmpty) {
      return rootMessage.trim();
    }

    return fallback;
  }

  bool _isEmailNotVerifiedError(Object e) {
    if (e is PaymentResultModel) {
      return e.errorCode == 'EMAIL_NOT_VERIFIED';
    }
    return _errorCode(e) == 'EMAIL_NOT_VERIFIED';
  }

  Future<void> _showEmailNotVerifiedDialog(Object e) async {
    final messageAr = _errorMessageAr(e);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد البريد الإلكتروني'),
        content: Text(messageAr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسنًا'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'الحساب غير مُفعّل. افتح شاشة Verify Email / Resend وأعد إرسال التفعيل.',
                  ),
                ),
              );
            },
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleNotVerifiedIfNeeded(Object e) async {
    if (!_isEmailNotVerifiedError(e)) return false;
    if (!mounted) return true;
    await _showEmailNotVerifiedDialog(e);
    return true;
  }

  String _extractRedirectUrl(PaymentResultModel result) {
    if (result.redirectUrl.trim().isNotEmpty) {
      return result.redirectUrl.trim();
    }

    final raw = result.raw;
    if (raw == null) return '';

    final direct = raw['redirectUrl']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final data = raw['data'];
    if (data is Map) {
      final nested = Map<String, dynamic>.from(data);
      final nestedUrl = nested['redirectUrl']?.toString().trim();
      if (nestedUrl != null && nestedUrl.isNotEmpty) return nestedUrl;
    }

    return '';
  }

  LaunchMode _launchModeForPayment() {
    return kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
  }

  Future<bool> _openPaymentUrl(Uri uri) async {
    if (kDebugMode) {
      debugPrint('[PAY_INIT] opening uri=$uri');
      debugPrint('[PAY_INIT] launchMode=${_launchModeForPayment()}');
    }

    return launchUrl(
      uri,
      mode: _launchModeForPayment(),
      webOnlyWindowName: '_self',
    );
  }

  Future<void> _refreshAfterPaymentReturn() async {
    if (_refreshingAfterPayment || !mounted || widget.args == null) return;

    setState(() => _refreshingAfterPayment = true);

    try {
      final bookingId = widget.args!.booking.id;

      BookingModel? updated;

      for (int i = 0; i < 3; i++) {
        ref.invalidate(bookingByIdProvider(bookingId));
        ref.invalidate(bookingQrProvider(bookingId));
        _invalidateAllBookings();

        updated = await ref.refresh(bookingByIdProvider(bookingId).future);

        final status = updated?.status.toUpperCase() ?? '';
if (status == 'CONFIRMED' || status == 'PLAYED') {
  break;
}

        await Future.delayed(const Duration(seconds: 2));
      }

      if (!mounted || updated == null) return;

      final status = updated.status.toUpperCase();

      if (status == 'CONFIRMED' || status == 'PLAYED') {
        await ref.read(walletProvider.notifier).refreshWallet();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تأكيد الحجز بعد الدفع بنجاح'),
          ),
        );
      } else if (status == 'PENDING_PAYMENT') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'الدفع لم يتأكد بعد. لو دفعت بالفعل انتظر ثواني ثم حدّث الحالة.',
            ),
          ),
        );
      } else if (status == 'PAYMENT_FAILED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل الدفع أو لم يكتمل'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تحديث حالة الحجز بعد الرجوع من صفحة الدفع'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _refreshingAfterPayment = false);
      }
    }
  }

  Future<void> _startOnlinePayment(BookingModel booking) async {
    if (_paying) return;

    setState(() => _paying = true);

    try {
      final result = await ref.read(
        initiateDepositPaymentProvider(booking.id).future,
      );

      if (!mounted) return;

      if (!result.isSuccess) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(result.userMessageAr)),
          );
        return;
      }

      final redirectUrl = _extractRedirectUrl(result);

      if (redirectUrl.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                result.userMessageAr.trim().isNotEmpty
                    ? result.userMessageAr
                    : 'لم يتم استلام رابط الدفع من الخادم',
              ),
            ),
          );
        return;
      }

      final uri = Uri.tryParse(redirectUrl);
      if (uri == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('رابط الدفع غير صالح')),
          );
        return;
      }

      _awaitingPaymentReturn = true;

      final opened = await _openPaymentUrl(uri);

      if (!mounted) return;

      if (!opened) {
        _awaitingPaymentReturn = false;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('تعذر فتح صفحة الدفع')),
          );
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('أكمل الدفع ثم ارجع للتطبيق'),
          ),
        );
    } catch (e) {
      final handled = await _handleNotVerifiedIfNeeded(e);
      if (handled) return;
      if (!mounted) return;

      final msg = _errorMessageAr(e);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(msg)),
        );
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }

  Future<void> _confirmAndCancel(BookingModel booking) async {
    if (_cancelling) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الحجز؟'),
        content: const Text(
          'هل أنت متأكد أنك تريد إلغاء هذا الحجز؟\n\n'
          'لو الحجز مستحق للاسترداد، سيتم إضافة الرصيد للمحفظة تلقائيًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _cancelling = true);

    try {
      final res = await ref.read(
        cancelBookingProvider(
          CancelBookingParams(
            bookingId: booking.id,
            reason: 'Cancelled by player',
          ),
        ).future,
      );

      if (!mounted) return;

      ref.invalidate(bookingByIdProvider(booking.id));
      ref.invalidate(bookingQrProvider(booking.id));
      _invalidateAllBookings();
      await ref.read(walletProvider.notifier).refreshWallet();

      if (!mounted) return;

      final refund = res.refund;
      final msg = (res.messageAr?.trim().isNotEmpty == true)
          ? res.messageAr!.trim()
          : 'تم إلغاء الحجز';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$msg\nالاسترداد: ${refund.percentage}% (${_formatMoney(refund.amount)} EGP)',
            ),
          ),
        );
    } catch (e) {
      final handled = await _handleNotVerifiedIfNeeded(e);
      if (handled) return;
      if (!mounted) return;

      final msg = _errorMessageAr(e);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(msg)),
        );
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    if (args == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Confirmation'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              tooltip: 'Home',
              icon: const Icon(Icons.home),
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Missing booking data',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We could not load the booking details for this page.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/my-bookings'),
                  child: const Text('Go to My Bookings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bookingAsync = ref.watch(bookingByIdProvider(args.booking.id));

    return bookingAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Booking Confirmation'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              tooltip: 'Home',
              icon: const Icon(Icons.home),
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Booking Confirmation'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              tooltip: 'Home',
              icon: const Icon(Icons.home),
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessageAr(e),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(bookingByIdProvider(args.booking.id));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (booking) {
        final statusUpper = booking.status.toUpperCase();

        const cancelledStatuses = {
          'CANCELLED',
          'CANCELLED_REFUNDED',
          'CANCELLED_NO_REFUND',
        };

        const qrAllowedStatuses = {
          'CONFIRMED',
          'PLAYED',
          'CHECKED_IN',
          'COMPLETED',
        };

        final isCancelled = cancelledStatuses.contains(statusUpper);
        final hasQr = qrAllowedStatuses.contains(statusUpper);

        final payableAmount = booking.depositAsDouble > 0
            ? booking.depositAsDouble
            : booking.totalAsDouble;

        final computedCashAtField =
            booking.totalAsDouble - booking.depositAsDouble;

        final cashAtFieldAmount = booking.remainingAmount.trim().isNotEmpty
            ? booking.remainingAsDouble
            : (computedCashAtField < 0 ? 0.0 : computedCashAtField);

        final qrAsync = hasQr && !isCancelled
            ? ref.watch(bookingQrProvider(booking.id))
            : null;

        final canPay = !isCancelled &&
            statusUpper == 'PENDING_PAYMENT' &&
            (booking.paymentDeadline == null ||
                (_remaining == null || _remaining! > Duration.zero));

        final canCancel = !isCancelled &&
            (statusUpper == 'CONFIRMED' || statusUpper == 'PENDING_PAYMENT');

        final fieldName = (booking.fieldName ?? '').trim().isNotEmpty
            ? booking.fieldName!.trim()
            : ((args.field?.nameAr?.trim().isNotEmpty == true)
                ? args.field!.nameAr!.trim()
                : (args.field?.name ?? '—'));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Booking Confirmation'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                tooltip: 'Home',
                icon: const Icon(Icons.home),
                onPressed: () => context.go('/home'),
              ),
              IconButton(
                tooltip: 'My Bookings',
                icon: const Icon(Icons.list_alt),
                onPressed: () => context.go('/my-bookings'),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CardShell(
                  child: Column(
                    children: [
                      if (hasQr && !isCancelled)
                        qrAsync!.when(
                          loading: () => _qrBoxLoading(),
                          error: (e, _) => _qrBoxError(
                            onRetry: () =>
                                ref.invalidate(bookingQrProvider(booking.id)),
                          ),
                          data: (qr) {
                            final url = qr.imageUrl.trim().isNotEmpty
                                ? qr.imageUrl
                                : (booking.qrImageUrl ?? '');

                            if (url.trim().isEmpty) {
                              return _qrBoxError(
                                onRetry: () => ref.invalidate(
                                  bookingQrProvider(booking.id),
                                ),
                              );
                            }

                            return _qrBoxImage(url);
                          },
                        )
                      else if (isCancelled)
                        _qrBoxCancelled()
                      else
                        _qrBoxPending(),
                      const SizedBox(height: 14),
                      Text(
                        booking.bookingNumber.trim().isNotEmpty
                            ? 'Booking #${booking.bookingNumber}'
                            : 'Booking #${_shortId(booking.id)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatusBadge(status: booking.status),
                      if (!isCancelled && booking.paymentDeadline != null) ...[
                        const SizedBox(height: 10),
                        _CountdownPill(
                          deadline: booking.paymentDeadline!,
                          remaining: _remaining,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _CardShell(
                  child: Column(
                    children: [
                      _RowItem(label: 'Field', value: fieldName),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      _RowItem(
                        label: 'Date',
                        value: _formatDate(booking.scheduledDate),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      _RowItem(
                        label: 'Time',
                        value:
                            '${_formatTime(booking.scheduledStart)} - ${_formatTime(booking.scheduledEnd)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _CardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RowItem(
                        label: 'Total Price',
                        value: '${_formatMoney(booking.totalAsDouble)} EGP',
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      _RowItem(
                        label: 'Pay Now (Deposit)',
                        value: '${_formatMoney(payableAmount)} EGP',
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      _RowItem(
                        label: 'Pay at Field (Cash)',
                        value: '${_formatMoney(cashAtFieldAmount)} EGP',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              AppColors.orange.withAlpha((0.08 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.orange
                                .withAlpha((0.20 * 255).round()),
                          ),
                        ),
                        child: const Text(
                          'سيتم فتح صفحة دفع Paymob لإتمام دفع العربون. باقي المبلغ يتم دفعه كاش في الملعب.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_refreshingAfterPayment) ...[
                  const SizedBox(height: 16),
                  const _CardShell(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'جارٍ تحديث حالة الحجز بعد الرجوع من صفحة الدفع...',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (canPay)
                  _PrimaryButton(
                    text: 'Pay Deposit Now',
                    color: AppColors.orange,
                    loading: _paying,
                    onPressed: () => _startOnlinePayment(booking),
                  ),
                if (hasQr && !isCancelled)
                  _PrimaryButton(
                    text: 'Show QR',
                    color: AppColors.green,
                    onPressed: () => context.push('/booking/${booking.id}/qr'),
                  ),
                if (canCancel)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: OutlinedButton(
                      onPressed: _cancelling
                          ? null
                          : () => _confirmAndCancel(booking),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _cancelling
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Cancel Booking',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                const SizedBox(height: 8),
                _SecondaryButton(
                  text: 'Refresh Booking Status',
                  loading: _refreshingAfterPayment,
                  onPressed: _refreshAfterPaymentReturn,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _GhostButton(
                        text: 'Back to My Bookings',
                        onPressed: () => context.go('/my-bookings'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GhostButton(
                        text: 'Go Home',
                        onPressed: () => context.go('/home'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qrBoxLoading() {
    return const _QrBox(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _qrBoxError({required VoidCallback onRetry}) {
    return _QrBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 40, color: Colors.orange),
            const SizedBox(height: 8),
            const Text(
              'QR is not available right now.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your booking may still be confirmed. Please try again later.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrBoxCancelled() {
    return const _QrBox(
      child: Center(
        child: Text(
          'Booking Cancelled',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _qrBoxPending() {
    return const _QrBox(
      child: Center(
        child: Text(
          'QR will appear after payment confirmation',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  String _resolveQrUrl(String imageUrl) {
    final raw = imageUrl.trim();
    if (raw.isEmpty) return '';

    if (kDebugMode) {
      debugPrint('[QR] raw imageUrl=$raw');
    }

    if (kIsWeb) {
      final resolved = raw
          .replaceAll('http://10.0.2.2:3000', 'http://localhost:3000')
          .replaceAll('http://127.0.0.1:3000', 'http://localhost:3000');

      if (kDebugMode) {
        debugPrint('[QR] resolved web imageUrl=$resolved');
      }

      return resolved;
    }

    const backendOrigin = String.fromEnvironment(
      'API_ORIGIN',
      defaultValue: 'http://10.0.2.2:3000',
    );

    final resolved = raw
        .replaceAll('http://localhost:3000', backendOrigin)
        .replaceAll('http://127.0.0.1:3000', backendOrigin);

    if (kDebugMode) {
      debugPrint('[QR] resolved mobile imageUrl=$resolved');
    }

    return resolved;
  }

  Widget _qrBoxImage(String imageUrl) {
    final resolvedUrl = _resolveQrUrl(imageUrl);

    if (resolvedUrl.isEmpty) {
      return _qrBoxError(onRetry: () {});
    }

    return _QrBox(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          resolvedUrl,
          height: 190,
          width: 190,
          fit: BoxFit.contain,
          errorBuilder: (_, error, stackTrace) {
            if (kDebugMode) {
              debugPrint('[QR] failed loading imageUrl=$resolvedUrl');
              debugPrint('[QR] error=$error');
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2, size: 48),
                  const SizedBox(height: 8),
                  const Text(
                    'QR image could not be loaded',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resolvedUrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;

  const _CardShell({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class _QrBox extends StatelessWidget {
  final Widget child;

  const _QrBox({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final Color color;
  final bool loading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.text,
    required this.color,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onPressed;

  const _SecondaryButton({
    required this.text,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blueGrey,
          side: const BorderSide(color: Colors.blueGrey),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const _GhostButton({
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    final fg = _statusColor(s);
    final bg = fg.withAlpha((0.14 * 255).round());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(s),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'CONFIRMED':
      case 'PLAYED':
      case 'COMPLETED':
      case 'CHECKED_IN':
        return AppColors.green;
      case 'PENDING_PAYMENT':
        return AppColors.orange;
      case 'CANCELLED':
      case 'CANCELLED_REFUNDED':
      case 'CANCELLED_NO_REFUND':
      case 'PAYMENT_FAILED':
      case 'NO_SHOW':
      case 'EXPIRED_NO_SHOW':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'PENDING_PAYMENT':
        return 'Pending Payment';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PLAYED':
        return 'Played';
      case 'CHECKED_IN':
        return 'Checked In';
      case 'COMPLETED':
        return 'Completed';
      case 'PAYMENT_FAILED':
        return 'Payment Failed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'CANCELLED_REFUNDED':
        return 'Cancelled + Refunded';
      case 'CANCELLED_NO_REFUND':
        return 'Cancelled بدون استرداد';
      case 'NO_SHOW':
        return 'No Show';
      case 'EXPIRED_NO_SHOW':
        return 'Expired / No Show';
      default:
        return s;
    }
  }
}

class _CountdownPill extends StatelessWidget {
  final DateTime deadline;
  final Duration? remaining;

  const _CountdownPill({
    required this.deadline,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final rem = remaining ?? deadline.difference(DateTime.now());
    final safe = rem.isNegative ? Duration.zero : rem;

    final mm = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = safe.inSeconds.remainder(60).toString().padLeft(2, '0');

    final text =
        safe == Duration.zero ? 'Payment expired' : 'Complete payment in $mm:$ss';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orange.withAlpha((0.14 * 255).round()),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.orange,
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;

  const _RowItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.subText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value.trim().isEmpty ? '—' : value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

String _shortId(String id) {
  final x = id.trim();
  if (x.isEmpty) return '—';
  if (x.length <= 8) return x;
  return x.substring(0, 8);
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
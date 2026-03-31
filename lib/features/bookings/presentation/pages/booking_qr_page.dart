import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/booking_providers.dart';

class BookingQrPage extends ConsumerWidget {
  final String bookingId;

  const BookingQrPage({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrAsync = ref.watch(bookingQrProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking QR'),
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
      body: SafeArea(
        child: qrAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_2, size: 48, color: Colors.orange),
                  const SizedBox(height: 10),
                  const Text(
                    'QR is not available right now, but your booking may still be confirmed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _friendlyQrError(e),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(bookingQrProvider(bookingId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/my-bookings'),
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Back to My Bookings'),
                  ),
                ],
              ),
            ),
          ),
          data: (qr) {
            final rawUrl = qr.imageUrl.trim();
            final url = _normalizeQrUrl(rawUrl);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: url.isEmpty
                          ? _qrFallbackBox(
                              message: 'QR image is not available right now.',
                            )
                          : Image.network(
                              url,
                              height: 260,
                              width: 260,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return _qrFallbackBox(
                                  message: 'QR image could not be loaded.',
                                );
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Show this QR to the owner عند الوصول للملعب',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking ID',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(bookingId),
                        const SizedBox(height: 12),
                        const Text(
                          'QR Status',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(qr.isUsed ? 'Used' : 'Ready'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                              'Used: ',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(qr.isUsed ? 'YES' : 'NO'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'QR Image URL',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(url.isEmpty ? rawUrl : url),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/my-bookings'),
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Back to My Bookings'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _normalizeQrUrl(String raw) {
    if (raw.isEmpty) return '';

    const backendOrigin = String.fromEnvironment(
      'API_ORIGIN',
      defaultValue: 'http://10.0.2.2:3000',
    );

    return raw.replaceAll('http://localhost:3000', backendOrigin);
  }

  static Widget _qrFallbackBox({required String message}) {
    return SizedBox(
      height: 260,
      width: 260,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_2, size: 56),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _friendlyQrError(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '').trim();
    if (text.isEmpty) {
      return 'Please try again in a moment.';
    }
    if (text.contains('404')) {
      return 'QR record was not found.';
    }
    return text;
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/features/owner/data/models/owner_wallet_models.dart';
import 'package:football/features/owner/presentation/providers/owner_providers.dart';

class OwnerWithdrawalRequestsPage extends ConsumerStatefulWidget {
  const OwnerWithdrawalRequestsPage({super.key});

  @override
  ConsumerState<OwnerWithdrawalRequestsPage> createState() =>
      _OwnerWithdrawalRequestsPageState();
}

class _OwnerWithdrawalRequestsPageState
    extends ConsumerState<OwnerWithdrawalRequestsPage> {
  final ScrollController _scrollController = ScrollController();

  static const List<String> _statuses = [
    'ALL',
    'PENDING',
    'APPROVED',
    'REJECTED',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ownerWithdrawalRequestsProvider.notifier).load(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      ref.read(ownerWithdrawalRequestsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerWithdrawalRequestsProvider);
    final notifier = ref.read(ownerWithdrawalRequestsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: notifier.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statuses.map((status) {
                    final selected =
                        (state.selectedStatus ?? 'ALL') == status;

                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        selected: selected,
                        label: Text(_statusLabel(status)),
                        onSelected: (_) {
                          notifier.setStatusFilter(
                            status == 'ALL' ? null : status,
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading && !state.hasRequests) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null && !state.hasRequests) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 52),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load withdrawal requests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.error!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: notifier.refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!state.isLoading && state.requests.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: notifier.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 90),
                        Icon(Icons.receipt_long_outlined, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No withdrawal requests found',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your submitted withdrawal requests will appear here.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: notifier.refresh,
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount:
                        state.requests.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= state.requests.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final request = state.requests[index];
                      return _RequestCard(request: request);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final OwnerWithdrawalRequestModel request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(request.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(
                  label: _statusLabel(request.status),
                  color: statusStyle.$1,
                  backgroundColor: statusStyle.$2,
                ),
                _Badge(
                  label: _money(request.amount),
                  color: Colors.green.shade800,
                  backgroundColor: Colors.green.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Withdrawal Request',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.receipt_long_outlined,
              title: 'Request ID',
              value: request.id,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Amount',
              value: _money(request.amount),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.payments_outlined,
              title: 'Method',
              value: _paymentMethodLabel(request.paymentMethod),
            ),
            if (request.accountDetails?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.phone_outlined,
                title: 'Account Details',
                value: request.accountDetails!.trim(),
              ),
            ],
            if (request.balanceBefore != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Balance Before',
                value: _money(request.balanceBefore!),
              ),
            ],
            if (request.balanceAfter != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Balance After',
                value: _money(request.balanceAfter!),
              ),
            ],
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.access_time_outlined,
              title: 'Created At',
              value: _formatDateTime(request.createdAt),
            ),
            if (request.processedAt != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.task_alt_outlined,
                title: 'Processed At',
                value: _formatDateTime(request.processedAt!),
              ),
            ],
            if (request.payoutId?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.link_outlined,
                title: 'Payout ID',
                value: request.payoutId!.trim(),
              ),
            ],
            if (request.rejectionReason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.error_outline,
                title: 'Rejection Reason',
                value: request.rejectionReason!.trim(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

(Color, Color) _statusStyle(String status) {
  switch (status.trim().toUpperCase()) {
    case 'PENDING':
      return (Colors.orange.shade800, Colors.orange.shade100);
    case 'APPROVED':
      return (Colors.green.shade800, Colors.green.shade100);
    case 'REJECTED':
      return (Colors.red.shade800, Colors.red.shade100);
    case 'PROCESSING':
      return (Colors.blue.shade800, Colors.blue.shade100);
    case 'COMPLETED':
      return (Colors.teal.shade800, Colors.teal.shade100);
    case 'FAILED':
      return (Colors.red.shade900, Colors.red.shade200);
    default:
      return (Colors.grey.shade800, Colors.grey.shade200);
  }
}

String _statusLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'ALL':
      return 'All';
    case 'PENDING':
      return 'Pending';
    case 'APPROVED':
      return 'Approved';
    case 'REJECTED':
      return 'Rejected';
    case 'PROCESSING':
      return 'Processing';
    case 'COMPLETED':
      return 'Completed';
    case 'FAILED':
      return 'Failed';
    default:
      return raw.replaceAll('_', ' ');
  }
}

String _paymentMethodLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'VODAFONE_CASH':
      return 'Vodafone Cash';
    case 'INSTAPAY':
      return 'InstaPay';
    case 'FAWRY_PAYOUT':
      return 'Fawry Payout';
    case 'MOBILE_WALLET':
      return 'Mobile Wallet';
    default:
      return raw.replaceAll('_', ' ');
  }
}

String _money(double value) {
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  return '$text EGP';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final yyyy = local.year.toString();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$dd/$mm/$yyyy $hour:$minute $suffix';
}
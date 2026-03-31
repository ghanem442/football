import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_withdrawal_request_model.dart';
import '../providers/admin_withdrawal_requests_provider.dart';

class AdminWithdrawalRequestsPage extends ConsumerStatefulWidget {
  const AdminWithdrawalRequestsPage({super.key});

  @override
  ConsumerState<AdminWithdrawalRequestsPage> createState() =>
      _AdminWithdrawalRequestsPageState();
}

class _AdminWithdrawalRequestsPageState
    extends ConsumerState<AdminWithdrawalRequestsPage> {
  static const List<String> _statuses = [
    'ALL',
    'PENDING',
    'APPROVED',
    'REJECTED',
  ];

  Future<void> _rejectRequest(AdminWithdrawalRequestModel request) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject Request'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter rejection reason',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = reasonController.text.trim();
                if (text.isEmpty) return;
                Navigator.of(dialogContext).pop(text);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (result == null || result.trim().isEmpty) return;

    try {
      await ref.read(adminWithdrawalRequestsProvider.notifier).rejectRequest(
            id: request.id,
            reason: result.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approveRequest(AdminWithdrawalRequestModel request) async {
    try {
      await ref
          .read(adminWithdrawalRequestsProvider.notifier)
          .approveRequest(request.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminWithdrawalRequestsProvider);
    final notifier = ref.read(adminWithdrawalRequestsProvider.notifier);

    final effectiveStatus = state.status ?? 'ALL';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading ? null : notifier.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statuses.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final status = _statuses[index];
                      final selected = effectiveStatus == status;

                      return ChoiceChip(
                        selected: selected,
                        label: Text(_statusLabel(status)),
                        onSelected: (_) {
                          notifier.setStatus(status == 'ALL' ? null : status);
                        },
                      );
                    },
                  ),
                ),
                if (state.hasFilters) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: notifier.clearFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Clear Filters'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading && state.requests.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null && state.requests.isEmpty) {
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
                        Icon(Icons.payments_outlined, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No withdrawal requests found',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: notifier.refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: state.requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final request = state.requests[index];
                      return _RequestCard(
                        request: request,
                        isProcessing: state.isProcessing,
                        onApprove: request.isPending
                            ? () => _approveRequest(request)
                            : null,
                        onReject: request.isPending
                            ? () => _rejectRequest(request)
                            : null,
                      );
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
  final AdminWithdrawalRequestModel request;
  final bool isProcessing;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _RequestCard({
    required this.request,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _statusStyle(request.status);

    final ownerName = request.owner?.name?.trim().isNotEmpty == true
        ? request.owner!.name!.trim()
        : 'Unknown owner';

    final ownerEmail = request.owner?.email?.trim().isNotEmpty == true
        ? request.owner!.email!.trim()
        : null;

    return Card(
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
                  color: badge.$1,
                  backgroundColor: badge.$2,
                ),
                _Badge(
                  label: _money(request.amount),
                  color: Colors.green.shade800,
                  backgroundColor: Colors.green.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ownerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (ownerEmail != null) ...[
              const SizedBox(height: 4),
              Text(
                ownerEmail,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.receipt_long_outlined,
              title: 'Request ID',
              value: request.id,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.payments_outlined,
              title: 'Payment Method',
              value: _paymentMethodLabel(request.paymentMethod),
            ),
            if (request.accountDetails?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Account Details',
                value: request.accountDetails!.trim(),
              ),
            ],
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.access_time_outlined,
              title: 'Created',
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
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isProcessing ? null : onReject,
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                      ),
                    ),
                  if (onReject != null && onApprove != null)
                    const SizedBox(width: 12),
                  if (onApprove != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isProcessing ? null : onApprove,
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                    ),
                ],
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

(Color, Color) _statusStyle(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'PENDING':
      return (Colors.orange.shade800, Colors.orange.shade100);
    case 'APPROVED':
      return (Colors.green.shade800, Colors.green.shade100);
    case 'REJECTED':
      return (Colors.red.shade800, Colors.red.shade100);
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
  final text = value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
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
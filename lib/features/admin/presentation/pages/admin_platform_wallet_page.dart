import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_platform_wallet_model.dart';
import '../providers/admin_platform_wallet_provider.dart';

class AdminPlatformWalletPage extends ConsumerStatefulWidget {
  const AdminPlatformWalletPage({super.key});

  @override
  ConsumerState<AdminPlatformWalletPage> createState() =>
      _AdminPlatformWalletPageState();
}

class _AdminPlatformWalletPageState
    extends ConsumerState<AdminPlatformWalletPage> {
  static const List<String> _types = [
    'ALL',
    'BOOKING_DEPOSIT',
    'BOOKING_REFUND',
    'ADMIN_WITHDRAWAL',
    'MANUAL_ADJUSTMENT',
  ];

  static const List<String> _mobileWalletProviders = [
    'VODAFONE',
    'ORANGE',
    'ETISALAT',
    'WE',
  ];

  final TextEditingController _bookingIdController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _bookingIdController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;

    if (pos.pixels >= pos.maxScrollExtent - 220) {
      _tryLoadMore();
    }
  }

  Future<void> _tryLoadMore() async {
    if (_loadingMore) return;

    final state = ref.read(adminPlatformWalletProvider);
    if (!state.pagination.hasMore) return;

    setState(() => _loadingMore = true);

    try {
      await ref.read(adminPlatformWalletProvider.notifier).loadMore();
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openWithdrawSheet(double currentBalance) async {
    final pageContext = context;
    final notifier = ref.read(adminPlatformWalletProvider.notifier);

    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final referenceController = TextEditingController();
    final phoneController = TextEditingController();
    final instapayController = TextEditingController();
    final accountHolderNameController = TextEditingController();

    String selectedMethod = 'MOBILE_WALLET';
    String selectedProvider = 'VODAFONE';
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            Future<void> submit() async {
              if (submitting) return;

              final amount = double.tryParse(amountController.text.trim());

              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid amount greater than 0'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (amount > currentBalance) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient platform wallet balance'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final accountHolderName =
                  accountHolderNameController.text.trim();
              if (accountHolderName.isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Account holder name is required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              String? phoneNumber;
              String? walletProvider;
              String? accountDetails;

              if (selectedMethod == 'MOBILE_WALLET') {
                phoneNumber = phoneController.text.trim();
                walletProvider = selectedProvider;

                if (phoneNumber.isEmpty) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              } else if (selectedMethod == 'INSTAPAY') {
                accountDetails = instapayController.text.trim();

                if (accountDetails.isEmpty) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text('InstaPay handle is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              setModalState(() => submitting = true);

              try {
                final message = await notifier.withdraw(
                  amount: amount,
                  description: descriptionController.text.trim(),
                  reference: referenceController.text.trim(),
                  payoutMethod: selectedMethod,
                  phoneNumber: phoneNumber,
                  walletProvider: walletProvider,
                  accountDetails: accountDetails,
                  accountHolderName: accountHolderName,
                );

                if (!mounted) return;

                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }

                if (!mounted) return;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                });
              } catch (e) {
                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (sheetContext.mounted) {
                  setModalState(() => submitting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Withdraw from Platform Wallet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text('Available balance: ${_money(currentBalance)}'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      suffixText: 'EGP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Withdrawal Method',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'MOBILE_WALLET',
                        child: Text('Mobile Wallet'),
                      ),
                      DropdownMenuItem(
                        value: 'INSTAPAY',
                        child: Text('InstaPay'),
                      ),
                    ],
                    onChanged: submitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setModalState(() {
                              selectedMethod = value;
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  if (selectedMethod == 'MOBILE_WALLET') ...[
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedProvider,
                      decoration: const InputDecoration(
                        labelText: 'Wallet Provider',
                        border: OutlineInputBorder(),
                      ),
                      items: _mobileWalletProviders
                          .map(
                            (provider) => DropdownMenuItem(
                              value: provider,
                              child: Text(_walletProviderLabel(provider)),
                            ),
                          )
                          .toList(),
                      onChanged: submitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setModalState(() {
                                selectedProvider = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (selectedMethod == 'INSTAPAY') ...[
                    TextFormField(
                      controller: instapayController,
                      decoration: const InputDecoration(
                        labelText: 'InstaPay Handle / Account Details',
                        hintText: 'name@instapay',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: accountHolderNameController,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Reference',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: submitting ? null : submit,
                    icon: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.account_balance_wallet_outlined),
                    label: Text(
                      submitting ? 'Processing...' : 'Withdraw Now',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    descriptionController.dispose();
    referenceController.dispose();
    phoneController.dispose();
    instapayController.dispose();
    accountHolderNameController.dispose();
  }

  Future<void> _searchByBookingId() async {
    await ref.read(adminPlatformWalletProvider.notifier).setBookingId(
          _bookingIdController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPlatformWalletProvider);
    final notifier = ref.read(adminPlatformWalletProvider.notifier);
    final wallet = state.wallet;
    final summary = state.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Wallet'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading ? null : notifier.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.isLoading && wallet == null && summary == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && wallet == null && summary == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 52),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load platform wallet',
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
                )
              : RefreshIndicator(
                  onRefresh: notifier.refresh,
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (state.error != null) ...[
                        _InlineErrorBanner(message: state.error!),
                        const SizedBox(height: 12),
                      ],
                      if (summary != null) ...[
                        _PrimaryBalanceCard(
                          currentBalance: summary.currentBalance,
                          totalRefundLiability: summary.totalRefundLiability,
                          onWithdraw: summary.currentBalance <= 0
                              ? null
                              : () => _openWithdrawSheet(summary.currentBalance),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Collected',
                                value: _money(summary.totalCollected),
                                subtitle: '${summary.counts.deposits} deposits',
                                icon: Icons.south_west_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Refunded',
                                value: _money(summary.totalRefunded),
                                subtitle: '${summary.counts.refunds} refunds',
                                icon: Icons.replay_circle_filled_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Withdrawn',
                                value: _money(summary.totalWithdrawn),
                                subtitle:
                                    '${summary.counts.withdrawals} withdrawals',
                                icon: Icons.north_east_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Net Flow',
                                value: _money(summary.netFlow),
                                subtitle:
                                    '${summary.counts.adjustments} adjustments',
                                icon: Icons.analytics_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (summary.totalAdjustments != 0)
                          _InfoCard(
                            title: 'Manual Adjustments',
                            value: _money(summary.totalAdjustments),
                            note:
                                'Used for manual balance corrections in the platform wallet.',
                          ),
                        const SizedBox(height: 18),
                      ] else if (wallet != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Available Platform Balance',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _money(wallet.balance),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This wallet receives booking deposits paid online by players.',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  onPressed: wallet.balance <= 0
                                      ? null
                                      : () => _openWithdrawSheet(wallet.balance),
                                  icon: const Icon(Icons.south_east_outlined),
                                  label: const Text('Withdraw'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _bookingIdController,
                        decoration: InputDecoration(
                          labelText: 'Filter by Booking ID',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: _searchByBookingId,
                            icon: const Icon(Icons.search),
                          ),
                        ),
                        onSubmitted: (_) => _searchByBookingId(),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _types.map((type) {
                            final isSelected = (state.type ?? 'ALL') == type;

                            return Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(end: 8),
                              child: ChoiceChip(
                                selected: isSelected,
                                label: Text(_transactionTypeLabel(type)),
                                onSelected: (_) {
                                  notifier.setType(type == 'ALL' ? null : type);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (state.hasFilters) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              _bookingIdController.clear();
                              notifier.clearFilters();
                            },
                            icon: const Icon(Icons.filter_alt_off_outlined),
                            label: const Text('Clear Filters'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Transactions',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                          ),
                          const Spacer(),
                          Text(
                            '${state.pagination.total} total',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (state.transactions.isEmpty && !state.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No platform transactions found',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        ...state.transactions.map(
                          (tx) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PlatformTransactionCard(transaction: tx),
                          ),
                        ),
                        if (_loadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (state.pagination.hasMore)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: TextButton(
                                onPressed: _tryLoadMore,
                                child: const Text('Load more'),
                              ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(child: Text('No more transactions')),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _PrimaryBalanceCard extends StatelessWidget {
  final double currentBalance;
  final double totalRefundLiability;
  final VoidCallback? onWithdraw;

  const _PrimaryBalanceCard({
    required this.currentBalance,
    required this.totalRefundLiability,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Platform Balance',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _money(currentBalance),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Refund liability: ${_money(totalRefundLiability)}',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This wallet receives booking deposits paid online by players and tracks refunds and admin withdrawals.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onWithdraw,
              icon: const Icon(Icons.south_east_outlined),
              label: const Text('Withdraw'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String note;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(note),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  final String message;

  const _InlineErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade700,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PlatformTransactionCard extends StatelessWidget {
  final AdminPlatformWalletTransactionModel transaction;

  const _PlatformTransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncoming = transaction.isIncoming;
    final color = isIncoming ? Colors.green : Colors.red;
    final sign = isIncoming ? '+' : '-';
    final icon =
        isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    final payoutMethod = (transaction.payoutMethod ?? '').trim().toUpperCase();
    final payoutDetails = transaction.payoutDetails ?? const <String, dynamic>{};

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          _transactionTitle(transaction),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDateTime(transaction.createdAt)),
            if (transaction.bookingId?.trim().isNotEmpty == true)
              Text('Booking ID: ${transaction.bookingId}'),
            if (transaction.reference?.trim().isNotEmpty == true)
              Text('Reference: ${transaction.reference}'),
            if (transaction.balanceBefore != null &&
                transaction.balanceAfter != null)
              Text(
                'Balance: ${_money(transaction.balanceBefore!)} → ${_money(transaction.balanceAfter!)}',
              ),
            if (payoutMethod.isNotEmpty)
              Text('Method: ${_payoutMethodLabel(payoutMethod)}'),
            if (payoutMethod == 'MOBILE_WALLET') ...[
              if ((payoutDetails['phoneNumber'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty)
                Text('Phone: ${payoutDetails['phoneNumber']}'),
              if ((payoutDetails['walletProvider'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty)
                Text(
                  'Provider: ${_walletProviderLabel(payoutDetails['walletProvider'].toString())}',
                ),
              if ((payoutDetails['accountHolderName'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty)
                Text('Account Name: ${payoutDetails['accountHolderName']}'),
            ],
            if (payoutMethod == 'INSTAPAY') ...[
              if ((payoutDetails['accountDetails'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty)
                Text('InstaPay: ${payoutDetails['accountDetails']}'),
              if ((payoutDetails['accountHolderName'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty)
                Text('Account Name: ${payoutDetails['accountHolderName']}'),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$sign${_money(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: transaction.id),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction ID copied')),
                  );
                }
              },
              child: const Text(
                'Copy ID',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _transactionTitle(AdminPlatformWalletTransactionModel tx) {
    if (tx.description?.trim().isNotEmpty == true) {
      return tx.description!.trim();
    }
    return _transactionTypeLabel(tx.type);
  }
}

String _transactionTypeLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'ALL':
      return 'All';
    case 'BOOKING_DEPOSIT':
      return 'Booking Deposit';
    case 'BOOKING_REFUND':
      return 'Booking Refund';
    case 'ADMIN_WITHDRAWAL':
      return 'Admin Withdrawal';
    case 'MANUAL_ADJUSTMENT':
      return 'Manual Adjustment';
    default:
      return raw.replaceAll('_', ' ');
  }
}

String _payoutMethodLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'MOBILE_WALLET':
      return 'Mobile Wallet';
    case 'INSTAPAY':
      return 'InstaPay';
    default:
      return raw.replaceAll('_', ' ');
  }
}

String _walletProviderLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'VODAFONE':
      return 'Vodafone Cash';
    case 'ORANGE':
      return 'Orange Cash';
    case 'ETISALAT':
      return 'Etisalat Cash';
    case 'WE':
      return 'WE Pay';
    default:
      return raw.replaceAll('_', ' ');
  }
}

String _money(double value) {
  final text = value.toStringAsFixed(
    value.truncateToDouble() == value ? 0 : 2,
  );
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
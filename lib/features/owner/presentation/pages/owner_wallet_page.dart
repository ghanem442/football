import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/features/owner/data/models/owner_wallet_models.dart';
import 'package:football/features/owner/presentation/providers/owner_providers.dart';

class OwnerWalletPage extends ConsumerStatefulWidget {
  const OwnerWalletPage({super.key});

  @override
  ConsumerState<OwnerWalletPage> createState() => _OwnerWalletPageState();
}

class _OwnerWalletPageState extends ConsumerState<OwnerWalletPage> {
  final ScrollController _scrollController = ScrollController();

  static const List<String> _transactionTypes = [
    'ALL',
    'DEPOSIT',
    'WITHDRAWAL',
    'REFUND',
    'BOOKING_PAYMENT',
    'COMMISSION_DEDUCTION',
    'CREDIT',
    'DEBIT',
    'PAYOUT',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ownerWalletTransactionsProvider.notifier).load(refresh: true);
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
      ref.read(ownerWalletTransactionsProvider.notifier).loadMore();
    }
  }

  double _calculateTotalIncoming(List<OwnerWalletTransactionModel> items) {
    return items
        .where((e) => e.isIncoming)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double _calculateTotalOutgoing(List<OwnerWalletTransactionModel> items) {
    return items
        .where((e) => e.isOutgoing)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Future<void> _showWithdrawalRequestSuccess(
    BuildContext context,
    OwnerWithdrawalRequestModel request,
    String? message,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.green.shade100,
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade700,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Withdrawal Request Submitted',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                (message?.trim().isNotEmpty ?? false)
                    ? message!.trim()
                    : 'Your withdrawal request is now pending admin approval.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _RequestSummaryRow(
                title: 'Request ID',
                value: request.id,
              ),
              const SizedBox(height: 8),
              _RequestSummaryRow(
                title: 'Amount',
                value: _money(request.amount),
              ),
              const SizedBox(height: 8),
              _RequestSummaryRow(
                title: 'Status',
                value: _withdrawStatusLabel(request.status),
              ),
              const SizedBox(height: 8),
              _RequestSummaryRow(
                title: 'Method',
                value: _paymentMethodLabel(request.paymentMethod),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openWithdrawSheet(OwnerWalletModel wallet) async {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    final walletProviderController = TextEditingController();
    final accountNameController = TextEditingController();

    String selectedMethod = 'VODAFONE_CASH';
    String selectedGateway = 'vodafone';
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            Future<void> submit() async {
              if (submitting) return;

              final amountText = amountController.text.trim();
              final amount = double.tryParse(amountText);

              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid amount greater than 0'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (amount > wallet.balance) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient online balance'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (selectedMethod == 'VODAFONE_CASH' ||
                  selectedMethod == 'MOBILE_WALLET' ||
                  selectedMethod == 'INSTAPAY' ||
                  selectedMethod == 'FAWRY_PAYOUT') {
                if (phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              setModalState(() => submitting = true);

              try {
                final repo = ref.read(ownerRepositoryProvider);

                final accountDetails = phoneController.text.trim();

                final request = OwnerCreateWithdrawalRequest(
                  amount: amount,
                  paymentMethod: selectedMethod,
                  accountDetails: accountDetails,
                  gateway: selectedGateway,
                  mobileWalletDetails:
                      (selectedMethod == 'VODAFONE_CASH' ||
                              selectedMethod == 'MOBILE_WALLET' ||
                              selectedMethod == 'INSTAPAY' ||
                              selectedMethod == 'FAWRY_PAYOUT')
                          ? OwnerWithdrawalMobileWalletDetails(
                              phoneNumber: phoneController.text.trim(),
                              walletProvider:
                                  walletProviderController.text.trim().isEmpty
                                      ? null
                                      : walletProviderController.text.trim(),
                              name: accountNameController.text.trim().isEmpty
                                  ? null
                                  : accountNameController.text.trim(),
                            )
                          : null,
                );

                final result = await repo.createWithdrawalRequest(
                  request: request,
                );

                if (!mounted) return;

                ref.invalidate(ownerWalletProvider);
                await ref
                    .read(ownerWalletTransactionsProvider.notifier)
                    .refresh();

                if (!mounted) return;

                Navigator.of(sheetContext).pop();

                await _showWithdrawalRequestSuccess(
                  context,
                  result.request,
                  result.message,
                );

                if (!mounted) return;

                ref.invalidate(ownerWalletProvider);
                await ref
                    .read(ownerWalletTransactionsProvider.notifier)
                    .refresh();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) {
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
                    'Request Withdrawal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text('Available online balance: ${_money(wallet.balance)}'),
                  const SizedBox(height: 8),
                  Text(
                    'This request will be reviewed by admin before approval.',
                    style: TextStyle(
                      color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
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
                      labelText: 'Method',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'VODAFONE_CASH',
                        child: Text('Vodafone Cash'),
                      ),
                      DropdownMenuItem(
                        value: 'INSTAPAY',
                        child: Text('InstaPay'),
                      ),
                      DropdownMenuItem(
                        value: 'FAWRY_PAYOUT',
                        child: Text('Fawry Payout'),
                      ),
                      DropdownMenuItem(
                        value: 'MOBILE_WALLET',
                        child: Text('Mobile Wallet'),
                      ),
                    ],
                    onChanged: submitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setModalState(() {
                              selectedMethod = value;
                              switch (value) {
                                case 'VODAFONE_CASH':
                                  selectedGateway = 'vodafone';
                                  break;
                                case 'INSTAPAY':
                                  selectedGateway = 'instapay';
                                  break;
                                case 'FAWRY_PAYOUT':
                                  selectedGateway = 'fawry';
                                  break;
                                default:
                                  selectedGateway = 'vodafone';
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number / Account Details',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: walletProviderController,
                    decoration: const InputDecoration(
                      labelText: 'Wallet Provider (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: accountNameController,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name (optional)',
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
                      submitting ? 'Submitting...' : 'Submit Withdrawal Request',
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
    phoneController.dispose();
    walletProviderController.dispose();
    accountNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(ownerWalletProvider);
    final txState = ref.watch(ownerWalletTransactionsProvider);
    final txNotifier = ref.read(ownerWalletTransactionsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Wallet'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(ownerWalletProvider);
              txNotifier.refresh();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: walletAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(ownerWalletProvider);
                    txNotifier.refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (wallet) {
          final totalIncoming = _calculateTotalIncoming(txState.transactions);
          final totalOutgoing = _calculateTotalOutgoing(txState.transactions);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withOpacity(.45),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Online Balance',
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
                              'This balance includes your share from online booking deposits only.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cash collected at the field is outside the system and is not included here.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: wallet.balance <= 0
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'You cannot request a withdrawal because your online balance is 0',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  : () => _openWithdrawSheet(wallet),
                              icon: const Icon(Icons.south_east_outlined),
                              label: const Text('Request Withdrawal'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Online Credits',
                            value: _money(totalIncoming),
                            icon: Icons.arrow_downward_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Withdrawals & Reversals',
                            value: _money(totalOutgoing),
                            icon: Icons.arrow_upward_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _transactionTypes.map((type) {
                          final isSelected =
                              (txState.selectedType ?? 'ALL') == type;
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ChoiceChip(
                              selected: isSelected,
                              label: Text(_transactionTypeLabel(type)),
                              onSelected: (_) => txNotifier.setTypeFilter(
                                type == 'ALL' ? null : type,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (txState.isLoading && !txState.hasTransactions) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (txState.error != null && !txState.hasTransactions) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48),
                              const SizedBox(height: 12),
                              Text(txState.error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: txNotifier.refresh,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!txState.isLoading && txState.transactions.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: txNotifier.refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: const [
                            SizedBox(height: 80),
                            Icon(Icons.receipt_long_outlined, size: 64),
                            SizedBox(height: 16),
                            Text(
                              'No wallet transactions yet',
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
                      onRefresh: txNotifier.refresh,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount:
                            txState.transactions.length +
                            (txState.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index >= txState.transactions.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final tx = txState.transactions[index];
                          return _TransactionCard(transaction: tx);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final OwnerWalletTransactionModel transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncoming = transaction.isIncoming;
    final icon = isIncoming
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _transactionTypeLabel(transaction.transactionPurpose ?? transaction.type),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.description?.trim().isNotEmpty == true
                        ? transaction.description!
                        : 'No description',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Balance: ${_money(transaction.balanceBefore)} → ${_money(transaction.balanceAfter)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (transaction.reference?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${transaction.reference!}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if ((transaction.actorRole?.trim().isNotEmpty ?? false) ||
                      (transaction.transactionPurpose?.trim().isNotEmpty ?? false)) ...[
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (transaction.actorRole?.trim().isNotEmpty ?? false)
                          transaction.actorRole!.trim(),
                        if (transaction.transactionPurpose?.trim().isNotEmpty ?? false)
                          transaction.transactionPurpose!.trim(),
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(transaction.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${isIncoming ? '+' : '-'}${_money(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isIncoming ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestSummaryRow extends StatelessWidget {
  final String title;
  final String value;

  const _RequestSummaryRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
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

String _withdrawStatusLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
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

String _transactionTypeLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'ALL':
      return 'All';
    case 'DEPOSIT':
      return 'Deposit';
    case 'WITHDRAWAL':
      return 'Withdrawal';
    case 'REFUND':
      return 'Refund';
    case 'BOOKING_PAYMENT':
      return 'Booking Payment';
    case 'COMMISSION_DEDUCTION':
      return 'Commission Deduction';
    case 'CREDIT':
      return 'Credit';
    case 'DEBIT':
      return 'Debit';
    case 'PAYOUT':
      return 'Payout';
    case 'OWNER_ONLINE_SHARE':
      return 'Online Deposit Share';
    case 'OWNER_WITHDRAWAL':
      return 'Withdrawal Request';
    case 'OWNER_WITHDRAWAL_REVERSAL':
      return 'Withdrawal Reversal';
    case 'REFUND_REVERSAL':
      return 'Refund Reversal';
    case 'PLAYER_REFUND':
      return 'Player Refund';
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_settings_provider.dart';

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _commissionController;
  late final TextEditingController _depositController;
  late final TextEditingController _refundWindowController;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _commissionController = TextEditingController();
    _depositController = TextEditingController();
    _refundWindowController = TextEditingController();
  }

  @override
  void dispose() {
    _commissionController.dispose();
    _depositController.dispose();
    _refundWindowController.dispose();
    super.dispose();
  }

  void _syncFormIfNeeded(AdminSettingsState state) {
    final settings = state.settings;
    if (_initialized || settings == null) return;

    _commissionController.text =
        _formatNumber(settings.globalCommissionPercentage);
    _depositController.text = _formatNumber(settings.depositPercentage);
    _refundWindowController.text =
        settings.cancellationRefundWindowHours.toString();

    _initialized = true;
  }

  String _formatNumber(num value) {
    final asDouble = value.toDouble();
    return asDouble.truncateToDouble() == asDouble
        ? asDouble.toStringAsFixed(0)
        : asDouble.toStringAsFixed(2);
  }

  String? _validatePercentage(String? value, {required String fieldName}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$fieldName is required';

    final parsed = double.tryParse(text);
    if (parsed == null) return '$fieldName must be a valid number';
    if (parsed < 0 || parsed > 100) {
      return '$fieldName must be between 0 and 100';
    }
    return null;
  }

  String? _validateHours(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Refund window is required';

    final parsed = int.tryParse(text);
    if (parsed == null) return 'Refund window must be a valid integer';
    if (parsed < 0) return 'Refund window must be 0 or more';
    return null;
  }

  Future<void> _save(AdminSettingsState state) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final notifier = ref.read(adminSettingsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    final commission = double.parse(_commissionController.text.trim());
    final deposit = double.parse(_depositController.text.trim());
    final refundHours = int.parse(_refundWindowController.text.trim());

    try {
      await notifier.saveSettings(
        globalCommissionPercentage: commission,
        depositPercentage: deposit,
        cancellationRefundWindowHours: refundHours,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Settings updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSettingsProvider);
    _syncFormIfNeeded(state);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading || state.isSaving
                ? null
                : () {
                    _initialized = false;
                    ref.read(adminSettingsProvider.notifier).refresh();
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.settings == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && state.settings == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 52),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load settings',
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
                      onPressed: () {
                        _initialized = false;
                        ref.read(adminSettingsProvider.notifier).refresh();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'System Configuration',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update global commission, deposit percentage, and cancellation refund window.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _commissionController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Global Commission Percentage',
                      hintText: '10',
                      suffixText: '%',
                    ),
                    validator: (value) => _validatePercentage(
                      value,
                      fieldName: 'Global commission percentage',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _depositController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Deposit Percentage',
                      hintText: '20',
                      suffixText: '%',
                    ),
                    validator: (value) => _validatePercentage(
                      value,
                      fieldName: 'Deposit percentage',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _refundWindowController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cancellation Refund Window',
                      hintText: '3',
                      suffixText: 'hours',
                    ),
                    validator: _validateHours,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: state.isSaving ? null : () => _save(state),
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      state.isSaving ? 'Saving...' : 'Save Settings',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
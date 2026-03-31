import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/features/owner/data/models/owner_bulk_slot_models.dart';
import 'package:football/features/owner/presentation/providers/owner_providers.dart';
import 'package:go_router/go_router.dart';

class OwnerBulkTimeSlotsPage extends ConsumerStatefulWidget {
  final String fieldId;
  final String fieldName;

  const OwnerBulkTimeSlotsPage({
    super.key,
    required this.fieldId,
    required this.fieldName,
  });

  @override
  ConsumerState<OwnerBulkTimeSlotsPage> createState() =>
      _OwnerBulkTimeSlotsPageState();
}

class _OwnerBulkTimeSlotsPageState
    extends ConsumerState<OwnerBulkTimeSlotsPage> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _startDate;
  late DateTime _endDate;

  final Map<int, bool> _selectedWeekdays = {
    0: true, // Sunday
    1: true, // Monday
    2: true, // Tuesday
    3: true, // Wednesday
    4: true, // Thursday
    5: true, // Friday
    6: true, // Saturday
  };

  final List<_TimeRangeFormItem> _timeRanges = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate;
    _timeRanges.add(_TimeRangeFormItem());
  }

  @override
  void dispose() {
    for (final item in _timeRanges) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(now) ? now : _startDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(DateTime.now().year + 2),
    );

    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    return '$dd/$mm/$yyyy';
  }

  int _daysInclusive(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  String _toApiTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  int _minutesOfDay(TimeOfDay time) => time.hour * 60 + time.minute;

  List<int> _selectedDaysOfWeek() {
    return _selectedWeekdays.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList()
      ..sort();
  }

  String _weekdayLabel(int value) {
    switch (value) {
      case 0:
        return 'Sun';
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      default:
        return value.toString();
    }
  }

  void _addTimeRange() {
    setState(() {
      _timeRanges.add(_TimeRangeFormItem());
    });
  }

  void _removeTimeRange(int index) {
    if (_timeRanges.length == 1) return;

    setState(() {
      final item = _timeRanges.removeAt(index);
      item.dispose();
    });
  }

  Future<void> _pickRangeStart(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _timeRanges[index].startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _timeRanges[index].startTime = picked;
      });
    }
  }

  Future<void> _pickRangeEnd(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _timeRanges[index].endTime ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _timeRanges[index].endTime = picked;
      });
    }
  }

  String? _validatePrice(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Price is required';

    final parsed = double.tryParse(text);
    if (parsed == null) return 'Price must be a valid number';
    if (parsed <= 0) return 'Price must be greater than 0';
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final selectedDays = _selectedDaysOfWeek();
    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ranges = <BulkTimeRangeItem>[];

    for (final item in _timeRanges) {
      if (item.startTime == null || item.endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select start and end time for every range'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_minutesOfDay(item.startTime!) >= _minutesOfDay(item.endTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Every start time must be before end time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final price = double.tryParse(item.priceController.text.trim());
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Every price must be greater than 0'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ranges.add(
        BulkTimeRangeItem(
          startTime: _toApiTime(item.startTime!),
          endTime: _toApiTime(item.endTime!),
          price: price,
        ),
      );
    }

    final repo = ref.read(ownerRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _submitting = true);

    try {
      final result = await repo.bulkCreateTimeSlots(
        fieldId: widget.fieldId,
        startDate: _startDate,
        endDate: _endDate,
        daysOfWeek: selectedDays,
        timeRanges: ranges,
      );

      if (!mounted) return;

      final message = result.message?.trim().isNotEmpty == true
          ? result.message!
          : 'Created ${result.count} slots successfully';

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '$message\n${result.dates} day(s) × ${result.timeRanges} range(s) = ${result.count} slot(s)',
          ),
        ),
      );

      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDays = _selectedDaysOfWeek();
    final totalDays = _daysInclusive(_startDate, _endDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Create Slots'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.fieldName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create multiple recurring time slots across a date range.',
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.play_arrow_outlined),
                  title: const Text('Start Date'),
                  subtitle: Text(_formatDate(_startDate)),
                  trailing: TextButton(
                    onPressed: _submitting ? null : _pickStartDate,
                    child: const Text('Change'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.stop_outlined),
                  title: const Text('End Date'),
                  subtitle: Text(_formatDate(_endDate)),
                  trailing: TextButton(
                    onPressed: _submitting ? null : _pickEndDate,
                    child: const Text('Change'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Days of Week',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  return _DayChip(
                    label: _weekdayLabel(index),
                    value: _selectedWeekdays[index] ?? false,
                    onChanged: _submitting
                        ? null
                        : (v) => setState(() {
                              _selectedWeekdays[index] = v;
                            }),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Time Ranges',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _addTimeRange,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Range'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(_timeRanges.length, (index) {
                final item = _timeRanges[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Range ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              if (_timeRanges.length > 1)
                                IconButton(
                                  tooltip: 'Remove',
                                  onPressed: _submitting
                                      ? null
                                      : () => _removeTimeRange(index),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.schedule_outlined),
                              title: const Text('Start Time'),
                              subtitle: Text(
                                item.startTime == null
                                    ? 'Not selected'
                                    : item.startTime!.format(context),
                              ),
                              trailing: TextButton(
                                onPressed: _submitting
                                    ? null
                                    : () => _pickRangeStart(index),
                                child: const Text('Select'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.schedule_outlined),
                              title: const Text('End Time'),
                              subtitle: Text(
                                item.endTime == null
                                    ? 'Not selected'
                                    : item.endTime!.format(context),
                              ),
                              trailing: TextButton(
                                onPressed: _submitting
                                    ? null
                                    : () => _pickRangeEnd(index),
                                child: const Text('Select'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: item.priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              hintText: '150',
                              suffixText: 'EGP',
                              border: OutlineInputBorder(),
                            ),
                            validator: _validatePrice,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text(
                    'Preview',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Date range: $totalDays day(s)\nSelected weekdays: ${selectedDays.length}\nTime ranges: ${_timeRanges.length}',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_motion_outlined),
                label: Text(
                  _submitting ? 'Please wait...' : 'Create Bulk Slots',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _submitting ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(height: 12),
              Text(
                'Note: bulk creation is all-or-nothing. If any slot overlaps with an existing slot, the whole request will fail.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeRangeFormItem {
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  final TextEditingController priceController = TextEditingController();

  void dispose() {
    priceController.dispose();
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _DayChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: value,
      label: Text(label),
      onSelected: onChanged,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:football/features/bookings/data/models/time_slot_model.dart';
import 'package:football/features/owner/presentation/providers/owner_providers.dart';
import 'package:go_router/go_router.dart';

class AddEditTimeSlotPage extends ConsumerStatefulWidget {
  final String fieldId;
  final String fieldName;
  final TimeSlotModel? slot;
  final DateTime? initialDate;

  const AddEditTimeSlotPage({
    super.key,
    required this.fieldId,
    required this.fieldName,
    this.slot,
    this.initialDate,
  });

  @override
  ConsumerState<AddEditTimeSlotPage> createState() =>
      _AddEditTimeSlotPageState();
}

class _AddEditTimeSlotPageState extends ConsumerState<AddEditTimeSlotPage> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _submitting = false;

  bool get _isEdit => widget.slot != null;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedDate = widget.slot?.date ??
        widget.initialDate ??
        DateTime(now.year, now.month, now.day);

    if (widget.slot != null) {
      _startTime = TimeOfDay(
        hour: widget.slot!.start.hour,
        minute: widget.slot!.start.minute,
      );
      _endTime = TimeOfDay(
        hour: widget.slot!.end.hour,
        minute: widget.slot!.end.minute,
      );
      _priceController.text = widget.slot!.priceAsDouble ==
              widget.slot!.priceAsDouble.truncateToDouble()
          ? widget.slot!.priceAsDouble.toStringAsFixed(0)
          : widget.slot!.priceAsDouble.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  String _toApiTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  int _minutesOfDay(TimeOfDay time) => time.hour * 60 + time.minute;

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
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start time and end time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_minutesOfDay(_startTime!) >= _minutesOfDay(_endTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start time must be before end time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(ownerRepositoryProvider);
    final price = double.parse(_priceController.text.trim());

    setState(() => _submitting = true);

    try {
      if (_isEdit) {
        await repo.updateTimeSlot(
          slotId: widget.slot!.id,
          date: _selectedDate,
          startTime: _toApiTime(_startTime!),
          endTime: _toApiTime(_endTime!),
          price: price,
        );
      } else {
        await repo.createTimeSlot(
          fieldId: widget.fieldId,
          date: _selectedDate,
          startTime: _toApiTime(_startTime!),
          endTime: _toApiTime(_endTime!),
          price: price,
        );
      }

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Time slot updated successfully'
                : 'Time slot created successfully',
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
    final title = _isEdit ? 'Edit Time Slot' : 'Add Time Slot';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
              Text(
                _isEdit
                    ? 'Update the selected slot details.'
                    : 'Create a new available time slot for this field.',
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Date'),
                  subtitle: Text(
                    '${_selectedDate.day.toString().padLeft(2, '0')}/'
                    '${_selectedDate.month.toString().padLeft(2, '0')}/'
                    '${_selectedDate.year}',
                  ),
                  trailing: TextButton(
                    onPressed: _submitting ? null : _pickDate,
                    child: const Text('Change'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Start Time'),
                  subtitle: Text(
                    _startTime == null
                        ? 'Not selected'
                        : _startTime!.format(context),
                  ),
                  trailing: TextButton(
                    onPressed: _submitting ? null : _pickStartTime,
                    child: const Text('Select'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('End Time'),
                  subtitle: Text(
                    _endTime == null ? 'Not selected' : _endTime!.format(context),
                  ),
                  trailing: TextButton(
                    onPressed: _submitting ? null : _pickEndTime,
                    child: const Text('Select'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: '150',
                  suffixText: 'EGP',
                  border: OutlineInputBorder(),
                ),
                validator: _validatePrice,
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
                    : Icon(_isEdit ? Icons.save_outlined : Icons.add),
                label: Text(
                  _submitting
                      ? 'Please wait...'
                      : (_isEdit ? 'Save Changes' : 'Create Slot'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _submitting ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
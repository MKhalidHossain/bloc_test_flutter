import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';

/// Bottom sheet form for creating a booking.
class CreateBookingSheet extends StatefulWidget {
  const CreateBookingSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<BookingBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const CreateBookingSheet(),
      ),
    );
  }

  @override
  State<CreateBookingSheet> createState() => _CreateBookingSheetState();
}

class _CreateBookingSheetState extends State<CreateBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _serviceController = TextEditingController(text: 'svc_1');
  final _doctorController = TextEditingController(text: 'dr_1');
  DateTime _bookingTime = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _serviceController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _bookingTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_bookingTime),
    );
    if (time == null) return;
    setState(() {
      _bookingTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<BookingBloc>().add(CreateBookingRequested(
          serviceId: _serviceController.text.trim(),
          bookingTime: _bookingTime.toIso8601String(),
          doctorId: _doctorController.text.trim(),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Booking',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serviceController,
              decoration: const InputDecoration(labelText: 'Service ID'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _doctorController,
              decoration: const InputDecoration(labelText: 'Doctor ID'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Booking time'),
              subtitle: Text(
                DateFormat('EEE, d MMM yyyy • HH:mm').format(_bookingTime),
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: const Text('Create booking'),
            ),
          ],
        ),
      ),
    );
  }
}

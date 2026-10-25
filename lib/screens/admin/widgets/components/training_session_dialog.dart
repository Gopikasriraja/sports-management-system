import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../models/training_session_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/training_session_provider.dart';

class TrainingSessionDialog extends StatefulWidget {
  final TrainingSession? session;

  const TrainingSessionDialog({super.key, this.session});

  @override
  State<TrainingSessionDialog> createState() => _TrainingSessionDialogState();
}

class _TrainingSessionDialogState extends State<TrainingSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sportController;
  late final TextEditingController _teamController;
  late final TextEditingController _coachController;
  late final TextEditingController _venueController;
  late final TextEditingController _notesController;
  late DateTime _startsAt;
  late DateTime _endsAt;
  late String _status;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    _sportController = TextEditingController(text: session?.sport ?? '');
    _teamController = TextEditingController(text: session?.team ?? '');
    _coachController = TextEditingController(text: session?.coach ?? '');
    _venueController = TextEditingController(text: session?.venue ?? '');
    _notesController = TextEditingController(text: session?.notes ?? '');
    final now = DateTime.now();
    _startsAt = session?.startsAt ?? DateTime(now.year, now.month, now.day, 9);
    _endsAt = session?.endsAt ?? _startsAt.add(const Duration(hours: 1));
    _status = session?.status ?? 'Scheduled';
  }

  @override
  void dispose() {
    _sportController.dispose();
    _teamController.dispose();
    _coachController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime initialDate) => showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );

  Future<TimeOfDay?> _pickTime(DateTime initialDate) => showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );

  DateTime _withTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  Future<void> _selectStartsAt() async {
    final date = await _pickDate(_startsAt);
    if (date == null || !mounted) return;
    final time = await _pickTime(_startsAt);
    if (time == null || !mounted) return;
    setState(() {
      _startsAt = _withTime(date, time);
      if (!_endsAt.isAfter(_startsAt)) {
        _endsAt = _startsAt.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _selectEndsAt() async {
    final date = await _pickDate(_endsAt);
    if (date == null || !mounted) return;
    final time = await _pickTime(_endsAt);
    if (time == null || !mounted) return;
    setState(() => _endsAt = _withTime(date, time));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>().currentUser;
    if (auth == null ||
        !AppRoles.canManageTrainingSessions(auth.role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not authorized to manage schedules.')),
      );
      return;
    }

    final session = TrainingSession(
      sessionId: widget.session?.sessionId ?? '',
      sport: _sportController.text,
      team: _teamController.text,
      coach: _coachController.text,
      venue: _venueController.text,
      startsAt: _startsAt,
      endsAt: _endsAt,
      notes: _notesController.text,
      status: _status,
    );
    final provider = context.read<TrainingSessionProvider>();
    final saved = await provider.saveSession(session, actorRole: auth.role);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not save the session.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = MaterialLocalizations.of(context);
    final dateText = DateTime(
      _startsAt.year,
      _startsAt.month,
      _startsAt.day,
    );
    final endDateText = DateTime(_endsAt.year, _endsAt.month, _endsAt.day);

    return AlertDialog(
      title: Text(widget.session == null ? 'Schedule training' : 'Edit training'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _sportController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Sport',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a sport.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teamController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Team (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _coachController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Coach',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a coach name.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _venueController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a training venue.'
                      : null,
                ),
                const SizedBox(height: 12),
                _DateTimePicker(
                  label: 'Starts',
                  value:
                      '${dateFormat.formatMediumDate(dateText)} · ${dateFormat.formatTimeOfDay(TimeOfDay.fromDateTime(_startsAt))}',
                  onPressed: _selectStartsAt,
                ),
                const SizedBox(height: 8),
                _DateTimePicker(
                  label: 'Ends',
                  value:
                      '${dateFormat.formatMediumDate(endDateText)} · ${dateFormat.formatTimeOfDay(TimeOfDay.fromDateTime(_endsAt))}',
                  onPressed: _selectEndsAt,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const ['Scheduled', 'Completed', 'Cancelled']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                if (_endsAt.isBefore(_startsAt) ||
                    _endsAt.isAtSameMomentAs(_startsAt)) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'End time must be after start time.',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.session == null ? 'Create' : 'Save changes'),
        ),
      ],
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onPressed;

  const _DateTimePicker({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text('$label: $value')),
      TextButton(onPressed: onPressed, child: const Text('Change')),
    ],
  );
}

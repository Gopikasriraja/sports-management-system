import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../models/event_model.dart';
import '../../../../../../providers/event_provider.dart';
import 'package:intl/intl.dart';

class AddEditEventDialog extends StatefulWidget {
  final EventModel? event;

  const AddEditEventDialog({super.key, this.event});

  @override
  State<AddEditEventDialog> createState() => _AddEditEventDialogState();
}

class _AddEditEventDialogState extends State<AddEditEventDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _venueController;
  late TextEditingController _organizerController;
  late TextEditingController _departmentController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxParticipantsController;
  late TextEditingController _bannerImageController;

  String _category = 'Cricket';
  String _eventType = 'Tournament';
  String _status = 'Upcoming';
  bool _registrationRequired = true;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  final List<String> _categories = [
    'Cricket', 'Football', 'Basketball', 'Volleyball', 'Athletics',
    'Badminton', 'Chess', 'Table Tennis', 'Kabaddi', 'Hockey', 'Yoga', 'Sports Day', 'Other'
  ];
  final List<String> _types = ['Match', 'Tournament', 'Selection', 'Practice', 'Friendly'];
  final List<String> _statuses = ['Upcoming', 'Ongoing', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _venueController = TextEditingController(text: widget.event?.venue ?? '');
    _organizerController = TextEditingController(text: widget.event?.organizer ?? '');
    _departmentController = TextEditingController(text: widget.event?.department ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _maxParticipantsController = TextEditingController(text: widget.event?.maxParticipants.toString() ?? '100');
    _bannerImageController = TextEditingController(text: widget.event?.bannerImage ?? '');

    if (widget.event != null) {
      _category = widget.event!.category;
      _eventType = widget.event!.eventType;
      _status = widget.event!.status;
      _registrationRequired = widget.event!.registrationRequired;
      _startDate = widget.event!.startDate;
      _endDate = widget.event!.endDate;
      try {
        final stParts = widget.event!.startTime.split(':');
        _startTime = TimeOfDay(hour: int.parse(stParts[0]), minute: int.parse(stParts[1]));
        final etParts = widget.event!.endTime.split(':');
        _endTime = TimeOfDay(hour: int.parse(etParts[0]), minute: int.parse(etParts[1]));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _organizerController.dispose();
    _departmentController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _bannerImageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      String formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      
      final event = EventModel(
        eventId: widget.event?.eventId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        category: _category,
        eventType: _eventType,
        startDate: _startDate,
        endDate: _endDate,
        startTime: formatTime(_startTime),
        endTime: formatTime(_endTime),
        venue: _venueController.text,
        organizer: _organizerController.text,
        department: _departmentController.text,
        description: _descriptionController.text,
        maxParticipants: int.tryParse(_maxParticipantsController.text) ?? 0,
        registrationRequired: _registrationRequired,
        bannerImage: _bannerImageController.text,
        status: _status,
      );

      final provider = Provider.of<EventProvider>(context, listen: false);
      final success = await provider.saveEvent(event);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Error saving event')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.event == null ? 'Create New Event' : 'Edit Event',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(labelText: 'Event Name', border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (v) => setState(() => _category = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _eventType,
                              decoration: const InputDecoration(labelText: 'Event Type', border: OutlineInputBorder()),
                              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setState(() => _eventType = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder()),
                                child: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, true),
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Start Time', border: OutlineInputBorder()),
                                child: Text(_startTime.format(context)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'End Date', border: OutlineInputBorder()),
                                child: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, false),
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'End Time', border: OutlineInputBorder()),
                                child: Text(_endTime.format(context)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _venueController,
                              decoration: const InputDecoration(labelText: 'Venue', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _organizerController,
                              decoration: const InputDecoration(labelText: 'Organizer', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _departmentController,
                              decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _maxParticipantsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Max Participants (0 = Unlimited)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Registration Required'),
                              value: _registrationRequired,
                              onChanged: (v) => setState(() => _registrationRequired = v!),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                              items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _status = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bannerImageController,
                        decoration: const InputDecoration(labelText: 'Banner Image URL (Leave empty for default)', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: isDark ? Colors.black : Colors.white),
                  child: const Text('Save Event'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

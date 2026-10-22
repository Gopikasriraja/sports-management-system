import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../core/validation/attendance_rules.dart';
import '../../../../models/attendance_model.dart';
import '../../../../models/attendance_session_model.dart';
import '../../../../models/student_model.dart';
import '../../../../models/team_model.dart';
import '../../../../providers/attendance_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/team_provider.dart';

class AttendanceManagementView extends StatefulWidget {
  const AttendanceManagementView({super.key});

  @override
  State<AttendanceManagementView> createState() =>
      _AttendanceManagementViewState();
}

class _AttendanceManagementViewState extends State<AttendanceManagementView> {
  String? _selectedSessionId;
  String _search = '';
  DateTime? _sessionDateFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final actor = context.read<AuthProvider>().currentUser;
      if (actor == null || !AppRoles.canManageAttendance(actor.role)) return;
      context.read<AttendanceProvider>().watchSessions(
        actorUid: actor.uid,
        actorRole: actor.role,
      );
    });
  }

  Future<void> _openSessionEditor({AttendanceSessionModel? existing}) async {
    final actor = context.read<AuthProvider>().currentUser;
    if (actor == null || !AppRoles.canManageAttendance(actor.role)) return;
    final session = await showDialog<AttendanceSessionModel>(
      context: context,
      builder: (_) => _CreateAttendanceSessionDialog(initialSession: existing),
    );
    if (session == null || !mounted) return;
    final provider = context.read<AttendanceProvider>();
    final saved = existing == null
        ? await provider.createSession(
            session,
            actorUid: actor.uid,
            actorRole: actor.role,
            actorName: actor.name,
          )
        : await provider.updateSession(
            session,
            actorUid: actor.uid,
            actorRole: actor.role,
          );
    if (!mounted) return;
    _showMessage(
      saved
          ? existing == null
                ? 'Attendance session created.'
                : 'Attendance session updated.'
          : 'Could not save session: ${provider.errorMessage ?? 'Unknown error'}',
      success: saved,
    );
  }

  Future<void> _chooseSessionDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _sessionDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _sessionDateFilter = selected);
  }

  Future<void> _selectSession(AttendanceSessionModel session) async {
    final actor = context.read<AuthProvider>().currentUser;
    if (actor == null) return;
    setState(() {
      _selectedSessionId = session.sessionId;
      _search = '';
    });
    final provider = context.read<AttendanceProvider>();
    provider.watchSessionAttendance(
      session.sessionId,
      actorUid: actor.uid,
      actorRole: actor.role,
    );
    try {
      await provider.loadEligibleStudents(
        session.sessionId,
        actorUid: actor.uid,
        actorRole: actor.role,
      );
    } catch (_) {
      // The provider stores the operation error for the visible error state.
    }
  }

  void _showMessage(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _changeSessionStatus(
    AttendanceSessionModel session,
    String status,
  ) async {
    final actor = context.read<AuthProvider>().currentUser;
    if (actor == null) return;
    final provider = context.read<AttendanceProvider>();
    final updated = await provider.updateSessionStatus(
      session.sessionId,
      status,
      actorUid: actor.uid,
      actorRole: actor.role,
    );
    if (!mounted) return;
    _showMessage(
      updated
          ? 'Session marked $status.'
          : 'Could not update session: ${provider.errorMessage ?? 'Unknown error'}',
      success: updated,
    );
  }

  Future<void> _markStudent(
    AttendanceSessionModel session,
    StudentModel student,
    String status,
    AttendanceModel? previous,
  ) async {
    var reason = '';
    if (previous != null && previous.status != status) {
      final controller = TextEditingController();
      final enteredReason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Correct attendance'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for correction',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (enteredReason == null || enteredReason.trim().isEmpty) return;
      reason = enteredReason.trim();
    }
    if (!mounted) return;
    final actor = context.read<AuthProvider>().currentUser;
    if (actor == null) return;
    final provider = context.read<AttendanceProvider>();
    final saved = await provider.markAttendance(
      sessionId: session.sessionId,
      student: student,
      status: status,
      actorUid: actor.uid,
      actorRole: actor.role,
      correctionReason: reason,
    );
    if (!mounted) return;
    _showMessage(
      saved
          ? previous == null
                ? 'Attendance recorded.'
                : 'Attendance correction saved.'
          : 'Attendance was not saved: ${provider.errorMessage ?? 'Unknown error'}',
      success: saved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final actor = context.watch<AuthProvider>().currentUser;
    final provider = context.watch<AttendanceProvider>();
    if (actor == null || !AppRoles.canManageAttendance(actor.role)) {
      return const Center(child: Text('Attendance access is unavailable.'));
    }
    final selected = provider.sessions
        .where((session) => session.sessionId == _selectedSessionId)
        .firstOrNull;
    final filteredSessions = provider.sessions.where((session) {
      final date = _sessionDateFilter;
      return date == null ||
          (session.date.year == date.year &&
              session.date.month == date.month &&
              session.date.day == date.day);
    }).toList();
    final recordsByStudent = {
      for (final record in provider.attendanceLogs) record.studentId: record,
    };
    final eligible = provider.eligibleStudents.where((student) {
      final search = _search.trim().toLowerCase();
      return search.isEmpty ||
          student.name.toLowerCase().contains(search) ||
          student.registerNumber.toLowerCase().contains(search) ||
          student.department.toLowerCase().contains(search);
    }).toList();
    final summary = AttendanceRules.summarize(
      provider.attendanceLogs,
      selected == null ? const [] : [selected],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance sessions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create a session, then record each eligible student explicitly.',
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: () => _openSessionEditor(),
              icon: const Icon(Icons.add),
              label: const Text('New session'),
            ),
            OutlinedButton.icon(
              onPressed: _chooseSessionDate,
              icon: const Icon(Icons.filter_alt_outlined),
              label: Text(
                _sessionDateFilter == null
                    ? 'Filter by date'
                    : DateFormat('d MMM yyyy').format(_sessionDateFilter!),
              ),
            ),
            if (_sessionDateFilter != null)
              IconButton(
                tooltip: 'Clear date filter',
                onPressed: () => setState(() => _sessionDateFilter = null),
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (provider.errorMessage != null)
          _InlineNotice(
            message: provider.errorMessage!,
            isError: true,
            onRetry: () => provider.watchSessions(
              actorUid: actor.uid,
              actorRole: actor.role,
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sessionsPanel = _SessionsPanel(
                sessions: filteredSessions,
                selectedId: _selectedSessionId,
                isLoading: provider.isLoading && provider.sessions.isEmpty,
                onSelect: _selectSession,
                onChangeStatus: _changeSessionStatus,
              );
              final detail = selected == null
                  ? const _EmptyPanel(
                      message:
                          'Choose a session to view its roster and records.',
                    )
                  : _SessionDetail(
                      session: selected,
                      students: eligible,
                      recordsByStudent: recordsByStudent,
                      isLoading: provider.isLoading,
                      search: _search,
                      onSearchChanged: (value) =>
                          setState(() => _search = value),
                      summary: summary,
                      onMark: (student, status, previous) =>
                          _markStudent(selected, student, status, previous),
                      onChangeStatus: (status) =>
                          _changeSessionStatus(selected, status),
                      onEdit: () => _openSessionEditor(existing: selected),
                    );
              if (constraints.maxWidth < 800) {
                return Column(
                  children: [
                    SizedBox(height: 210, child: sessionsPanel),
                    const SizedBox(height: 12),
                    Expanded(child: detail),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 300, child: sessionsPanel),
                  const SizedBox(width: 16),
                  Expanded(child: detail),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SessionsPanel extends StatelessWidget {
  final List<AttendanceSessionModel> sessions;
  final String? selectedId;
  final bool isLoading;
  final ValueChanged<AttendanceSessionModel> onSelect;
  final void Function(AttendanceSessionModel, String) onChangeStatus;

  const _SessionsPanel({
    required this.sessions,
    required this.selectedId,
    required this.isLoading,
    required this.onSelect,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: isLoading
        ? const Center(child: CircularProgressIndicator())
        : sessions.isEmpty
        ? const _EmptyPanel(message: 'No attendance sessions yet.')
        : ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final isSelected = session.sessionId == selectedId;
              return ListTile(
                selected: isSelected,
                title: Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${DateFormat('d MMM yyyy').format(session.date)} · ${session.sport}\n${session.status}',
                ),
                isThreeLine: true,
                onTap: () => onSelect(session),
                trailing: session.status == 'scheduled'
                    ? PopupMenuButton<String>(
                        tooltip: 'Manage session',
                        onSelected: (status) => onChangeStatus(session, status),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'active',
                            child: Text('Start session'),
                          ),
                          PopupMenuItem(
                            value: 'cancelled',
                            child: Text('Cancel session'),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert),
                      )
                    : session.status == 'active'
                    ? PopupMenuButton<String>(
                        tooltip: 'Complete or cancel session',
                        onSelected: (status) => onChangeStatus(session, status),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'completed',
                            child: Text('Complete'),
                          ),
                          PopupMenuItem(
                            value: 'cancelled',
                            child: Text('Cancel session'),
                          ),
                        ],
                      )
                    : null,
              );
            },
          ),
  );
}

class _SessionDetail extends StatelessWidget {
  final AttendanceSessionModel session;
  final List<StudentModel> students;
  final Map<String, AttendanceModel> recordsByStudent;
  final bool isLoading;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final AttendanceSummary summary;
  final void Function(StudentModel, String, AttendanceModel?) onMark;
  final ValueChanged<String> onChangeStatus;
  final VoidCallback onEdit;

  const _SessionDetail({
    required this.session,
    required this.students,
    required this.recordsByStudent,
    required this.isLoading,
    required this.search,
    required this.onSearchChanged,
    required this.summary,
    required this.onMark,
    required this.onChangeStatus,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final canMark = session.status == 'active';
    final count =
        summary.present + summary.absent + summary.late + summary.excused;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  session.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (session.status == 'scheduled')
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => onChangeStatus('active'),
                        child: const Text('Start session'),
                      ),
                      TextButton(
                        onPressed: () => onChangeStatus('cancelled'),
                        child: const Text('Cancel'),
                      ),
                    ],
                  )
                else if (session.status == 'active')
                  OutlinedButton(
                    onPressed: () => onChangeStatus('completed'),
                    child: const Text('Complete session'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${session.sport}${session.teamName.isEmpty ? '' : ' · ${session.teamName}'}'
              ' · ${DateFormat('d MMM yyyy').format(session.date)}'
              ' · ${session.startTime}–${session.endTime} · ${session.venue}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                Text('Present ${summary.present}'),
                Text('Absent ${summary.absent}'),
                Text('Late ${summary.late}'),
                Text('Excused ${summary.excused}'),
                Text('${summary.percentage.toStringAsFixed(1)}% attendance'),
                Text('$count recorded'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Rate = Present + Late divided by Present + Late + Absent. '
              'Excused and unmarked students are excluded.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search eligible students',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : students.isEmpty
                  ? const _EmptyPanel(
                      message: 'No active eligible students are available.',
                    )
                  : ListView.separated(
                      itemCount: students.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final previous = recordsByStudent[student.studentId];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(student.name),
                          subtitle: Text(
                            '${student.registerNumber} · ${student.department}',
                          ),
                          trailing: canMark
                              ? PopupMenuButton<String>(
                                  tooltip: previous == null
                                      ? 'Mark attendance'
                                      : 'Correct attendance',
                                  onSelected: (status) =>
                                      onMark(student, status, previous),
                                  itemBuilder: (_) => AttendanceRules.statuses
                                      .map(
                                        (status) => PopupMenuItem(
                                          value: status,
                                          child: Text(status),
                                        ),
                                      )
                                      .toList(),
                                  child: Chip(
                                    label: Text(
                                      previous?.status ?? 'Not marked',
                                    ),
                                  ),
                                )
                              : Chip(
                                  label: Text(previous?.status ?? 'Not marked'),
                                ),
                        );
                      },
                    ),
            ),
            if (!canMark)
              const Text(
                'Attendance can only be entered while the session is active.',
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateAttendanceSessionDialog extends StatefulWidget {
  final AttendanceSessionModel? initialSession;

  const _CreateAttendanceSessionDialog({this.initialSession});

  @override
  State<_CreateAttendanceSessionDialog> createState() =>
      _CreateAttendanceSessionDialogState();
}

class _CreateAttendanceSessionDialogState
    extends State<_CreateAttendanceSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _sport = TextEditingController();
  final _startTime = TextEditingController(text: '09:00');
  final _endTime = TextEditingController(text: '10:00');
  final _venue = TextEditingController();
  DateTime _date = DateTime.now();
  TeamModel? _team;

  @override
  void initState() {
    super.initState();
    final session = widget.initialSession;
    if (session == null) return;
    _title.text = session.title;
    _sport.text = session.sport;
    _startTime.text = session.startTime;
    _endTime.text = session.endTime;
    _venue.text = session.venue;
    _date = session.date;
    _team = context
        .read<TeamProvider>()
        .teams
        .where((team) => team.teamId == session.teamId)
        .firstOrNull;
  }

  @override
  void dispose() {
    _title.dispose();
    _sport.dispose();
    _startTime.dispose();
    _endTime.dispose();
    _venue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teams = context.watch<TeamProvider>().teams;
    return AlertDialog(
      title: Text(
        widget.initialSession == null
            ? 'Create attendance session'
            : 'Edit attendance session',
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Session title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a session title.'
                      : null,
                ),
                TextFormField(
                  controller: _sport,
                  decoration: const InputDecoration(labelText: 'Sport'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a sport.'
                      : null,
                ),
                DropdownButtonFormField<TeamModel?>(
                  initialValue: _team,
                  decoration: const InputDecoration(
                    labelText: 'Team roster (optional)',
                  ),
                  items: [
                    const DropdownMenuItem<TeamModel?>(
                      value: null,
                      child: Text('All active students'),
                    ),
                    ...teams
                        .where((team) => team.status.toLowerCase() == 'active')
                        .map(
                          (team) => DropdownMenuItem<TeamModel?>(
                            value: team,
                            child: Text(team.name),
                          ),
                        ),
                  ],
                  onChanged: (value) => setState(() {
                    _team = value;
                    if (value != null) _sport.text = value.sport;
                  }),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Session date'),
                  subtitle: Text(DateFormat('EEEE, d MMM yyyy').format(_date)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (value != null) setState(() => _date = value);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTime,
                        decoration: const InputDecoration(
                          labelText: 'Start time',
                          hintText: '09:00',
                        ),
                        validator: _validateTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endTime,
                        decoration: const InputDecoration(
                          labelText: 'End time',
                          hintText: '10:00',
                        ),
                        validator: _validateTime,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _venue,
                  decoration: const InputDecoration(labelText: 'Venue'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a venue.'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final now = DateTime.now();
            Navigator.pop(
              context,
              AttendanceSessionModel(
                sessionId: widget.initialSession?.sessionId ?? '',
                title: _title.text.trim(),
                sport: _sport.text.trim(),
                teamId: _team?.teamId ?? '',
                teamName: _team?.name ?? '',
                date: _date,
                startTime: _startTime.text.trim(),
                endTime: _endTime.text.trim(),
                venue: _venue.text.trim(),
                status: widget.initialSession?.status ?? 'scheduled',
                responsibleUid: widget.initialSession?.responsibleUid ?? '',
                responsibleName: widget.initialSession?.responsibleName ?? '',
                createdAt: widget.initialSession?.createdAt ?? now,
                updatedAt: now,
              ),
            );
          },
          child: Text(
            widget.initialSession == null ? 'Create' : 'Save changes',
          ),
        ),
      ],
    );
  }

  String? _validateTime(String? value) {
    if (value == null ||
        !RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value.trim())) {
      return 'Use HH:mm.';
    }
    return null;
  }
}

class _EmptyPanel extends StatelessWidget {
  final String message;

  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

class _InlineNotice extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onRetry;

  const _InlineNotice({
    required this.message,
    required this.isError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: isError ? Theme.of(context).colorScheme.errorContainer : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          IconButton(
            tooltip: 'Retry',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    ),
  );
}

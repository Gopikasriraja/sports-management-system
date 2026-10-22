import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_roles.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  final _searchController = TextEditingController();
  DateTime? _filterDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      context.read<AttendanceProvider>().fetchAttendanceForStudent(
        user.uid,
        actorUid: user.uid,
        actorRole: user.role,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final provider = context.watch<AttendanceProvider>();
    if (user == null || user.role != AppRoles.student) {
      return const Center(child: Text('Sign in as a student to view attendance.'));
    }
    if (provider.isLoading && provider.attendanceLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined),
            const SizedBox(height: 8),
            Text('Attendance could not be loaded: ${provider.errorMessage}'),
            TextButton(
              onPressed: () => provider.fetchAttendanceForStudent(
                user.uid,
                actorUid: user.uid,
                actorRole: user.role,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final records = provider.attendanceLogs.where((record) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          record.sport.toLowerCase().contains(query) ||
          record.status.toLowerCase().contains(query) ||
          record.registerNumber.toLowerCase().contains(query);
      final date = _filterDate;
      final matchesDate = date == null ||
          (record.date.year == date.year &&
              record.date.month == date.month &&
              record.date.day == date.day);
      return matchesSearch && matchesDate;
    }).toList();
    if (provider.attendanceLogs.isEmpty) {
      return const Center(
        child: Text('No attendance records are available for your account.'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('My attendance', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search sport, status, or register number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _filterDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (selected != null) setState(() => _filterDate = selected);
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                _filterDate == null
                    ? 'Filter by date'
                    : DateFormat('d MMM yyyy').format(_filterDate!),
              ),
            ),
            if (_filterDate != null)
              TextButton(
                onPressed: () => setState(() => _filterDate = null),
                child: const Text('Clear date'),
              ),
          ],
        ),
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No records match these filters.')),
          ),
        ...records.map(
          (record) => Card(
            child: ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: Text(record.sessionId.isEmpty
                  ? (record.sport.isEmpty
                      ? 'Legacy attendance record'
                      : '${record.sport} · legacy record')
                  : record.sport),
              subtitle: Text(
                '${DateFormat('d MMM yyyy').format(record.date)}'
                '${record.sessionId.isEmpty ? ' · No session ID in historical record' : ' · Session attendance'}',
              ),
              trailing: Chip(label: Text(record.status)),
            ),
          ),
        ),
      ],
    );
  }
}

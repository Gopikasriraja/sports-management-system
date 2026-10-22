import 'dart:convert';

import '../../models/attendance_model.dart';
import '../../models/attendance_session_model.dart';
import '../constants/app_roles.dart';

class AttendanceRules {
  AttendanceRules._();

  static const statuses = ['Present', 'Absent', 'Late', 'Excused'];
  static const sessionStatuses = [
    'scheduled',
    'active',
    'completed',
    'cancelled',
  ];

  static String? validateStatus(String status) =>
      statuses.contains(status) ? null : 'Choose a valid attendance status.';

  static String validateRecordChange({
    required bool alreadyExists,
    required String? previousStatus,
    required String newStatus,
    required String correctionReason,
  }) {
    final statusError = validateStatus(newStatus);
    if (statusError != null) return statusError;
    if (alreadyExists &&
        previousStatus != newStatus &&
        correctionReason.trim().isEmpty) {
      return 'Enter a reason to correct this attendance record.';
    }
    return '';
  }

  static bool canManageSession({
    required String actorUid,
    required String actorRole,
    required String responsibleUid,
  }) =>
      actorRole == AppRoles.admin ||
      actorRole == AppRoles.manager ||
      (actorRole == AppRoles.sportsStaff && actorUid == responsibleUid);

  static String attendanceDocumentId(String sessionId, String studentId) =>
      base64Url.encode(utf8.encode(jsonEncode([sessionId, studentId])));

  static String? validateSession(AttendanceSessionModel session) {
    if (session.title.trim().isEmpty) return 'Enter a session title.';
    if (session.sport.trim().isEmpty) return 'Enter or select a sport.';
    if (session.venue.trim().isEmpty) return 'Enter a venue.';
    if (session.startTime.trim().isEmpty || session.endTime.trim().isEmpty) {
      return 'Enter the session start and end times.';
    }
    final timePattern = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$');
    if (!timePattern.hasMatch(session.startTime.trim()) ||
        !timePattern.hasMatch(session.endTime.trim())) {
      return 'Use HH:mm for session start and end times.';
    }
    if (session.startTime.trim() == session.endTime.trim()) {
      return 'Session start and end times must differ.';
    }
    if (!sessionStatuses.contains(session.status)) {
      return 'Choose a valid session status.';
    }
    if (session.responsibleUid.trim().isEmpty) {
      return 'A responsible staff member is required.';
    }
    return null;
  }

  static bool canTransitionSession(String from, String to) {
    if (!sessionStatuses.contains(from) || !sessionStatuses.contains(to)) {
      return false;
    }
    if (from == to) return true;
    return switch (from) {
      'scheduled' => to == 'active' || to == 'cancelled',
      'active' => to == 'completed' || to == 'cancelled',
      _ => false,
    };
  }

  static AttendanceSummary summarize(
    Iterable<AttendanceModel> attendance,
    Iterable<AttendanceSessionModel> sessions,
  ) {
    final eligibleSessionIds = sessions
        .where((session) => session.status != 'cancelled')
        .map((session) => session.sessionId)
        .toSet();
    final records = attendance
        .where(
          (item) =>
              item.sessionId.isNotEmpty &&
              eligibleSessionIds.contains(item.sessionId),
        )
        .toList();
    final present = records.where((item) => item.status == 'Present').length;
    final absent = records.where((item) => item.status == 'Absent').length;
    final late = records.where((item) => item.status == 'Late').length;
    final excused = records.where((item) => item.status == 'Excused').length;
    final denominator = present + absent + late;
    return AttendanceSummary(
      present: present,
      absent: absent,
      late: late,
      excused: excused,
      percentage: denominator == 0 ? 0 : (present + late) * 100 / denominator,
    );
  }
}

class AttendanceSummary {
  final int present;
  final int absent;
  final int late;
  final int excused;
  final double percentage;

  const AttendanceSummary({
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.percentage,
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sports_management_system/core/constants/app_roles.dart';
import 'package:sports_management_system/core/validation/attendance_rules.dart';
import 'package:sports_management_system/models/attendance_model.dart';
import 'package:sports_management_system/models/attendance_session_model.dart';

void main() {
  group('AttendanceRules', () {
    test('accepts only the four supported attendance statuses', () {
      for (final status in AttendanceRules.statuses) {
        expect(AttendanceRules.validateStatus(status), isNull);
      }
      expect(AttendanceRules.validateStatus('Unknown'), isNotNull);
    });

    test('requires a reason for a changed existing record', () {
      expect(
        AttendanceRules.validateRecordChange(
          alreadyExists: true,
          previousStatus: 'Absent',
          newStatus: 'Present',
          correctionReason: 'Recorded in error',
        ),
        isEmpty,
      );
      expect(
        AttendanceRules.validateRecordChange(
          alreadyExists: true,
          previousStatus: 'Absent',
          newStatus: 'Present',
          correctionReason: '',
        ),
        isNotEmpty,
      );
      expect(
        AttendanceRules.validateRecordChange(
          alreadyExists: true,
          previousStatus: 'Present',
          newStatus: 'Present',
          correctionReason: '',
        ),
        isEmpty,
      );
    });

    test('enforces session status transitions', () {
      expect(AttendanceRules.canTransitionSession('scheduled', 'active'), isTrue);
      expect(AttendanceRules.canTransitionSession('active', 'completed'), isTrue);
      expect(AttendanceRules.canTransitionSession('completed', 'active'), isFalse);
      expect(AttendanceRules.canTransitionSession('cancelled', 'active'), isFalse);
    });

    test('validates session details and time formats', () {
      final session = _session('session-1', 'scheduled');
      expect(AttendanceRules.validateSession(session), isNull);
      expect(
        AttendanceRules.validateSession(
          session.copyWith(startTime: '9am'),
        ),
        isNotNull,
      );
      expect(
        AttendanceRules.validateSession(
          session.copyWith(responsibleUid: ''),
        ),
        isNotNull,
      );
    });

    test('scopes sports staff to responsible sessions', () {
      expect(
        AttendanceRules.canManageSession(
          actorUid: 'staff-1',
          actorRole: AppRoles.sportsStaff,
          responsibleUid: 'staff-1',
        ),
        isTrue,
      );
      expect(
        AttendanceRules.canManageSession(
          actorUid: 'staff-2',
          actorRole: AppRoles.sportsStaff,
          responsibleUid: 'staff-1',
        ),
        isFalse,
      );
      expect(
        AttendanceRules.canManageSession(
          actorUid: 'student-1',
          actorRole: AppRoles.student,
          responsibleUid: 'staff-1',
        ),
        isFalse,
      );
      expect(
        AttendanceRules.canManageSession(
          actorUid: 'manager-1',
          actorRole: AppRoles.manager,
          responsibleUid: 'staff-1',
        ),
        isTrue,
      );
    });

    test('builds a deterministic one-record-per-student document ID', () {
      final first = AttendanceRules.attendanceDocumentId('session/one', 's-1');
      final repeated = AttendanceRules.attendanceDocumentId(
        'session/one',
        's-1',
      );
      final otherStudent = AttendanceRules.attendanceDocumentId(
        'session/one',
        's-2',
      );
      expect(first, repeated);
      expect(first, isNot(otherStudent));
      expect(first, isNot(contains('/')));
    });

    test('percentage excludes excused records and cancelled sessions', () {
      final session = _session('session-1', 'active');
      final cancelled = _session('session-2', 'cancelled');
      final records = [
        _attendance('s-1', 'session-1', 'Present'),
        _attendance('s-2', 'session-1', 'Late'),
        _attendance('s-3', 'session-1', 'Absent'),
        _attendance('s-4', 'session-1', 'Excused'),
        _attendance('s-5', 'session-2', 'Present'),
        _attendance('legacy', '', 'Present'),
      ];

      final summary = AttendanceRules.summarize(records, [session, cancelled]);
      expect(summary.present, 1);
      expect(summary.late, 1);
      expect(summary.absent, 1);
      expect(summary.excused, 1);
      expect(summary.percentage, closeTo(200 / 3, 0.001));
    });
  });
}

AttendanceSessionModel _session(String id, String status) =>
    AttendanceSessionModel(
      sessionId: id,
      title: 'Training',
      sport: 'Football',
      date: DateTime(2026),
      startTime: '09:00',
      endTime: '10:00',
      venue: 'Ground',
      status: status,
      responsibleUid: 'staff',
      responsibleName: 'Coach',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

AttendanceModel _attendance(String student, String session, String status) =>
    AttendanceModel(
      attendanceId: '$session--$student',
      sessionId: session,
      studentId: student,
      studentName: student,
      department: 'Sports',
      sport: 'Football',
      date: DateTime(2026),
      status: status,
      markedBy: 'staff',
      createdAt: DateTime(2026),
    );

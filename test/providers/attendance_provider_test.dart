import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sports_management_system/database/repositories/attendance_repository.dart';
import 'package:sports_management_system/models/attendance_model.dart';
import 'package:sports_management_system/models/student_model.dart';
import 'package:sports_management_system/providers/attendance_provider.dart';

class _FailingAttendanceRepository extends AttendanceRepository {
  final List<AttendanceModel> initialRecords;

  _FailingAttendanceRepository({this.initialRecords = const []});

  @override
  Future<void> markAttendance({
    required String sessionId,
    required StudentModel student,
    required String status,
    required String actorUid,
    required String actorRole,
    String correctionReason = '',
  }) async {
    throw StateError('offline write rejected');
  }

  @override
  Future<List<AttendanceModel>> getAttendanceForStudent(
    String studentId, {
    required String actorUid,
    required String actorRole,
  }) async => initialRecords;
}

class _DeferredAttendanceRepository extends AttendanceRepository {
  final eligibleRequests = <String, Completer<List<StudentModel>>>{};
  final historyRequests = <String, Completer<List<AttendanceModel>>>{};

  @override
  Future<List<StudentModel>> getEligibleStudents(
    String sessionId, {
    required String actorUid,
    required String actorRole,
  }) =>
      (eligibleRequests[sessionId] ??= Completer<List<StudentModel>>()).future;

  @override
  Future<List<AttendanceModel>> getAttendanceForStudent(
    String studentId, {
    required String actorUid,
    required String actorRole,
  }) => (historyRequests[studentId] ??= Completer<List<AttendanceModel>>())
      .future;
}

void main() {
  test(
    'failed attendance write returns false and exposes the failure',
    () async {
      final provider = AttendanceProvider(
        attendanceRepository: _FailingAttendanceRepository(),
      );
      addTearDown(provider.dispose);

      final saved = await provider.markAttendance(
        sessionId: 'session-1',
        student: StudentModel(
          studentId: 'student-1',
          registerNumber: 'R1',
          name: 'Test Student',
          department: 'Sports',
          year: '1',
          section: '',
          gender: '',
          phone: '',
          email: 'student@example.com',
          bloodGroup: '',
          address: '',
          sports: const [],
          profileImage: '',
          createdAt: DateTime(2026),
        ),
        status: 'Present',
        actorUid: 'staff-1',
        actorRole: 'Sports Staff',
      );

      expect(saved, isFalse);
      expect(provider.errorMessage, contains('offline write rejected'));
      expect(provider.attendanceLogs, isEmpty);
    },
  );

  test(
    'failed attendance write preserves the last confirmed records',
    () async {
      final previous = _attendance('student-1');
      final provider = AttendanceProvider(
        attendanceRepository: _FailingAttendanceRepository(
          initialRecords: [previous],
        ),
      );
      addTearDown(provider.dispose);
      await provider.fetchAttendanceForStudent(
        'student-1',
        actorUid: 'student-1',
        actorRole: 'Student',
      );

      final saved = await provider.markAttendance(
        sessionId: 'session-1',
        student: _student('student-1'),
        status: 'Absent',
        actorUid: 'staff-1',
        actorRole: 'Sports Staff',
      );

      expect(saved, isFalse);
      expect(provider.errorMessage, contains('offline write rejected'));
      expect(provider.attendanceLogs, [previous]);
    },
  );

  test(
    'late roster responses cannot replace the newly selected session',
    () async {
      final repository = _DeferredAttendanceRepository();
      final provider = AttendanceProvider(attendanceRepository: repository);
      addTearDown(provider.dispose);
      final first = repository.eligibleRequests['session-1'] =
          Completer<List<StudentModel>>();
      final second = repository.eligibleRequests['session-2'] =
          Completer<List<StudentModel>>();

      final firstLoad = provider.loadEligibleStudents(
        'session-1',
        actorUid: 'staff',
        actorRole: 'Sports Staff',
      );
      final secondLoad = provider.loadEligibleStudents(
        'session-2',
        actorUid: 'staff',
        actorRole: 'Sports Staff',
      );
      second.complete([_student('student-2')]);
      await secondLoad;
      first.complete([_student('student-1')]);
      await firstLoad;

      expect(provider.eligibleStudents.map((student) => student.studentId), [
        'student-2',
      ]);
    },
  );

  test(
    'switching student history clears and ignores stale responses',
    () async {
      final repository = _DeferredAttendanceRepository();
      final provider = AttendanceProvider(attendanceRepository: repository);
      addTearDown(provider.dispose);
      final first = repository.historyRequests['student-1'] =
          Completer<List<AttendanceModel>>();
      final second = repository.historyRequests['student-2'] =
          Completer<List<AttendanceModel>>();

      final firstLoad = provider.fetchAttendanceForStudent(
        'student-1',
        actorUid: 'student-1',
        actorRole: 'Student',
      );
      final secondLoad = provider.fetchAttendanceForStudent(
        'student-2',
        actorUid: 'student-2',
        actorRole: 'Student',
      );
      expect(provider.attendanceLogs, isEmpty);
      expect(provider.isLoading, isTrue);

      second.complete([_attendance('student-2')]);
      await secondLoad;
      first.complete([_attendance('student-1')]);
      await firstLoad;

      expect(provider.attendanceLogs.map((record) => record.studentId), [
        'student-2',
      ]);
    },
  );
}

StudentModel _student(String id) => StudentModel(
  studentId: id,
  registerNumber: id,
  name: id,
  department: 'Sports',
  year: '1',
  section: '',
  gender: '',
  phone: '',
  email: '$id@example.com',
  bloodGroup: '',
  address: '',
  sports: const [],
  profileImage: '',
  createdAt: DateTime(2026),
);

AttendanceModel _attendance(String studentId) => AttendanceModel(
  attendanceId: 'attendance-$studentId',
  studentId: studentId,
  studentName: studentId,
  department: 'Sports',
  sport: 'Football',
  date: DateTime(2026),
  status: 'Present',
  markedBy: 'staff',
  createdAt: DateTime(2026),
);

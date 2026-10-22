import '../services/attendance_service.dart';
import '../../models/attendance_model.dart';
import '../../models/attendance_session_model.dart';
import '../../models/student_model.dart';

class AttendanceRepository {
  final AttendanceService _attendanceService;

  AttendanceRepository({AttendanceService? attendanceService})
      : _attendanceService = attendanceService ?? AttendanceService();

  Future<String> createSession(
    AttendanceSessionModel session, {
    required String actorUid,
    required String actorRole,
    required String actorName,
  }) {
    return _attendanceService.createSession(
      session,
      actorUid: actorUid,
      actorRole: actorRole,
      actorName: actorName,
    );
  }

  Future<void> updateSession(
    AttendanceSessionModel session, {
    required String actorUid,
    required String actorRole,
  }) {
    return _attendanceService.updateSession(
      session,
      actorUid: actorUid,
      actorRole: actorRole,
    );
  }

  Future<void> updateSessionStatus(
    String sessionId,
    String status, {
    required String actorUid,
    required String actorRole,
  }) {
    return _attendanceService.updateSessionStatus(
      sessionId,
      status,
      actorUid: actorUid,
      actorRole: actorRole,
    );
  }

  Stream<List<AttendanceSessionModel>> streamSessions({
    required String actorUid,
    required String actorRole,
  }) {
    return _attendanceService.streamSessions(
      actorUid: actorUid,
      actorRole: actorRole,
    );
  }

  Future<List<StudentModel>> getEligibleStudents(
    String sessionId, {
    required String actorUid,
    required String actorRole,
  }) {
    return _attendanceService.getEligibleStudents(
      sessionId,
      actorUid: actorUid,
      actorRole: actorRole,
    );
  }

  Stream<List<AttendanceModel>> streamSessionAttendance(
    String sessionId, {
    required String actorUid,
    required String actorRole,
  }) {
    return _attendanceService.streamSessionAttendance(
      sessionId,
      actorUid: actorUid,
      actorRole: actorRole,
    );
  }

  Future<void> markAttendance({
    required String sessionId,
    required StudentModel student,
    required String status,
    required String actorUid,
    required String actorRole,
    String correctionReason = '',
  }) {
    return _attendanceService.markAttendance(
      sessionId: sessionId,
      student: student,
      status: status,
      actorUid: actorUid,
      actorRole: actorRole,
      correctionReason: correctionReason,
    );
  }

  Future<List<AttendanceModel>> getAttendanceForStudent(
    String studentId, {
    required String actorUid,
    required String actorRole,
  }) {
    return _attendanceService.getAttendanceForStudent(
      studentId,
      actorUid: actorUid,
      actorRole: actorRole,
    );
  }
}

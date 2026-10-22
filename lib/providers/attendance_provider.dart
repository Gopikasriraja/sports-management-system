import 'dart:async';

import 'package:flutter/material.dart';

import '../database/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';
import '../models/attendance_session_model.dart';
import '../models/student_model.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository;
  StreamSubscription<List<AttendanceSessionModel>>? _sessionsSubscription;
  StreamSubscription<List<AttendanceModel>>? _sessionRecordsSubscription;
  int _eligibleStudentsRequestId = 0;
  int _studentAttendanceRequestId = 0;

  AttendanceProvider({AttendanceRepository? attendanceRepository})
    : _attendanceRepository = attendanceRepository ?? AttendanceRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<AttendanceModel> _attendanceLogs = [];
  List<AttendanceSessionModel> _sessions = [];
  List<StudentModel> _eligibleStudents = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AttendanceModel> get attendanceLogs =>
      List.unmodifiable(_attendanceLogs);
  List<AttendanceSessionModel> get sessions => List.unmodifiable(_sessions);
  List<StudentModel> get eligibleStudents =>
      List.unmodifiable(_eligibleStudents);

  int get totalStudents =>
      _attendanceLogs.map((item) => item.studentId).toSet().length;
  int get presentToday => _attendanceLogs
      .where((item) => item.status == 'Present' && _isToday(item.date))
      .length;
  int get absentToday => _attendanceLogs
      .where((item) => item.status == 'Absent' && _isToday(item.date))
      .length;
  int get lateToday => _attendanceLogs
      .where((item) => item.status == 'Late' && _isToday(item.date))
      .length;
  double get attendancePercentage {
    final records = _attendanceLogs
        .where((item) => _isToday(item.date) && item.status != 'Excused')
        .toList();
    if (records.isEmpty) return 0;
    final attended = records
        .where((item) => item.status == 'Present' || item.status == 'Late')
        .length;
    return attended * 100 / records.length;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  void dispose() {
    _sessionsSubscription?.cancel();
    _sessionRecordsSubscription?.cancel();
    super.dispose();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void watchSessions({required String actorUid, required String actorRole}) {
    _sessionsSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _sessionsSubscription = _attendanceRepository
        .streamSessions(actorUid: actorUid, actorRole: actorRole)
        .listen(
          (sessions) {
            _sessions = sessions;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  Future<bool> createSession(
    AttendanceSessionModel session, {
    required String actorUid,
    required String actorRole,
    required String actorName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _attendanceRepository.createSession(
        session,
        actorUid: actorUid,
        actorRole: actorRole,
        actorName: actorName,
      );
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSessionStatus(
    String sessionId,
    String status, {
    required String actorUid,
    required String actorRole,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _attendanceRepository.updateSessionStatus(
        sessionId,
        status,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSession(
    AttendanceSessionModel session, {
    required String actorUid,
    required String actorRole,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _attendanceRepository.updateSession(
        session,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEligibleStudents(
    String sessionId, {
    required String actorUid,
    required String actorRole,
  }) async {
    final requestId = ++_eligibleStudentsRequestId;
    _isLoading = true;
    _errorMessage = null;
    _eligibleStudents = [];
    notifyListeners();
    try {
      final students = await _attendanceRepository.getEligibleStudents(
        sessionId,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      if (requestId == _eligibleStudentsRequestId) {
        _eligibleStudents = students;
      }
    } catch (error) {
      if (requestId == _eligibleStudentsRequestId) {
        _errorMessage = error.toString();
      }
      rethrow;
    } finally {
      if (requestId == _eligibleStudentsRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void watchSessionAttendance(
    String sessionId, {
    required String actorUid,
    required String actorRole,
  }) {
    _sessionRecordsSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    _attendanceLogs = [];
    notifyListeners();
    _sessionRecordsSubscription = _attendanceRepository
        .streamSessionAttendance(
          sessionId,
          actorUid: actorUid,
          actorRole: actorRole,
        )
        .listen(
          (records) {
            _attendanceLogs = records;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  Future<bool> markAttendance({
    required String sessionId,
    required StudentModel student,
    required String status,
    required String actorUid,
    required String actorRole,
    String correctionReason = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _attendanceRepository.markAttendance(
        sessionId: sessionId,
        student: student,
        status: status,
        actorUid: actorUid,
        actorRole: actorRole,
        correctionReason: correctionReason,
      );
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttendanceForStudent(
    String studentId, {
    required String actorUid,
    required String actorRole,
  }) async {
    final requestId = ++_studentAttendanceRequestId;
    _isLoading = true;
    _errorMessage = null;
    _attendanceLogs = [];
    notifyListeners();
    try {
      final records = await _attendanceRepository.getAttendanceForStudent(
        studentId,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      if (requestId == _studentAttendanceRequestId) {
        _attendanceLogs = records;
      }
    } catch (error) {
      if (requestId == _studentAttendanceRequestId) {
        _attendanceLogs = [];
        _errorMessage = error.toString();
      }
    } finally {
      if (requestId == _studentAttendanceRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}

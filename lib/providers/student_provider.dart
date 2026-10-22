import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_roles.dart';
import '../database/repositories/student_repository.dart';
import '../core/validation/student_registration_validator.dart';
import '../models/student_model.dart';

class StudentProvider extends ChangeNotifier {
  final StudentRepository _studentRepository;
  StreamSubscription? _studentSub;

  StudentProvider({
    StudentRepository? studentRepository,
    bool listenToRealtimeUpdates = true,
  })
      : _studentRepository = studentRepository ?? StudentRepository() {
    if (listenToRealtimeUpdates) _initRealtimeListeners();
  }

  void _initRealtimeListeners() {
    _isLoading = true;
    _studentSub = _studentRepository.streamStudents().listen((list) {
      _students = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _studentSub?.cancel();
    super.dispose();
  }

  bool _isLoading = false;
  String? _errorMessage;
  List<StudentModel> _students = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<StudentModel> get students => _students;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> isRegisterNumberAvailable(
    String registerNumber, {
    required String actorUid,
    required String actorRole,
    String? excludingStudentId,
    String? excludingEmail,
  }) async {
    try {
      return await _studentRepository.isRegisterNumberAvailable(
        registerNumber,
        actorUid: actorUid,
        actorRole: actorRole,
        excludingStudentId: excludingStudentId,
        excludingEmail: excludingEmail,
      );
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Fetch all students
  Future<void> fetchStudents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _studentRepository.getStudentsList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save or update student
  Future<bool> saveStudent(
    StudentModel student, {
    required String actorUid,
    required String actorRole,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nameError = StudentRegistrationValidator.validateName(
        student.name,
      );
      final registerError =
          StudentRegistrationValidator.validateRegisterNumber(
            student.registerNumber,
          );
      final emailError = StudentRegistrationValidator.validateEmail(
        student.email,
      );
      if (nameError != null || registerError != null || emailError != null) {
        throw ArgumentError(nameError ?? registerError ?? emailError);
      }
      if (student.department.trim().isEmpty || student.year.trim().isEmpty) {
        throw ArgumentError('Department and year are required.');
      }
      if (!AppRoles.canManageStudents(actorRole)) {
        throw StateError('You are not authorized to manage student records.');
      }
      await _studentRepository.saveStudent(
        student,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete student
  Future<bool> deleteStudent({
    required String studentId,
    required String actorUid,
    required String actorRole,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!AppRoles.canManageStudents(actorRole)) {
        throw StateError('You are not authorized to manage student records.');
      }
      await _studentRepository.deleteStudent(
        studentId,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      await fetchStudents();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter students by department
  Future<void> fetchStudentsByDepartment(String department) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _studentRepository.getStudentsByDepartment(department);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter students by sport
  Future<void> fetchStudentsBySport(String sport) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _studentRepository.getStudentsBySport(sport);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search students by name or register number
  Future<void> searchStudents(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _studentRepository.searchStudents(query);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

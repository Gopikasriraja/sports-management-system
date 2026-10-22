import 'dart:convert';

import '../../models/student_model.dart';

class StudentRegistrationValidator {
  StudentRegistrationValidator._();

  static String normalizeRegisterNumber(String value) =>
      value.trim().toLowerCase();

  static String registerNumberReservationId(String value) =>
      base64Url.encode(utf8.encode(normalizeRegisterNumber(value)));

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter student name.';
    return null;
  }

  static String? validateRegisterNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter register number.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter email address.';
    if (!RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$')
        .hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static bool isRegisterNumberDuplicate(
    String registerNumber,
    Iterable<StudentModel> students, {
    String? excludingStudentId,
  }) {
    final normalized = normalizeRegisterNumber(registerNumber);
    if (normalized.isEmpty) return false;
    return students.any(
      (student) =>
          student.studentId != excludingStudentId &&
          normalizeRegisterNumber(student.registerNumber) == normalized,
    );
  }
}

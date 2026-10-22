import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_roles.dart';
import '../../core/validation/student_registration_validator.dart';
import '../../models/student_model.dart';
import 'firestore_authorization.dart';

class StudentService {
  final FirebaseFirestore? _firestore;

  StudentService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  Future<bool> isRegisterNumberAvailable(
    String registerNumber, {
    required String actorUid,
    required String actorRole,
    String? excludingStudentId,
    String? excludingEmail,
  }) async {
    await FirestoreAuthorization.requireActiveActor(
      db: db,
      actorUid: actorUid,
      actorRole: actorRole,
    );
    if (!AppRoles.canManageStudents(actorRole)) {
      throw StateError('You are not authorized to inspect student records.');
    }
    final normalized = StudentRegistrationValidator.normalizeRegisterNumber(
      registerNumber,
    );
    if (normalized.isEmpty) return false;
    return !await _hasRegisterNumberDuplicate(
      normalized,
      excludingStudentId: excludingStudentId,
      excludingEmail: excludingEmail,
    );
  }

  // Get specific student
  Future<StudentModel?> getStudent(String studentId) async {
    try {
      final doc = await db.collection('students').doc(studentId).get();
      if (doc.exists) {
        return StudentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch student: $e');
    }
  }

  // Create or update student profile
  Future<void> saveStudent(
    StudentModel student, {
    required String actorUid,
    required String actorRole,
  }) async {
    try {
      await FirestoreAuthorization.requireActiveActor(
        db: db,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      if (!AppRoles.canManageStudents(actorRole)) {
        throw StateError('You are not authorized to manage student records.');
      }
      final validationError =
          StudentRegistrationValidator.validateName(student.name) ??
          StudentRegistrationValidator.validateRegisterNumber(
            student.registerNumber,
          ) ??
          StudentRegistrationValidator.validateEmail(student.email);
      if (validationError != null) {
        throw ArgumentError(validationError);
      }
      if (student.department.trim().isEmpty || student.year.trim().isEmpty) {
        throw ArgumentError('Department and year are required.');
      }
      final students = db.collection('students');
      final studentRef = students.doc(student.studentId);
      final normalized = StudentRegistrationValidator.normalizeRegisterNumber(
        student.registerNumber,
      );
      if (normalized.isEmpty) {
        throw ArgumentError('Register number is required.');
      }
      final duplicate = await _hasRegisterNumberDuplicate(
        normalized,
        excludingStudentId: student.studentId,
        excludingEmail: student.email,
      );
      if (duplicate) {
        throw StateError('A student with this register number already exists.');
      }

      final reservationRef = db
          .collection('student_register_numbers')
          .doc(
            StudentRegistrationValidator.registerNumberReservationId(
              normalized,
            ),
          );
      await db.runTransaction((transaction) async {
        final existingStudent = await transaction.get(studentRef);
        final reservation = await transaction.get(reservationRef);
        final reservationData = reservation.data();
        if (reservation.exists &&
            reservationData?['ownerId'] != student.studentId &&
            (reservationData?['email'] as String? ?? '').toLowerCase() !=
                student.email.toLowerCase()) {
          throw StateError(
            'A student with this register number already exists.',
          );
        }
        final previousRegisterNumber = existingStudent.exists
            ? StudentRegistrationValidator.normalizeRegisterNumber(
                existingStudent.data()?['registerNumber'] as String? ?? '',
              )
            : '';
        final previousReservationRef =
            previousRegisterNumber.isEmpty ||
                previousRegisterNumber == normalized
            ? null
            : db
                  .collection('student_register_numbers')
                  .doc(
                    StudentRegistrationValidator.registerNumberReservationId(
                      previousRegisterNumber,
                    ),
                  );
        final previousReservation = previousReservationRef == null
            ? null
            : await transaction.get(previousReservationRef);

        transaction.set(reservationRef, {
          'registerNumber': student.registerNumber.trim(),
          'registerNumberNormalized': normalized,
          'ownerId': student.studentId,
          'email': student.email.toLowerCase(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final previousData = previousReservation?.data();
        if (previousReservationRef != null &&
            previousReservation?.exists == true &&
            (previousData?['ownerId'] == student.studentId ||
                (previousData?['email'] as String? ?? '').toLowerCase() ==
                    student.email.toLowerCase())) {
          transaction.delete(previousReservationRef);
        }
        transaction.set(studentRef, {
          ...student.toMap(),
          'registerNumberNormalized': normalized,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      if (e is StateError) rethrow;
      throw Exception('Failed to save student: $e');
    }
  }

  // Delete student profile
  Future<void> deleteStudent(
    String studentId, {
    required String actorUid,
    required String actorRole,
  }) async {
    try {
      await FirestoreAuthorization.requireActiveActor(
        db: db,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      if (!AppRoles.canManageStudents(actorRole)) {
        throw StateError('You are not authorized to manage student records.');
      }
      await db.collection('students').doc(studentId).update({
        'status': 'inactive',
      });
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  // Stream all students
  Stream<List<StudentModel>> streamStudents() {
    return db
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StudentModel.fromFirestore(doc))
              .toList();
        });
  }

  // Fetch all students list
  Future<List<StudentModel>> getStudentsList() async {
    try {
      final snapshot = await db
          .collection('students')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StudentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch students list: $e');
    }
  }

  // Filter students by department
  Future<List<StudentModel>> getStudentsByDepartment(String department) async {
    try {
      final snapshot = await db
          .collection('students')
          .where('department', isEqualTo: department)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StudentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch students by department: $e');
    }
  }

  // Filter students by sport (array-contains query)
  Future<List<StudentModel>> getStudentsBySport(String sport) async {
    try {
      final snapshot = await db
          .collection('students')
          .where('sports', arrayContains: sport)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StudentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch students by sport: $e');
    }
  }

  // Search students by name or register number (client-side filter)
  Future<List<StudentModel>> searchStudents(String query) async {
    try {
      final allStudents = await getStudentsList();
      final lowerQuery = query.toLowerCase();
      return allStudents.where((student) {
        return student.name.toLowerCase().contains(lowerQuery) ||
            student.registerNumber.toLowerCase().contains(lowerQuery) ||
            student.email.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search students: $e');
    }
  }

  Future<bool> _hasRegisterNumberDuplicate(
    String normalized, {
    String? excludingStudentId,
    String? excludingEmail,
  }) async {
    final records = await Future.wait([
      db.collection('students').get(),
      db.collection('users').get(),
    ]);
    return records.any(
      (snapshot) => snapshot.docs.any((doc) {
        final data = doc.data();
        final registerNumber = data['registerNumber'] as String? ?? '';
        if (registerNumber.trim().isEmpty) return false;
        final storedNormalized =
            data['registerNumberNormalized'] as String? ??
            StudentRegistrationValidator.normalizeRegisterNumber(
              registerNumber,
            );
        final isExcluded =
            doc.id == excludingStudentId ||
            (excludingEmail != null &&
                (data['email'] as String? ?? '').toLowerCase() ==
                    excludingEmail.toLowerCase());
        return storedNormalized == normalized && !isExcluded;
      }),
    );
  }
}

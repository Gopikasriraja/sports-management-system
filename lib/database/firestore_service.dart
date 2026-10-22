import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_roles.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore? _firestore;

  FirestoreService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  // Retrieve user document by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user from Firestore: $e');
    }
  }

  // Public registration can only create a pending Sports Staff profile.
  Future<void> createPendingStaffProfile(UserModel user) async {
    if (user.role != AppRoles.sportsStaff) {
      throw StateError('Public registration is limited to Sports Staff.');
    }
    try {
      await db.collection('users').doc(user.uid).set({
        ...user.toMap(),
        'role': AppRoles.sportsStaff,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to save user in Firestore: $e');
    }
  }

  // Check if a register number already exists (for sign-up duplicate validation)
  Future<bool> checkRegisterNumberExists(String registerNumber) async {
    try {
      if (registerNumber.trim().isEmpty) return false;
      final query = await db
          .collection('students')
          .where('registerNumber', isEqualTo: registerNumber.trim())
          .limit(1)
          .get();
      // Also check in users collection for Student role
      final userQuery = await db
          .collection('users')
          .where('registerNumber', isEqualTo: registerNumber.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty || userQuery.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check register number: $e');
    }
  }

  // Check if an employee ID already exists (for Sports Staff sign-up)
  Future<bool> checkEmployeeIdExists(String employeeId) async {
    try {
      if (employeeId.trim().isEmpty) return false;
      final query = await db
          .collection('users')
          .where('employeeId', isEqualTo: employeeId.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check employee ID: $e');
    }
  }

  // Fetch a student by their register number and phone number
  Future<UserModel?> getStudentByCredentials(String registerNumber, String phone) async {
    try {
      final query = await db
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('registerNumber', isEqualTo: registerNumber.trim())
          .where('phone', isEqualTo: phone.trim())
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch student by credentials: $e');
    }
  }
}

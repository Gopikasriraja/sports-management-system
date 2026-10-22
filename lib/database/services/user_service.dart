import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_roles.dart';
import '../../core/validation/student_registration_validator.dart';
import '../../models/user_model.dart';
import 'firestore_authorization.dart';

class UserService {
  final FirebaseFirestore? _firestore;

  UserService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  // Fetch user profile
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  // Create or update user profile
  Future<void> saveUser(
    UserModel user, {
    required String actorUid,
    required String actorRole,
  }) async {
    try {
      await FirestoreAuthorization.requireActiveActor(
        db: db,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      _authorizeTarget(
        actorUid: actorUid,
        actorRole: actorRole,
        targetUid: user.uid,
        targetRole: user.role,
      );
      final users = db.collection('users');
      final userRef = users.doc(user.uid);
      final normalized = StudentRegistrationValidator.normalizeRegisterNumber(
        user.registerNumber,
      );
      await _ensureRegisterNumberAvailable(user, normalized);
      final reservationRef = normalized.isEmpty
          ? null
          : _registerReservationRef(normalized);
      final initialAdminCount = await _activeAdminCount();
      final counterRef = _activeAdminCounterRef;
      await db.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final reservation = reservationRef == null
            ? null
            : await transaction.get(reservationRef);
        final counter = await transaction.get(counterRef);
        final reservationData = reservation?.data();
        if (reservation?.exists == true &&
            reservationData?['ownerId'] != user.uid &&
            (reservationData?['email'] as String? ?? '').toLowerCase() !=
                user.email.toLowerCase()) {
          throw StateError(
            'A student with this register number already exists.',
          );
        }
        final existing = userSnapshot.exists
            ? UserModel.fromFirestore(userSnapshot)
            : null;
        final previousNumber = StudentRegistrationValidator
            .normalizeRegisterNumber(existing?.registerNumber ?? '');
        final previousRef = previousNumber.isEmpty ||
                previousNumber == normalized
            ? null
            : _registerReservationRef(previousNumber);
        final previousReservation = previousRef == null
            ? null
            : await transaction.get(previousRef);
        final wasActiveAdmin = existing?.role == 'Admin' &&
            existing?.status.toLowerCase() == 'active';
        final willBeActiveAdmin =
            user.role == 'Admin' && user.status.toLowerCase() == 'active';
        final adminCount = (counter.data()?['count'] as num?)?.toInt() ??
            initialAdminCount;
        final updatedAdminCount = adminCount +
            (willBeActiveAdmin ? 1 : 0) -
            (wasActiveAdmin ? 1 : 0);
        if (wasActiveAdmin &&
            !willBeActiveAdmin &&
            !AppRoles.canRemoveActiveAdministrator(adminCount)) {
          throw StateError(
            'The last active administrator cannot be demoted or deactivated.',
          );
        }
        transaction.set(counterRef, {'count': updatedAdminCount});
        if (reservationRef != null) {
          transaction.set(reservationRef, {
            'registerNumber': user.registerNumber.trim(),
            'registerNumberNormalized': normalized,
            'ownerId': user.uid,
            'email': user.email.toLowerCase(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        final oldReservationData = previousReservation?.data();
        if (previousRef != null &&
            previousReservation?.exists == true &&
            (oldReservationData?['ownerId'] == user.uid ||
                (oldReservationData?['email'] as String? ?? '')
                        .toLowerCase() ==
                    user.email.toLowerCase())) {
          transaction.delete(previousRef);
        }
        transaction.set(userRef, user.toMap(), SetOptions(merge: true));
      });
    } catch (e) {
      if (e is StateError) rethrow;
      throw Exception('Failed to save user: $e');
    }
  }

  // Delete user document
  Future<void> deleteUser(
    String uid, {
    required String actorUid,
    required String actorRole,
  }) async {
    try {
      await FirestoreAuthorization.requireActiveActor(
        db: db,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      if (!AppRoles.canManageUsers(actorRole) || uid == actorUid) {
        throw StateError('You are not authorized to deactivate this account.');
      }
      await updateUserStatus(
        uid,
        'inactive',
        actorUid: actorUid,
        actorRole: actorRole,
      );
    } catch (e) {
      throw Exception('Failed to deactivate user: $e');
    }
  }

  Future<void> updateUserSafely(
    UserModel user, {
    required String actorUid,
    required String actorRole,
  }) async {
    try {
      await FirestoreAuthorization.requireActiveActor(
        db: db,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      _authorizeTarget(
        actorUid: actorUid,
        actorRole: actorRole,
        targetUid: user.uid,
        targetRole: user.role,
      );
      final users = db.collection('users');
      final userRef = users.doc(user.uid);
      final normalized = StudentRegistrationValidator.normalizeRegisterNumber(
        user.registerNumber,
      );
      await _ensureRegisterNumberAvailable(user, normalized);
      final reservationRef = normalized.isEmpty
          ? null
          : _registerReservationRef(normalized);
      final initialAdminCount = await _activeAdminCount();
      final counterRef = _activeAdminCounterRef;
      await db.runTransaction((transaction) async {
        final currentSnapshot = await transaction.get(userRef);
        if (!currentSnapshot.exists) {
          throw StateError('The user profile no longer exists.');
        }
        final reservation = reservationRef == null
            ? null
            : await transaction.get(reservationRef);
        final counter = await transaction.get(counterRef);
        final current = UserModel.fromFirestore(currentSnapshot);
        final reservationData = reservation?.data();
        if (reservation?.exists == true &&
            reservationData?['ownerId'] != user.uid &&
            (reservationData?['email'] as String? ?? '').toLowerCase() !=
                user.email.toLowerCase()) {
          throw StateError(
            'A student with this register number already exists.',
          );
        }
        final wasActiveAdmin =
            current.role == 'Admin' && current.status.toLowerCase() == 'active';
        final willBeActiveAdmin =
            user.role == 'Admin' && user.status.toLowerCase() == 'active';
        final adminCount = (counter.data()?['count'] as num?)?.toInt() ??
            initialAdminCount;
        final updatedAdminCount = adminCount +
            (willBeActiveAdmin ? 1 : 0) -
            (wasActiveAdmin ? 1 : 0);
        if (wasActiveAdmin &&
            !willBeActiveAdmin &&
            !AppRoles.canRemoveActiveAdministrator(adminCount)) {
          throw StateError(
            'The last active administrator cannot be demoted or deactivated.',
          );
        }
        final oldNumber = StudentRegistrationValidator
            .normalizeRegisterNumber(current.registerNumber);
        final oldReservationRef = oldNumber.isEmpty || oldNumber == normalized
            ? null
            : _registerReservationRef(oldNumber);
        final oldReservation = oldReservationRef == null
            ? null
            : await transaction.get(oldReservationRef);

        transaction.set(counterRef, {'count': updatedAdminCount});
        if (reservationRef != null) {
          transaction.set(reservationRef, {
            'registerNumber': user.registerNumber.trim(),
            'registerNumberNormalized': normalized,
            'ownerId': user.uid,
            'email': user.email.toLowerCase(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        final oldReservationData = oldReservation?.data();
        if (oldReservationRef != null &&
            oldReservation?.exists == true &&
            (oldReservationData?['ownerId'] == user.uid ||
                (oldReservationData?['email'] as String? ?? '')
                        .toLowerCase() ==
                    user.email.toLowerCase())) {
          transaction.delete(oldReservationRef);
        }
        transaction.set(userRef, user.toMap(), SetOptions(merge: true));
      });
    } catch (e) {
      if (e is StateError) rethrow;
      throw Exception('Failed to update user safely: $e');
    }
  }

  Future<void> updateUserStatus(
    String uid,
    String status, {
    required String actorUid,
    required String actorRole,
  }) async {
    try {
      await FirestoreAuthorization.requireActiveActor(
        db: db,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      if (!AppRoles.canManageUsers(actorRole) || uid == actorUid) {
        throw StateError('You are not authorized to deactivate this account.');
      }
      final users = db.collection('users');
      final userRef = users.doc(uid);
      final initialAdminCount = await _activeAdminCount();
      final counterRef = _activeAdminCounterRef;
      await db.runTransaction((transaction) async {
        final currentSnapshot = await transaction.get(userRef);
        if (!currentSnapshot.exists) return;
        final counter = await transaction.get(counterRef);
        final current = UserModel.fromFirestore(currentSnapshot);
        final wasActiveAdmin =
            current.role == 'Admin' && current.status.toLowerCase() == 'active';
        final willBeActiveAdmin =
            current.role == 'Admin' && status.toLowerCase() == 'active';
        final adminCount = (counter.data()?['count'] as num?)?.toInt() ??
            initialAdminCount;
        final updatedAdminCount = adminCount +
            (willBeActiveAdmin ? 1 : 0) -
            (wasActiveAdmin ? 1 : 0);
        if (wasActiveAdmin &&
            !willBeActiveAdmin &&
            !AppRoles.canRemoveActiveAdministrator(adminCount)) {
          throw StateError(
            'The last active administrator cannot be deactivated.',
          );
        }
        transaction.set(counterRef, {'count': updatedAdminCount});
        transaction.set(
          userRef,
          current.copyWith(status: status.toLowerCase()).toMap(),
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      if (e is StateError) rethrow;
      throw Exception('Failed to update user status: $e');
    }
  }

  // Fetch all users list
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await db.collection('users').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all users: $e');
    }
  }

  // Stream all users in real-time
  Stream<List<UserModel>> streamUsers() {
    return db.collection('users').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Filter users by role (Admin / User)
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final snapshot = await db
          .collection('users')
          .where('role', isEqualTo: role)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch users by role: $e');
    }
  }

  DocumentReference<Map<String, dynamic>> get _activeAdminCounterRef =>
      db.collection('system_counters').doc('active_admins');

  DocumentReference<Map<String, dynamic>> _registerReservationRef(
    String normalized,
  ) => db
      .collection('student_register_numbers')
      .doc(
        StudentRegistrationValidator.registerNumberReservationId(normalized),
      );

  Future<void> _ensureRegisterNumberAvailable(
    UserModel user,
    String normalized,
  ) async {
    if (normalized.isEmpty) return;
    final records = await Future.wait([
      db.collection('users').get(),
      db.collection('students').get(),
    ]);
    final duplicate = records.any(
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
            doc.id == user.uid ||
            (data['email'] as String? ?? '').toLowerCase() ==
                user.email.toLowerCase();
        return storedNormalized == normalized && !isExcluded;
      }),
    );
    if (duplicate) {
      throw StateError('A student with this register number already exists.');
    }
  }

  Future<int> _activeAdminCount() async {
    final admins = await db
        .collection('users')
        .where('role', isEqualTo: 'Admin')
        .get();
    return admins.docs
        .map(UserModel.fromFirestore)
        .where((user) => user.status.toLowerCase() == 'active')
        .length;
  }

  void _authorizeTarget({
    required String actorUid,
    required String actorRole,
    required String targetUid,
    required String targetRole,
  }) {
    if (targetUid == actorUid ||
        !AppRoles.canCreateUserWithRole(actorRole, targetRole)) {
      throw StateError('You are not authorized to manage this account.');
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_roles.dart';
import '../database/repositories/user_repository.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  StreamSubscription<List<UserModel>>? _userSub;

  UserProvider({
    UserRepository? userRepository,
    bool listenToRealtimeUpdates = true,
  })
    : _userRepository = userRepository ?? UserRepository() {
    if (listenToRealtimeUpdates) _initRealtimeListeners();
  }

  void _initRealtimeListeners() {
    _isLoading = true;
    _userSub = _userRepository.streamUsers().listen(
      (list) {
        _users = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _selectedUser;
  List<UserModel> _users = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get selectedUser => _selectedUser;
  List<UserModel> get users => _users;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Fetch single user by UID
  Future<void> fetchUser(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedUser = await _userRepository.getUser(uid);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all users
  Future<void> fetchAllUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userRepository.getAllUsers();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a user (from database only)
  Future<bool> deleteUser({
    required String uid,
    required String actorUid,
    required String actorRole,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _verifyActor(actorUid, actorRole);
      if (!AppRoles.canManageUsers(actorRole)) {
        throw StateError('Only an administrator can deactivate user accounts.');
      }
      if (uid == actorUid) {
        throw StateError('You cannot deactivate your own account here.');
      }
      await _userRepository.deleteUser(
        uid,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      _users = _users
          .map(
            (user) =>
                user.uid == uid ? user.copyWith(status: 'inactive') : user,
          )
          .toList();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch users filtered by role
  Future<void> fetchUsersByRole(String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userRepository.getUsersByRole(role);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create User with Firebase Auth and Firestore record
  Future<bool> createUser({
    required String name,
    required String email,
    required String phone,
    required String department,
    required String role,
    required String status,
    required String password,
    required String actorUid,
    required String actorRole,
    String registerNumber = '',
    XFile? profileImageFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    FirebaseApp? tempApp;
    User? createdAuthUser;
    Reference? uploadedImageRef;
    var success = false;

    try {
      await _verifyActor(actorUid, actorRole);
      if (!AppRoles.canCreateUserWithRole(actorRole, role)) {
        throw StateError('You are not authorized to create this user role.');
      }
      if (![
        AppRoles.admin,
        AppRoles.manager,
        AppRoles.sportsStaff,
        AppRoles.student,
      ].contains(role)) {
        throw StateError('Select a valid account role.');
      }
      final tempAppName =
          'TempUserCreator_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credentials = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      createdAuthUser = credentials.user;
      if (createdAuthUser == null) {
        throw Exception('Failed to generate user ID from authentication.');
      }

      String profileImageUrl = '';
      if (profileImageFile != null) {
        final imageRef = FirebaseStorage.instance
            .ref()
            .child('users')
            .child('${createdAuthUser.uid}.jpg');
        uploadedImageRef = imageRef;
        final bytes = await profileImageFile.readAsBytes();
        await imageRef.putData(bytes);
        profileImageUrl = await imageRef.getDownloadURL();
      }

      final newUser = UserModel(
        uid: createdAuthUser.uid,
        name: name,
        email: email,
        role: role,
        department: department,
        year: '',
        registerNumber: registerNumber,
        phone: phone,
        profileImage: profileImageUrl,
        status: status.toLowerCase(),
        createdAt: DateTime.now(),
      );

      await _userRepository.saveUser(
        newUser,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      _selectedUser = newUser;
      _users = [newUser, ..._users.where((user) => user.uid != newUser.uid)];
      success = true;
    } catch (e) {
      var message = e.toString().replaceFirst('Exception: ', '');
      if (uploadedImageRef != null) {
        try {
          await uploadedImageRef.delete();
        } on FirebaseException catch (cleanupError) {
          if (cleanupError.code != 'object-not-found') {
            message +=
                '\nFailed to remove the uploaded profile image: '
                '${cleanupError.message ?? cleanupError.code}';
          }
        }
      }
      if (createdAuthUser != null) {
        try {
          await createdAuthUser.delete();
        } catch (cleanupError) {
          message +=
              '\nFailed to remove the newly created authentication '
              'account: $cleanupError';
        }
      }
      _errorMessage = message;
    } finally {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (e) {
          debugPrint('Failed to close temporary Firebase app: $e');
        }
      }
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  // Update existing user document in Firestore (and upload optional photo)
  Future<bool> updateUser({
    required UserModel existingUser,
    required String actorUid,
    required String actorRole,
    required String name,
    required String department,
    required String role,
    required String phone,
    required String status,
    String registerNumber = '',
    XFile? profileImageFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _verifyActor(actorUid, actorRole);
      if (existingUser.uid == actorUid) {
        throw StateError('You cannot modify your own account here.');
      }
      final canManageTarget =
          AppRoles.canManageUsers(actorRole) ||
          (AppRoles.canManageStudents(actorRole) &&
              existingUser.role == AppRoles.student &&
              role == AppRoles.student);
      if (!canManageTarget) {
        throw StateError('You are not authorized to modify this account.');
      }
      if (![
        AppRoles.admin,
        AppRoles.manager,
        AppRoles.sportsStaff,
        AppRoles.student,
      ].contains(role)) {
        throw StateError('Select a valid account role.');
      }
      String profileImageUrl = existingUser.profileImage;
      if (profileImageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('users')
            .child('${existingUser.uid}.jpg');
        final bytes = await profileImageFile.readAsBytes();
        await ref.putData(bytes);
        profileImageUrl = await ref.getDownloadURL();
      }

      final updatedUser = existingUser.copyWith(
        name: name,
        department: department,
        role: role,
        phone: phone,
        status: status.toLowerCase(),
        registerNumber: registerNumber.isNotEmpty
            ? registerNumber
            : existingUser.registerNumber,
        profileImage: profileImageUrl,
      );

      await _userRepository.updateUserSafely(
        updatedUser,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      _selectedUser = updatedUser;
      _users = _users
          .map((user) => user.uid == updatedUser.uid ? updatedUser : user)
          .toList();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send Password Reset link
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _verifyActor(String actorUid, String actorRole) async {
    if (FirebaseAuth.instance.currentUser?.uid != actorUid) {
      throw StateError('The signed-in account does not match this action.');
    }
    final actor = await _userRepository.getUser(actorUid);
    if (actor == null ||
        actor.status.toLowerCase() != 'active' ||
        actor.role != actorRole) {
      throw StateError(
        'The signed-in account is not authorized for this action.',
      );
    }
  }
}

import 'package:flutter/material.dart';
import '../core/constants/app_roles.dart';
import '../database/auth_service.dart';
import '../database/firestore_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthProvider({AuthService? authService, FirestoreService? firestoreService})
    : _authService = authService ?? AuthService(),
      _firestoreService = firestoreService ?? FirestoreService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailVerificationSent = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get emailVerificationSent => _emailVerificationSent;
  bool get isEmailVerified => _authService.isEmailVerified;

  // Clear errors
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Admin / Staff Login ──────────────────────────────────────────────────
  // Admin, Manager, and Sports Staff use this authentication flow.
  Future<bool> loginAdmin(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final firebaseUser = await _authService.signIn(email, password);
      if (firebaseUser != null) {
        if (!firebaseUser.emailVerified) {
          await _authService.signOut();
          _errorMessage =
              'Please verify your email before logging in. Check your inbox for a verification link.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final user = await _firestoreService.getUser(firebaseUser.uid);
        if (user == null) {
          await _authService.signOut();
          _errorMessage =
              'No user profile is associated with this account. Contact administration.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        if (user.status.toLowerCase() != 'active') {
          await _authService.signOut();
          _errorMessage = 'This account is inactive. Contact administration.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        if (user.role == AppRoles.admin ||
            AppRoles.canAccessOperationsPortal(user.role)) {
          _currentUser = user;
          _isLoading = false;
          debugPrint('Authentication Status: Success');
          debugPrint('Current User UID: ${firebaseUser.uid}');
          notifyListeners();
          return true;
        } else {
          await _authService.signOut();
          _errorMessage =
              'You do not have Admin, Manager, or Sports Staff access.';
          debugPrint('Authentication Status: Failed (Not admin/staff)');
        }
      } else {
        _errorMessage = 'Authentication failed. Please try again.';
        debugPrint('Authentication Status: Failed ($_errorMessage)');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Authentication Status: Failed ($_errorMessage)');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ─── Student Login ────────────────────────────────────────────────────────
  Future<bool> loginUser(
    String registerNumber,
    String phone,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final student = await _firestoreService.getStudentByCredentials(
        registerNumber,
        phone,
      );
      if (student == null) {
        _errorMessage =
            'Student not found with this register number and phone.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final email = student.email;
      final firebaseUser = await _authService.signIn(email, password);
      if (firebaseUser != null) {
        // Bypass email verification for students since credentials are created by Admin
        final user = await _firestoreService.getUser(firebaseUser.uid);
        if (user == null) {
          await _authService.signOut();
          _errorMessage =
              'No student profile is associated with this account. Contact administration.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        if (user.status.toLowerCase() != 'active') {
          await _authService.signOut();
          _errorMessage = 'This account is inactive. Contact administration.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        if (user.role == AppRoles.student) {
          _currentUser = user;
          _isLoading = false;
          debugPrint('Authentication Status: Success');
          debugPrint('Current User UID: ${firebaseUser.uid}');
          notifyListeners();
          return true;
        } else {
          await _authService.signOut();
          _errorMessage =
              'This portal is for Students only. Use the Admin/Staff portal.';
          debugPrint('Authentication Status: Failed (Not student)');
        }
      } else {
        _errorMessage = 'Authentication failed. Please try again.';
        debugPrint('Authentication Status: Failed ($_errorMessage)');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Authentication Status: Failed ($_errorMessage)');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ─── Sign Up (New Account Registration) ──────────────────────────────────
  Future<bool> signUp({
    required String name,
    required String email,
    required String phone,
    required String department,
    required String role,
    required String password,
    String registerNumber = '',
    String employeeId = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _emailVerificationSent = false;
    notifyListeners();

    if (role == AppRoles.admin) {
      _errorMessage =
          'Admin registration is not allowed. Only one Admin is permitted.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    if (role == AppRoles.student) {
      _errorMessage =
          'Student registration is not allowed. Student credentials must be created by an Administrator.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    if (role != AppRoles.sportsStaff) {
      _errorMessage =
          'Only Sports Staff can register through public sign-up. '
          'Manager accounts must be created by an Administrator.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // 1. Validate duplicate register number for Students
      if (role == AppRoles.student && registerNumber.isNotEmpty) {
        final exists = await _firestoreService.checkRegisterNumberExists(
          registerNumber,
        );
        if (exists) {
          _errorMessage =
              'This Register Number is already registered. Please contact administration.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // 2. Validate duplicate employee ID for Sports Staff
      if (role == AppRoles.sportsStaff && employeeId.isNotEmpty) {
        final exists = await _firestoreService.checkEmployeeIdExists(
          employeeId,
        );
        if (exists) {
          _errorMessage =
              'This Employee ID is already registered. Please contact administration.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // 3. Create Firebase Auth account
      final firebaseUser = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );
      if (firebaseUser == null) {
        _errorMessage = 'Failed to create account. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 4. Save user profile to Firestore
      final newUser = UserModel(
        uid: firebaseUser.uid,
        name: name,
        email: email,
        role: role,
        department: department,
        year: '',
        registerNumber: registerNumber,
        employeeId: employeeId,
        phone: phone,
        profileImage: '',
        status: 'active',
        createdAt: DateTime.now(),
      );
      await _firestoreService.createPendingStaffProfile(newUser);

      // 5. Send email verification
      await _authService.sendEmailVerification();
      _emailVerificationSent = true;

      // Sign out immediately — user must verify email before first login
      await _authService.signOut();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('SIGN UP EXCEPTION: $e\n$stackTrace');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      _errorMessage =
          'Connection failed or Firebase is not configured properly. Original Error: $_errorMessage';
      // Clean up: if Auth user was created but Firestore write failed, sign out
      try {
        await _authService.signOut();
      } catch (_) {}
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Email Verification ───────────────────────────────────────────────────
  // Reload user from Firebase and check if email is now verified
  Future<bool> checkEmailVerification() async {
    try {
      if (_authService.auth.currentUser == null) {
        return false;
      }

      await _authService.reloadUser();

      return _authService.isEmailVerified;
    } catch (e) {
      return false;
    }
  }

  // Resend verification email (user must be signed in temporarily)
  Future<bool> resendVerificationEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _emailVerificationSent = false;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      if (!_authService.isEmailVerified) {
        await _authService.sendEmailVerification();
        _emailVerificationSent = true;
      }
      await _authService.signOut();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      try {
        await _authService.signOut();
      } catch (_) {}
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Password Reset ───────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordReset(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (_) {}

    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // ─── Session Restoration ──────────────────────────────────────────────────
  // Called at app startup via SplashScreen.
  // Returns role string if valid session exists, null otherwise.
  Future<String?> checkPersistedSession() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      try {
        // Reload to get latest emailVerified status
        await _authService.reloadUser();
        if (!_authService.isEmailVerified) {
          // Email not verified — sign out and return null
          await _authService.signOut();
          return null;
        }

        final user = await _firestoreService.getUser(firebaseUser.uid);
        if (user != null && user.status.toLowerCase() == 'active') {
          _currentUser = user;
          notifyListeners();
          return user.role;
        }
        if (user != null) {
          await _authService.signOut();
          return null;
        }
      } catch (_) {
        // Session invalid or firestore error
        await _authService.signOut();
      }
    }
    return null;
  }
}

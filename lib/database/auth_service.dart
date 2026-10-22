import 'package:firebase_auth/firebase_auth.dart';

class AuthUser {
  final String uid;
  final String email;
  final bool emailVerified;

  AuthUser({required this.uid, required this.email, this.emailVerified = false});
}

class AuthService {
  final FirebaseAuth? authInstance;

  // Using initializing formal syntax (prefer_initializing_formals fix)
  AuthService({this.authInstance});

  FirebaseAuth get auth => authInstance ?? FirebaseAuth.instance;

  // Stream of auth changes mapped to AuthUser
  Stream<AuthUser?> get authStateChanges => auth.authStateChanges().map((user) {
        if (user != null) {
          return AuthUser(uid: user.uid, email: user.email ?? '', emailVerified: user.emailVerified);
        }
        return null;
      });

  // Get current user mapped to AuthUser
  AuthUser? get currentUser {
    final user = auth.currentUser;
    if (user != null) {
      return AuthUser(uid: user.uid, email: user.email ?? '', emailVerified: user.emailVerified);
    }
    return null;
  }

  // Check if current user's email is verified
  bool get isEmailVerified => auth.currentUser?.emailVerified ?? false;

  // Sign in with email and password returning AuthUser
  Future<AuthUser?> signIn(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        return AuthUser(uid: user.uid, email: user.email ?? '', emailVerified: user.emailVerified);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected authentication error occurred.');
    }
  }

  // Create a new user with email and password
  Future<AuthUser?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        return AuthUser(uid: user.uid, email: user.email ?? '', emailVerified: user.emailVerified);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to create account. Please try again.');
    }
  }

  // Send email verification to the currently signed-in user
  Future<void> sendEmailVerification() async {
    try {
      final user = auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send verification email. Please try again.');
    }
  }

  // Reload the current user to refresh emailVerified status
  Future<void> reloadUser() async {
    try {
      await auth.currentUser?.reload();
    } catch (e) {
      // Fail silently — caller should check isEmailVerified after calling
    }
  }

  // Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset link.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw Exception('Failed to log out securely.');
    }
  }

  // Handle specific Firebase exceptions and return friendly errors
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return Exception('The email address format is invalid.');
      case 'email-already-in-use':
        return Exception('An account with this email already exists.');
      case 'user-disabled':
        return Exception('This account has been disabled. Contact administration.');
      case 'user-not-found':
        return Exception('No account found with this email address.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'invalid-credential':
        return Exception('Invalid credentials. Please check your email and password.');
      case 'weak-password':
        return Exception('Password is too weak. Use at least 8 characters with uppercase, lowercase, numbers, and symbols.');
      case 'network-request-failed':
        return Exception('Network error. Check your internet connection.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      default:
        return Exception(e.message ?? 'Authentication failed.');
    }
  }
}

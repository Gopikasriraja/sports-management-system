import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_management_system/main.dart';
import 'package:sports_management_system/core/routes/app_router.dart';
import 'package:sports_management_system/database/auth_service.dart';
import 'package:sports_management_system/database/firestore_service.dart';
import 'package:sports_management_system/providers/auth_provider.dart';
import 'package:sports_management_system/models/user_model.dart';

// Mock Services to bypass Firebase instantiation during testing
class MockAuthService extends AuthService {
  MockAuthService() : super(authInstance: null);

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  AuthUser? get currentUser => null;
}

class MockFirestoreService extends FirestoreService {
  MockFirestoreService() : super(db: null);
}

// Custom Mock Auth Provider inheriting AuthProvider with mocked logic
class MockAuthProvider extends AuthProvider {
  UserModel? _mockUser;
  bool _isLoading = false;
  String? _errorMessage;

  MockAuthProvider()
    : super(
        authService: MockAuthService(),
        firestoreService: MockFirestoreService(),
      );

  @override
  UserModel? get currentUser => _mockUser;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get isAuthenticated => _mockUser != null;

  @override
  Future<bool> loginAdmin(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    if (email == 'admin@mrcas.com' && password == 'admin123') {
      _mockUser = UserModel(
        uid: 'mock_admin_uid',
        name: 'Admin User',
        email: email,
        role: 'Admin',
        department: 'Physical Education',
        year: '',
        registerNumber: '',
        phone: '+91 98765 43210',
        profileImage: '',
        createdAt: DateTime.now(),
        status: 'active',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Invalid username or password';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> loginUser(
    String registerNumber,
    String phone,
    String password,
  ) async {
    _isLoading = true;
    notifyListeners();

    if (registerNumber == 'MRCAS2612' &&
        phone == '+91 98765 43210' &&
        password == 'student123') {
      _mockUser = UserModel(
        uid: 'mock_user_uid',
        name: 'Student Athlete',
        email: 'student@mrcas.com',
        role: 'Student',
        department: 'Sports Science',
        year: '3rd Year',
        registerNumber: 'MRCAS2612',
        phone: '+91 98765 43210',
        profileImage: '',
        createdAt: DateTime.now(),
        status: 'active',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Invalid username or password';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<String?> checkPersistedSession() async {
    return null;
  }
}

void main() {
  setUp(() {
    AppRouter.reset();
  });

  Future<void> pumpAppWithoutFirebase(
    WidgetTester tester,
    MockAuthProvider authProvider,
  ) async {
    await tester.pumpWidget(
      MyApp(authProvider: authProvider, enableRealtimeUpdates: false),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      AppRouter.router.dispose();
      AppRouter.reset();
    });
  }

  testWidgets(
    'Initializes and displays Sports Management System splash screen and navigates to home',
    (WidgetTester tester) async {
      final mockAuth = MockAuthProvider();
      // Build our app and trigger a frame.
      await pumpAppWithoutFirebase(tester, mockAuth);

      // Verify the splash screen elements are initially shown.
      expect(
        find.text('Manikam Ramaswami College of Arts & Science'),
        findsOneWidget,
      );
      expect(
        find.text('Department of Physical Education & Sports'),
        findsOneWidget,
      );

      // Advance virtual time by 3 seconds to trigger the auto-navigation timer.
      await tester.pump(const Duration(seconds: 3));
      // Re-pump to start transition, then pump 1 second to let transition finish and old screen dispose.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // An unauthenticated user is directed to the welcome portal.
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Login to Portal'), findsOneWidget);
    },
  );

  testWidgets('Full Admin Authentication flow integration test', (
    WidgetTester tester,
  ) async {
    final mockAuth = MockAuthProvider();
    // Build our app and trigger a frame.
    await pumpAppWithoutFirebase(tester, mockAuth);

    // Advance virtual time to navigate past the splash screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Open role selection from the unauthenticated welcome portal.
    final loginButtonFinder = find.text('Login to Portal');
    await tester.ensureVisible(loginButtonFinder);
    await tester.tap(loginButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Select Your Role'), findsOneWidget);
    expect(find.text('Admin Portal'), findsOneWidget);

    // Tap on the Admin Portal card text
    final adminCardFinder = find.text('Admin Portal');
    await tester.tap(adminCardFinder);
    await tester.pumpAndSettle();

    // Now we should be on the Admin Login screen.
    expect(find.text('Admin Login'), findsOneWidget);

    // Enter email formatted dummy credentials
    await tester.enterText(find.byType(TextFormField).first, 'admin@mrcas.com');
    await tester.enterText(find.byType(TextFormField).last, 'admin123');

    // Tap Submit Login
    final submitButtonFinder = find
        .widgetWithText(ElevatedButton, 'Login')
        .first;
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();

    // Verify it navigated to Admin Dashboard
    expect(find.text('Welcome Back, Admin'), findsOneWidget);
  });

  testWidgets('Full User Authentication flow integration test', (
    WidgetTester tester,
  ) async {
    final mockAuth = MockAuthProvider();
    // Build our app and trigger a frame.
    await pumpAppWithoutFirebase(tester, mockAuth);

    // Advance virtual time to navigate past the splash screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Open role selection from the unauthenticated welcome portal.
    final loginButtonFinder = find.text('Login to Portal');
    await tester.ensureVisible(loginButtonFinder);
    await tester.tap(loginButtonFinder);
    await tester.pumpAndSettle();

    // Select Student Portal card
    final studentCardFinder = find.text('User / Student Portal');
    await tester.tap(studentCardFinder);
    await tester.pumpAndSettle();

    // Enter the student login form's register number, phone, and password.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'MRCAS2612');
    await tester.enterText(fields.at(1), '+91 98765 43210');
    await tester.enterText(fields.at(2), 'student123');

    // Tap Submit Login
    final submitButtonFinder = find
        .widgetWithText(ElevatedButton, 'Login')
        .first;
    await tester.ensureVisible(submitButtonFinder);
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();

    // Verify it navigated to User Dashboard
    expect(find.text('Student Athlete Portal'), findsOneWidget);
  });
}

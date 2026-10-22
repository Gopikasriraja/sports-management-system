import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/auth/welcome_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/auth/admin_login_screen.dart';
import '../../screens/auth/user_login_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/sign_up_screen.dart';
import '../../screens/auth/email_verification_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/staff_dashboard_screen.dart';
import '../../screens/user/user_dashboard_screen.dart';
import '../../screens/chat/chatbot_screen.dart';
import '../../screens/teams/team_management_screen.dart';

class AppRouter {
  AppRouter._();

  // Route path constants
  static const String splash = '/';
  static const String home = '/home';
  static const String welcome = '/welcome';
  static const String auth = '/auth';
  static const String admin = '/admin';
  static const String staff = '/staff';
  static const String user = '/user';
  static const String chat = '/chat';
  static const String teams = '/teams';

  static GoRouter router = _buildRouter();

  static void reset() {
    router = _buildRouter();
  }

  static GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: splash,
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text('Page not found: ${state.uri}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => GoRouter.of(context).go('/welcome'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
      routes: [
        // ── Splash ─────────────────────────────────────────────────────────
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),

        // ── Public pages ───────────────────────────────────────────────────
        GoRoute(
          path: home,
          builder: (context, state) => const HomeScreen(),
        ),

        // ── Auth entry point ───────────────────────────────────────────────
        GoRoute(
          path: welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),

        // ── Auth flow ──────────────────────────────────────────────────────
        GoRoute(
          path: auth,
          builder: (context, state) => const LoginScreen(),
          routes: [
            GoRoute(
              path: 'role',
              builder: (context, state) => const RoleSelectionScreen(),
            ),
            GoRoute(
              path: 'admin',
              builder: (context, state) => const AdminLoginScreen(),
            ),
            GoRoute(
              path: 'user',
              builder: (context, state) => const UserLoginScreen(),
            ),
            GoRoute(
              path: 'forgot-password',
              builder: (context, state) => const ForgotPasswordScreen(),
            ),
            GoRoute(
              path: 'signup',
              builder: (context, state) => const SignUpScreen(),
            ),
            GoRoute(
              path: 'verify-email',
              builder: (context, state) {
                // Extra data passed from SignUpScreen: {email, password}
                final extra = state.extra as Map<String, dynamic>?;
                return EmailVerificationScreen(
                  email: extra?['email'] as String? ?? '',
                  password: extra?['password'] as String? ?? '',
                );
              },
            ),
          ],
        ),

        // ── Protected portals ──────────────────────────────────────────────
        GoRoute(
          path: admin,
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: staff,
          builder: (context, state) => const StaffDashboardScreen(),
        ),
        GoRoute(
          path: user,
          builder: (context, state) => const UserDashboardScreen(),
        ),
        GoRoute(
          path: chat,
          builder: (context, state) => const ChatbotScreen(),
        ),
        GoRoute(
          path: teams,
          builder: (context, state) => const TeamManagementScreen(),
        ),
      ],
    );
  }
}

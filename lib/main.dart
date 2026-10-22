import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/student_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/event_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/gallery_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/report_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/team_provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? initializationError;
  try {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase App Name: ${app.name}');
    debugPrint('Firebase Project ID: ${app.options.projectId}');
  } catch (error, stackTrace) {
    initializationError = error;
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  runApp(
    initializationError == null
        ? const MyApp()
        : FirebaseInitializationFailureApp(error: initializationError),
  );
}

class FirebaseInitializationFailureApp extends StatelessWidget {
  final Object? error;

  const FirebaseInitializationFailureApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 56,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase could not be initialized.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check the Firebase configuration for this platform and restart the app.\n\n$error',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final AuthProvider? authProvider;
  final bool enableRealtimeUpdates;

  const MyApp({
    super.key,
    this.authProvider,
    this.enableRealtimeUpdates = true,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => authProvider ?? AuthProvider(),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) =>
              UserProvider(listenToRealtimeUpdates: enableRealtimeUpdates),
        ),
        ChangeNotifierProvider<StudentProvider>(
          create: (_) =>
              StudentProvider(listenToRealtimeUpdates: enableRealtimeUpdates),
        ),
        ChangeNotifierProvider<AttendanceProvider>(
          create: (_) => AttendanceProvider(),
        ),
        ChangeNotifierProvider<EquipmentProvider>(
          create: (_) =>
              EquipmentProvider(listenToRealtimeUpdates: enableRealtimeUpdates),
        ),
        ChangeNotifierProvider<EventProvider>(
          create: (_) =>
              EventProvider(listenToRealtimeUpdates: enableRealtimeUpdates),
        ),
        ChangeNotifierProvider<AchievementProvider>(
          create: (_) => AchievementProvider(
            listenToRealtimeUpdates: enableRealtimeUpdates,
          ),
        ),
        ChangeNotifierProvider<GalleryProvider>(
          create: (_) =>
              GalleryProvider(listenToRealtimeUpdates: enableRealtimeUpdates),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(
            listenToRealtimeUpdates: enableRealtimeUpdates,
          ),
        ),
        ChangeNotifierProvider<ReportProvider>(
          create: (_) =>
              ReportProvider(listenToRealtimeUpdates: enableRealtimeUpdates),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<TeamProvider>(
          create: (_) =>
              TeamProvider(listenToRealtimeUpdates: enableRealtimeUpdates),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp.router(
          title: 'MRCAS Sports Management System',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}

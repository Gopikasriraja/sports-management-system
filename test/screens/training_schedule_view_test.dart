import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sports_management_system/database/repositories/training_session_repository.dart';
import 'package:sports_management_system/models/training_session_model.dart';
import 'package:sports_management_system/providers/auth_provider.dart';
import 'package:sports_management_system/providers/training_session_provider.dart';
import 'package:sports_management_system/screens/user/widgets/training_schedule_view.dart';

class _TrainingSessionRepository extends TrainingSessionRepository {
  @override
  Stream<List<TrainingSession>> streamSessions() => Stream.value([_session]);
}

final _session = TrainingSession(
  sessionId: 'session-1',
  sport: 'Football',
  team: 'Varsity',
  coach: 'Coach Lee',
  venue: 'Main Ground',
  startsAt: DateTime(2026, 10, 24, 9),
  endsAt: DateTime(2026, 10, 24, 10),
  notes: 'Bring water',
  status: 'Scheduled',
);

void main() {
  testWidgets('students can view sessions without schedule controls', (
    tester,
  ) async {
    final authProvider = AuthProvider();
    final sessionProvider = TrainingSessionProvider(
      repository: _TrainingSessionRepository(),
    );
    addTearDown(authProvider.dispose);
    addTearDown(sessionProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: sessionProvider),
        ],
        child: const MaterialApp(home: Scaffold(body: TrainingScheduleView())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Football'), findsOneWidget);
    expect(find.textContaining('Coach: Coach Lee'), findsOneWidget);
    expect(find.textContaining('Main Ground'), findsOneWidget);
    expect(find.text('Bring water'), findsOneWidget);
    expect(find.text('Schedule training'), findsNothing);
  });
}

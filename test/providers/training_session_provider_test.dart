import 'package:flutter_test/flutter_test.dart';
import 'package:sports_management_system/database/repositories/training_session_repository.dart';
import 'package:sports_management_system/models/training_session_model.dart';
import 'package:sports_management_system/providers/training_session_provider.dart';

class _TrainingSessionRepository extends TrainingSessionRepository {
  final savedSessions = <TrainingSession>[];
  final deletedIds = <String>[];

  @override
  Future<String> saveSession(TrainingSession session) async {
    savedSessions.add(session);
    return session.sessionId.isEmpty ? 'session-1' : session.sessionId;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    deletedIds.add(sessionId);
  }
}

void main() {
  final session = TrainingSession(
    sessionId: '',
    sport: 'Football',
    team: '',
    coach: 'Coach Lee',
    venue: 'Main Ground',
    startsAt: DateTime(2026, 10, 24, 9),
    endsAt: DateTime(2026, 10, 24, 10),
    notes: '',
    status: 'Scheduled',
  );

  test('denies students and reports the authorization failure', () async {
    final repository = _TrainingSessionRepository();
    final provider = TrainingSessionProvider(
      repository: repository,
      listenToRealtimeUpdates: false,
    );
    addTearDown(provider.dispose);

    expect(await provider.saveSession(session, actorRole: 'Student'), isFalse);
    expect(provider.errorMessage, contains('not authorized'));
    expect(repository.savedSessions, isEmpty);
  });

  test(
    'saves valid sessions and exposes them without a realtime listener',
    () async {
      final repository = _TrainingSessionRepository();
      final provider = TrainingSessionProvider(
        repository: repository,
        listenToRealtimeUpdates: false,
      );
      addTearDown(provider.dispose);

      expect(
        await provider.saveSession(session, actorRole: 'Sports Staff'),
        isTrue,
      );
      expect(provider.sessions.single.sessionId, 'session-1');
      expect(provider.errorMessage, isNull);

      expect(
        await provider.deleteSession('session-1', actorRole: 'Sports Staff'),
        isTrue,
      );
      expect(repository.deletedIds, ['session-1']);
      expect(provider.sessions, isEmpty);
    },
  );
}

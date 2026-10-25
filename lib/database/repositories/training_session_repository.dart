import '../../models/training_session_model.dart';
import '../services/training_session_service.dart';

class TrainingSessionRepository {
  final TrainingSessionService _service;

  TrainingSessionRepository({TrainingSessionService? service})
    : _service = service ?? TrainingSessionService();

  Stream<List<TrainingSession>> streamSessions() => _service.streamSessions();

  Future<List<TrainingSession>> getSessions() => _service.getSessions();

  Future<String> saveSession(TrainingSession session) =>
      _service.saveSession(session);

  Future<void> deleteSession(String sessionId) =>
      _service.deleteSession(sessionId);
}

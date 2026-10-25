import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/training_session_model.dart';

class TrainingSessionService {
  final FirebaseFirestore? _firestore;

  TrainingSessionService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      db.collection('training_sessions');

  Stream<List<TrainingSession>> streamSessions() {
    return _sessions.orderBy('startsAt').snapshots().map(
      (snapshot) => snapshot.docs
          .map(TrainingSession.fromFirestore)
          .toList(growable: false),
    );
  }

  Future<List<TrainingSession>> getSessions() async {
    final snapshot = await _sessions.orderBy('startsAt').get();
    return snapshot.docs
        .map(TrainingSession.fromFirestore)
        .toList(growable: false);
  }

  Future<String> saveSession(TrainingSession session) async {
    final document = session.sessionId.isEmpty
        ? _sessions.doc()
        : _sessions.doc(session.sessionId);
    await document.set(session.copyWith(sessionId: document.id).toMap());
    return document.id;
  }

  Future<void> deleteSession(String sessionId) =>
      _sessions.doc(sessionId).delete();
}

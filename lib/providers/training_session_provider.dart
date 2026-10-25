import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_roles.dart';
import '../core/validation/training_session_validator.dart';
import '../database/repositories/training_session_repository.dart';
import '../models/training_session_model.dart';

class TrainingSessionProvider extends ChangeNotifier {
  final TrainingSessionRepository _repository;
  StreamSubscription<List<TrainingSession>>? _subscription;

  TrainingSessionProvider({
    TrainingSessionRepository? repository,
    bool listenToRealtimeUpdates = true,
  }) : _repository = repository ?? TrainingSessionRepository() {
    if (listenToRealtimeUpdates) {
      _subscription = _repository.streamSessions().listen(
        (sessions) {
          _sessions = sessions;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (Object error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } else {
      _isLoading = false;
    }
  }

  List<TrainingSession> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<TrainingSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _sessions = await _repository.getSessions();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSession(
    TrainingSession session, {
    required String actorRole,
  }) async {
    if (!AppRoles.canManageTrainingSessions(actorRole)) {
      _errorMessage = 'You are not authorized to manage training sessions.';
      notifyListeners();
      return false;
    }
    final validationError = TrainingSessionValidator.validate(session);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final sessionId = await _repository.saveSession(session);
      _sessions = [
        ..._sessions.where((item) => item.sessionId != sessionId),
        session.copyWith(sessionId: sessionId),
      ]..sort((first, second) => first.startsAt.compareTo(second.startsAt));
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSession(
    String sessionId, {
    required String actorRole,
  }) async {
    if (!AppRoles.canManageTrainingSessions(actorRole)) {
      _errorMessage = 'You are not authorized to manage training sessions.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteSession(sessionId);
      _sessions = _sessions
          .where((session) => session.sessionId != sessionId)
          .toList(growable: false);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

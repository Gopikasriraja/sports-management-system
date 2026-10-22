import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_roles.dart';
import '../core/validation/team_validator.dart';
import '../database/repositories/team_repository.dart';
import '../models/student_model.dart';
import '../models/team_model.dart';

class TeamProvider extends ChangeNotifier {
  final TeamRepository _repository;
  StreamSubscription<List<TeamModel>>? _subscription;

  TeamProvider({
    TeamRepository? repository,
    bool listenToRealtimeUpdates = true,
  })
    : _repository = repository ?? TeamRepository() {
    if (listenToRealtimeUpdates) {
      _subscription = _repository.streamTeams().listen(
        (teams) {
          _teams = teams;
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

  List<TeamModel> _teams = [];
  final Map<String, List<StudentModel>> _members = {};
  bool _isLoading = true;
  String? _errorMessage;

  List<TeamModel> get teams => List.unmodifiable(_teams);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<StudentModel> membersFor(String teamId) =>
      List.unmodifiable(_members[teamId] ?? const []);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<List<TeamModel>> getTeamsForStudent({
    required String studentId,
    required String actorUid,
    required String actorRole,
  }) async {
    try {
      return await _repository.getTeamsForStudent(
        studentId,
        actorUid: actorUid,
        actorRole: actorRole,
      );
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadMembers({
    required String teamId,
    required String actorUid,
    required String actorRole,
  }) async {
    if (!AppRoles.canManageTeams(actorRole)) {
      throw StateError('You are not authorized to view team rosters.');
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _members[teamId] = await _repository.getMembers(
        teamId,
        actorUid: actorUid,
        actorRole: actorRole,
      );
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> saveTeam(
    TeamModel team, {
    required String actorUid,
    required String actorRole,
  }) async {
    if (!AppRoles.canManageTeams(actorRole)) {
      _errorMessage = 'You are not authorized to manage teams.';
      notifyListeners();
      return null;
    }
    final nameError = TeamValidator.validateName(team.name);
    final sportError = TeamValidator.validateSport(team.sport);
    if (nameError != null || sportError != null) {
      _errorMessage = nameError ?? sportError;
      notifyListeners();
      return null;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final id = await _repository.saveTeam(
        team,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      return id;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setMembership({
    required String teamId,
    required String studentId,
    required bool isMember,
    required String actorUid,
    required String actorRole,
  }) async {
    if (!AppRoles.canManageTeams(actorRole)) {
      _errorMessage = 'You are not authorized to manage team rosters.';
      notifyListeners();
      return false;
    }
    if (isMember &&
        TeamValidator.hasDuplicateMember(
          (_members[teamId] ?? const []).map((student) => student.studentId),
          studentId,
        )) {
      _errorMessage = 'This student is already on the team.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.setMember(
        teamId: teamId,
        studentId: studentId,
        isMember: isMember,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      await loadMembers(
        teamId: teamId,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deactivateTeam(
    String teamId, {
    required String actorUid,
    required String actorRole,
  }) async {
    if (!AppRoles.canManageTeams(actorRole)) {
      _errorMessage = 'You are not authorized to manage teams.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deactivateTeam(
        teamId,
        actorUid: actorUid,
        actorRole: actorRole,
      );
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _teams = await _repository.getAllTeams();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

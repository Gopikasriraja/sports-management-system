import 'dart:async';
import 'package:flutter/material.dart';
import '../database/repositories/achievement_repository.dart';
import '../models/achievement_model.dart';

class AchievementProvider extends ChangeNotifier {
  final AchievementRepository _achievementRepository;
  StreamSubscription? _achievementSub;

  AchievementProvider({
    AchievementRepository? achievementRepository,
    bool listenToRealtimeUpdates = true,
  })
      : _achievementRepository = achievementRepository ?? AchievementRepository() {
    if (listenToRealtimeUpdates) _initRealtimeListeners();
  }

  void _initRealtimeListeners() {
    _isLoading = true;
    _achievementSub = _achievementRepository.streamAchievements().listen((list) {
      _achievements = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _achievementSub?.cancel();
    super.dispose();
  }

  bool _isLoading = false;
  String? _errorMessage;
  List<AchievementModel> _achievements = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AchievementModel> get achievements => _achievements;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchAchievementsForStudent(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _achievements = await _achievementRepository.getAchievementsForStudent(studentId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllAchievements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _achievements = await _achievementRepository.getAllAchievements();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAchievementsBySport(String sport) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _achievements = await _achievementRepository.getAchievementsBySport(sport);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveAchievement(AchievementModel achievement) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _achievementRepository.saveAchievement(achievement);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAchievement(String achievementId, String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _achievementRepository.deleteAchievement(achievementId);
      await fetchAchievementsForStudent(studentId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

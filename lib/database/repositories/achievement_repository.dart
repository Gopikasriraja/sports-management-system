import '../../models/achievement_model.dart';
import '../services/achievement_service.dart';

class AchievementRepository {
  final AchievementService _achievementService;

  AchievementRepository({AchievementService? achievementService})
      : _achievementService = achievementService ?? AchievementService();

  Future<void> saveAchievement(AchievementModel achievement) =>
      _achievementService.saveAchievement(achievement);

  Future<void> deleteAchievement(String achievementId) => _achievementService.deleteAchievement(achievementId);

  Future<List<AchievementModel>> getAllAchievements() => _achievementService.getAllAchievements();

  Future<List<AchievementModel>> getAchievementsForStudent(String studentId) =>
      _achievementService.getAchievementsForStudent(studentId);

  Future<List<AchievementModel>> getAchievementsBySport(String sport) =>
      _achievementService.getAchievementsBySport(sport);

  Stream<List<AchievementModel>> streamAchievements() => _achievementService.streamAchievements();
}

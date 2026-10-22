import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/achievement_model.dart';

class AchievementService {
  final FirebaseFirestore? _firestore;

  AchievementService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  // Save achievement
  Future<void> saveAchievement(AchievementModel achievement) async {
    try {
      await db
          .collection('achievements')
          .doc(achievement.achievementId)
          .set(achievement.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save achievement: $e');
    }
  }

  // Delete achievement
  Future<void> deleteAchievement(String achievementId) async {
    try {
      await db.collection('achievements').doc(achievementId).delete();
    } catch (e) {
      throw Exception('Failed to delete achievement: $e');
    }
  }

  // Fetch all achievements
  Future<List<AchievementModel>> getAllAchievements() async {
    try {
      final snapshot = await db.collection('achievements').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => AchievementModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all achievements: $e');
    }
  }

  // Fetch achievements for student
  Future<List<AchievementModel>> getAchievementsForStudent(String studentId) async {
    try {
      final snapshot = await db
          .collection('achievements')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => AchievementModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch student achievements: $e');
    }
  }

  // Fetch achievements by sport
  Future<List<AchievementModel>> getAchievementsBySport(String sport) async {
    try {
      final snapshot = await db
          .collection('achievements')
          .where('sport', isEqualTo: sport)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => AchievementModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch achievements by sport: $e');
    }
  }

  // Stream achievements
  Stream<List<AchievementModel>> streamAchievements() {
    return db.collection('achievements').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AchievementModel.fromFirestore(doc)).toList();
    });
  }
}

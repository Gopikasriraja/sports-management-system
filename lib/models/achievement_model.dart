import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String achievementId;
  final String studentId;
  final String sport;
  final String event;
  final String medal;
  final String level;
  final String year;
  final String certificateImage;
  final DateTime createdAt;

  AchievementModel({
    required this.achievementId,
    required this.studentId,
    required this.sport,
    required this.event,
    required this.medal,
    required this.level,
    required this.year,
    required this.certificateImage,
    required this.createdAt,
  });

  AchievementModel copyWith({
    String? achievementId,
    String? studentId,
    String? sport,
    String? event,
    String? medal,
    String? level,
    String? year,
    String? certificateImage,
    DateTime? createdAt,
  }) {
    return AchievementModel(
      achievementId: achievementId ?? this.achievementId,
      studentId: studentId ?? this.studentId,
      sport: sport ?? this.sport,
      event: event ?? this.event,
      medal: medal ?? this.medal,
      level: level ?? this.level,
      year: year ?? this.year,
      certificateImage: certificateImage ?? this.certificateImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AchievementModel.fromMap(data, doc.id);
  }

  factory AchievementModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return AchievementModel(
      achievementId: id,
      studentId: data['studentId'] ?? '',
      sport: data['sport'] ?? '',
      event: data['event'] ?? '',
      medal: data['medal'] ?? '',
      level: data['level'] ?? '',
      year: data['year']?.toString() ?? '',
      certificateImage: data['certificateImage'] ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'studentId': studentId,
      'sport': sport,
      'event': event,
      'medal': medal,
      'level': level,
      'year': year,
      'certificateImage': certificateImage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String toJson() => json.encode(toMap());

  factory AchievementModel.fromJson(String source, String id) =>
      AchievementModel.fromMap(json.decode(source) as Map<String, dynamic>, id);
}

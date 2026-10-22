import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String title;
  final String message;
  final DateTime createdAt;
  final String createdBy;

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.createdBy,
  });

  NotificationModel copyWith({
    String? notificationId,
    String? title,
    String? message,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel.fromMap(data, doc.id);
  }

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return NotificationModel(
      notificationId: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: parseDate(data['createdAt']),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  String toJson() => json.encode(toMap());

  factory NotificationModel.fromJson(String source, String id) =>
      NotificationModel.fromMap(json.decode(source) as Map<String, dynamic>, id);
}

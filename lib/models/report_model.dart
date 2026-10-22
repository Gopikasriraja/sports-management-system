import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String title;
  final String type;
  final String generatedBy;
  final DateTime generatedAt;

  ReportModel({
    required this.reportId,
    required this.title,
    required this.type,
    required this.generatedBy,
    required this.generatedAt,
  });

  ReportModel copyWith({
    String? reportId,
    String? title,
    String? type,
    String? generatedBy,
    DateTime? generatedAt,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      title: title ?? this.title,
      type: type ?? this.type,
      generatedBy: generatedBy ?? this.generatedBy,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReportModel.fromMap(data, doc.id);
  }

  factory ReportModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return ReportModel(
      reportId: id,
      title: data['title'] ?? '',
      type: data['type'] ?? '',
      generatedBy: data['generatedBy'] ?? '',
      generatedAt: parseDate(data['generatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'title': title,
      'type': type,
      'generatedBy': generatedBy,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }

  String toJson() => json.encode(toMap());

  factory ReportModel.fromJson(String source, String id) =>
      ReportModel.fromMap(json.decode(source) as Map<String, dynamic>, id);
}

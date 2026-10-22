import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String attendanceId;
  final String studentId;
  final String studentName;
  final String department;
  final String sport;
  final DateTime date;
  final String status;
  final String markedBy;
  final DateTime createdAt;
  final String sessionId;
  final String registerNumber;
  final String updatedBy;
  final DateTime? updatedAt;
  final String correctionReason;

  AttendanceModel({
    required this.attendanceId,
    required this.studentId,
    required this.studentName,
    required this.department,
    required this.sport,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.createdAt,
    this.sessionId = '',
    this.registerNumber = '',
    this.updatedBy = '',
    this.updatedAt,
    this.correctionReason = '',
  });

  AttendanceModel copyWith({
    String? attendanceId,
    String? studentId,
    String? studentName,
    String? department,
    String? sport,
    DateTime? date,
    String? status,
    String? markedBy,
    DateTime? createdAt,
    String? sessionId,
    String? registerNumber,
    String? updatedBy,
    DateTime? updatedAt,
    String? correctionReason,
  }) {
    return AttendanceModel(
      attendanceId: attendanceId ?? this.attendanceId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      department: department ?? this.department,
      sport: sport ?? this.sport,
      date: date ?? this.date,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      createdAt: createdAt ?? this.createdAt,
      sessionId: sessionId ?? this.sessionId,
      registerNumber: registerNumber ?? this.registerNumber,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      correctionReason: correctionReason ?? this.correctionReason,
    );
  }

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AttendanceModel.fromMap(data, doc.id);
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return AttendanceModel(
      attendanceId: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Unknown',
      department: data['department'] ?? 'Unknown',
      sport: data['sport'] ?? '',
      date: parseDate(data['date']),
      status: data['status'] ?? '',
      markedBy: data['markedBy'] ?? '',
      createdAt: parseDate(data['createdAt']),
      sessionId: data['sessionId'] as String? ?? '',
      registerNumber: data['registerNumber'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      updatedAt: data['updatedAt'] == null ? null : parseDate(data['updatedAt']),
      correctionReason: data['correctionReason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'studentId': studentId,
      'studentName': studentName,
      'department': department,
      'sport': sport,
      'date': Timestamp.fromDate(date),
      'status': status,
      'markedBy': markedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'sessionId': sessionId,
      'registerNumber': registerNumber,
      'updatedBy': updatedBy,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'correctionReason': correctionReason,
    };
  }

  String toJson() => json.encode(toMap());

  factory AttendanceModel.fromJson(String source, String id) =>
      AttendanceModel.fromMap(json.decode(source) as Map<String, dynamic>, id);
}

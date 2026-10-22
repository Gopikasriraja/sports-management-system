import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSessionModel {
  final String sessionId;
  final String title;
  final String sport;
  final String teamId;
  final String teamName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String venue;
  final String status;
  final String responsibleUid;
  final String responsibleName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceSessionModel({
    required this.sessionId,
    required this.title,
    required this.sport,
    this.teamId = '',
    this.teamName = '',
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.status,
    required this.responsibleUid,
    required this.responsibleName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceSessionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    DateTime readDate(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime(1970);
      return DateTime(1970);
    }

    return AttendanceSessionModel(
      sessionId: snapshot.id,
      title: data['title'] as String? ?? '',
      sport: data['sport'] as String? ?? '',
      teamId: data['teamId'] as String? ?? '',
      teamName: data['teamName'] as String? ?? '',
      date: readDate(data['date']),
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      venue: data['venue'] as String? ?? '',
      status: data['status'] as String? ?? 'scheduled',
      responsibleUid: data['responsibleUid'] as String? ?? '',
      responsibleName: data['responsibleName'] as String? ?? '',
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
    );
  }

  Map<String, Object?> toMap() => {
    'title': title.trim(),
    'sport': sport.trim(),
    'teamId': teamId,
    'teamName': teamName.trim(),
    'date': Timestamp.fromDate(date),
    'startTime': startTime.trim(),
    'endTime': endTime.trim(),
    'venue': venue.trim(),
    'status': status,
    'responsibleUid': responsibleUid,
    'responsibleName': responsibleName.trim(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  AttendanceSessionModel copyWith({
    String? sessionId,
    String? title,
    String? sport,
    String? teamId,
    String? teamName,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? venue,
    String? status,
    String? responsibleUid,
    String? responsibleName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AttendanceSessionModel(
    sessionId: sessionId ?? this.sessionId,
    title: title ?? this.title,
    sport: sport ?? this.sport,
    teamId: teamId ?? this.teamId,
    teamName: teamName ?? this.teamName,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    venue: venue ?? this.venue,
    status: status ?? this.status,
    responsibleUid: responsibleUid ?? this.responsibleUid,
    responsibleName: responsibleName ?? this.responsibleName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

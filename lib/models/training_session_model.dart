import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingSession {
  final String sessionId;
  final String sport;
  final String team;
  final String coach;
  final String venue;
  final DateTime startsAt;
  final DateTime endsAt;
  final String notes;
  final String status;

  const TrainingSession({
    required this.sessionId,
    required this.sport,
    required this.team,
    required this.coach,
    required this.venue,
    required this.startsAt,
    required this.endsAt,
    required this.notes,
    required this.status,
  });

  TrainingSession copyWith({
    String? sessionId,
    String? sport,
    String? team,
    String? coach,
    String? venue,
    DateTime? startsAt,
    DateTime? endsAt,
    String? notes,
    String? status,
  }) {
    return TrainingSession(
      sessionId: sessionId ?? this.sessionId,
      sport: sport ?? this.sport,
      team: team ?? this.team,
      coach: coach ?? this.coach,
      venue: venue ?? this.venue,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  factory TrainingSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TrainingSession(
      sessionId: doc.id,
      sport: data['sport'] as String? ?? '',
      team: data['team'] as String? ?? '',
      coach: data['coach'] as String? ?? '',
      venue: data['venue'] as String? ?? '',
      startsAt: _parseDate(data['startsAt'], 'startsAt'),
      endsAt: _parseDate(data['endsAt'], 'endsAt'),
      notes: data['notes'] as String? ?? '',
      status: data['status'] as String? ?? 'Scheduled',
    );
  }

  static DateTime _parseDate(dynamic value, String field) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Training session has an invalid $field value.');
  }

  Map<String, dynamic> toMap() => {
    'sessionId': sessionId,
    'sport': sport.trim(),
    'team': team.trim(),
    'coach': coach.trim(),
    'venue': venue.trim(),
    'startsAt': Timestamp.fromDate(startsAt),
    'endsAt': Timestamp.fromDate(endsAt),
    'notes': notes.trim(),
    'status': status,
  };
}

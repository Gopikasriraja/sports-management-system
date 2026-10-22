import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String teamId;
  final String name;
  final String sport;
  final String coachName;
  final String captainName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamModel({
    required this.teamId,
    required this.name,
    required this.sport,
    this.coachName = '',
    this.captainName = '',
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    DateTime readDate(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return TeamModel(
      teamId: snapshot.id,
      name: data['name'] as String? ?? '',
      sport: data['sport'] as String? ?? '',
      coachName: data['coachName'] as String? ?? '',
      captainName: data['captainName'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
    );
  }

  Map<String, Object?> toMap() => {
    'name': name.trim(),
    'nameNormalized': name.trim().toLowerCase(),
    'sport': sport.trim(),
    'sportNormalized': sport.trim().toLowerCase(),
    'coachName': coachName.trim(),
    'captainName': captainName.trim(),
    'status': status.toLowerCase(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  TeamModel copyWith({
    String? name,
    String? sport,
    String? coachName,
    String? captainName,
    String? status,
    DateTime? updatedAt,
  }) => TeamModel(
    teamId: teamId,
    name: name ?? this.name,
    sport: sport ?? this.sport,
    coachName: coachName ?? this.coachName,
    captainName: captainName ?? this.captainName,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

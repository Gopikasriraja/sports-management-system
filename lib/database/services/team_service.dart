import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_roles.dart';
import '../../core/validation/team_validator.dart';
import '../../models/student_model.dart';
import '../../models/team_model.dart';
import 'firestore_authorization.dart';

class TeamService {
  final FirebaseFirestore? _firestore;

  TeamService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _teams =>
      db.collection('sports_teams');

  CollectionReference<Map<String, dynamic>> get _memberships =>
      db.collection('team_memberships');

  Stream<List<TeamModel>> streamTeams() => _teams
      .orderBy('nameNormalized')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(TeamModel.fromFirestore).toList());

  Future<String> saveTeam(
    TeamModel team, {
    required String actorUid,
    required String actorRole,
  }) async {
    await _requireTeamManager(actorUid, actorRole);
    final validationError =
        TeamValidator.validateName(team.name) ??
        TeamValidator.validateSport(team.sport);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    final teamRef = team.teamId.isEmpty ? _teams.doc() : _teams.doc(team.teamId);
    final normalizedName = team.name.trim().toLowerCase();
    final normalizedSport = team.sport.trim().toLowerCase();
    final existingTeams = await _teams.get();
    if (existingTeams.docs.any((doc) {
      if (doc.id == teamRef.id) return false;
      final data = doc.data();
      final name =
          data['nameNormalized'] as String? ??
          (data['name'] as String? ?? '').trim().toLowerCase();
      final sport =
          data['sportNormalized'] as String? ??
          (data['sport'] as String? ?? '').trim().toLowerCase();
      return name == normalizedName && sport == normalizedSport;
    })) {
      throw StateError('A team with this name and sport already exists.');
    }
    final reservationRef = db
        .collection('sports_team_names')
        .doc(TeamValidator.reservationId(normalizedName, normalizedSport));
    await db.runTransaction((transaction) async {
      final reservation = await transaction.get(reservationRef);
      final existingTeam = team.teamId.isNotEmpty
          ? await transaction.get(teamRef)
          : null;
      if (team.teamId.isNotEmpty) {
        if (existingTeam?.exists != true) {
          throw StateError('The team no longer exists.');
        }
      }
      final reservedTeamId = reservation.data()?['teamId'] as String?;
      if (reservation.exists && reservedTeamId != teamRef.id) {
        throw StateError('A team with this name and sport already exists.');
      }
      final oldName = (existingTeam?.data()?['name'] as String? ?? '')
          .trim()
          .toLowerCase();
      final oldSport = (existingTeam?.data()?['sport'] as String? ?? '')
          .trim()
          .toLowerCase();
      final oldReservationRef = oldName.isEmpty ||
              oldSport.isEmpty ||
              (oldName == normalizedName && oldSport == normalizedSport)
          ? null
          : db
                .collection('sports_team_names')
                .doc(TeamValidator.reservationId(oldName, oldSport));
      final oldReservation = oldReservationRef == null
          ? null
          : await transaction.get(oldReservationRef);
      transaction.set(reservationRef, {
        'teamId': teamRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (oldReservationRef != null &&
          oldReservation?.data()?['teamId'] == teamRef.id) {
        transaction.delete(oldReservationRef);
      }
      transaction.set(
        teamRef,
        team.copyWith(updatedAt: DateTime.now()).toMap(),
        SetOptions(merge: true),
      );
    });
    return teamRef.id;
  }

  Future<List<TeamModel>> getTeamsForStudent(
    String studentId, {
    required String actorUid,
    required String actorRole,
  }) async {
    await FirestoreAuthorization.requireActiveActor(
      db: db,
      actorUid: actorUid,
      actorRole: actorRole,
    );
    final isSelfStudent =
        actorRole == AppRoles.student && actorUid == studentId;
    if (!isSelfStudent && !AppRoles.canManageTeams(actorRole)) {
      throw StateError('You are not authorized to view this membership.');
    }
    final memberships = await _memberships
        .where('studentId', isEqualTo: studentId)
        .get();
    final teamIds = memberships.docs
        .map((doc) => doc.data()['teamId'] as String?)
        .whereType<String>()
        .toSet();
    if (teamIds.isEmpty) return [];
    final teams = await Future.wait(
      teamIds.map((id) => _teams.doc(id).get()),
    );
    return teams
        .where((team) => team.exists)
        .map(TeamModel.fromFirestore)
        .where((team) => team.status.toLowerCase() == 'active')
        .toList()
      ..sort((first, second) => first.name.compareTo(second.name));
  }

  Future<List<String>> getMemberIds(
    String teamId, {
    required String actorUid,
    required String actorRole,
  }) async {
    await _requireTeamManager(actorUid, actorRole);
    return _readMemberIds(teamId);
  }

  Future<List<String>> _readMemberIds(String teamId) async {
    final snapshot = await _memberships
        .where('teamId', isEqualTo: teamId)
        .get();
    return snapshot.docs
        .map((doc) => doc.data()['studentId'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<void> setMember({
    required String teamId,
    required String studentId,
    required bool isMember,
    required String actorUid,
    required String actorRole,
  }) async {
    await _requireTeamManager(actorUid, actorRole);
    final teamRef = _teams.doc(teamId);
    final studentRef = db.collection('students').doc(studentId);
    final membershipRef = _memberships.doc('$teamId--$studentId');
    await db.runTransaction((transaction) async {
      final teamSnapshot = await transaction.get(teamRef);
      final membershipSnapshot = await transaction.get(membershipRef);
      if (!teamSnapshot.exists) throw StateError('The team no longer exists.');
      if (isMember) {
        if (membershipSnapshot.exists) {
          throw StateError('This student is already on the team.');
        }
        final studentSnapshot = await transaction.get(studentRef);
        if (!studentSnapshot.exists ||
            (studentSnapshot.data()?['status'] as String? ?? 'active')
                    .toLowerCase() !=
                'active') {
          throw StateError('Only active student records can join a team.');
        }
        transaction.set(membershipRef, {
          'teamId': teamId,
          'studentId': studentId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        if (!membershipSnapshot.exists) {
          throw StateError('The student is not a member of this team.');
        }
        transaction.delete(membershipRef);
      }
    });
  }

  Future<void> deactivateTeam(
    String teamId, {
    required String actorUid,
    required String actorRole,
  }) async {
    await _requireTeamManager(actorUid, actorRole);
    await _teams.doc(teamId).update({
      'status': 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<TeamModel>> getAllTeams() async {
    final snapshot = await _teams.orderBy('nameNormalized').get();
    return snapshot.docs.map(TeamModel.fromFirestore).toList();
  }

  Future<List<StudentModel>> getMembers(
    String teamId, {
    required String actorUid,
    required String actorRole,
  }) async {
    await _requireTeamManager(actorUid, actorRole);
    final memberIds = await _readMemberIds(teamId);
    if (memberIds.isEmpty) return [];
    final studentSnapshots = await Future.wait(
      memberIds.map((id) => db.collection('students').doc(id).get()),
    );
    return studentSnapshots
        .where((snapshot) => snapshot.exists)
        .map(StudentModel.fromFirestore)
        .toList();
  }

  Future<void> _requireTeamManager(String actorUid, String actorRole) async {
    await FirestoreAuthorization.requireActiveActor(
      db: db,
      actorUid: actorUid,
      actorRole: actorRole,
    );
    if (!AppRoles.canManageTeams(actorRole)) {
      throw StateError('You are not authorized to manage sports teams.');
    }
  }
}

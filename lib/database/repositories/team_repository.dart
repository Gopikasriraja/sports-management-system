import '../../models/student_model.dart';
import '../../models/team_model.dart';
import '../services/team_service.dart';

class TeamRepository {
  final TeamService _service;

  TeamRepository({TeamService? service}) : _service = service ?? TeamService();

  Stream<List<TeamModel>> streamTeams() => _service.streamTeams();

  Future<String> saveTeam(
    TeamModel team, {
    required String actorUid,
    required String actorRole,
  }) => _service.saveTeam(
    team,
    actorUid: actorUid,
    actorRole: actorRole,
  );

  Future<List<TeamModel>> getTeamsForStudent(
    String studentId, {
    required String actorUid,
    required String actorRole,
  }) => _service.getTeamsForStudent(
    studentId,
    actorUid: actorUid,
    actorRole: actorRole,
  );

  Future<List<String>> getMemberIds(
    String teamId, {
    required String actorUid,
    required String actorRole,
  }) => _service.getMemberIds(
    teamId,
    actorUid: actorUid,
    actorRole: actorRole,
  );

  Future<List<StudentModel>> getMembers(
    String teamId, {
    required String actorUid,
    required String actorRole,
  }) => _service.getMembers(
    teamId,
    actorUid: actorUid,
    actorRole: actorRole,
  );

  Future<void> setMember({
    required String teamId,
    required String studentId,
    required bool isMember,
    required String actorUid,
    required String actorRole,
  }) => _service.setMember(
    teamId: teamId,
    studentId: studentId,
    isMember: isMember,
    actorUid: actorUid,
    actorRole: actorRole,
  );

  Future<void> deactivateTeam(
    String teamId, {
    required String actorUid,
    required String actorRole,
  }) => _service.deactivateTeam(
    teamId,
    actorUid: actorUid,
    actorRole: actorRole,
  );

  Future<List<TeamModel>> getAllTeams() => _service.getAllTeams();
}

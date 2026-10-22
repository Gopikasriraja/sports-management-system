import '../../models/user_model.dart';
import '../services/user_service.dart';

class UserRepository {
  final UserService _userService;

  UserRepository({UserService? userService}) : _userService = userService ?? UserService();

  Future<UserModel?> getUser(String uid) => _userService.getUser(uid);

  Future<void> saveUser(
    UserModel user, {
    required String actorUid,
    required String actorRole,
  }) => _userService.saveUser(
    user,
    actorUid: actorUid,
    actorRole: actorRole,
  );

  Future<void> updateUserSafely(
    UserModel user, {
    required String actorUid,
    required String actorRole,
  }) => _userService.updateUserSafely(
    user,
    actorUid: actorUid,
    actorRole: actorRole,
  );

  Future<void> deleteUser(
    String uid, {
    required String actorUid,
    required String actorRole,
  }) => _userService.deleteUser(
    uid,
    actorUid: actorUid,
    actorRole: actorRole,
  );

  Future<List<UserModel>> getAllUsers() => _userService.getAllUsers();

  Stream<List<UserModel>> streamUsers() => _userService.streamUsers();

  Future<List<UserModel>> getUsersByRole(String role) => _userService.getUsersByRole(role);
}

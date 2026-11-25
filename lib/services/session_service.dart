import '../database/database_helper.dart';
import '../models/user_model.dart';

class SessionService {
  SessionService({DatabaseHelper? database})
    : _database = database ?? DatabaseHelper.instance;

  final DatabaseHelper _database;

  Future<UserModel?> getRememberedUser() => _database.getRememberedUser();

  Future<void> rememberUser(UserModel user) =>
      _database.saveRememberedUser(user.id);

  Future<void> clearSession() => _database.clearRememberedUser();
}

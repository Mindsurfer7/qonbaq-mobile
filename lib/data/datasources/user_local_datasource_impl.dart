import '../datasources/user_local_datasource.dart';
import '../models/user_model.dart';

/// Реализация локального источника данных для пользователей
/// Использует простую in-memory хранилище
class UserLocalDataSourceImpl extends UserLocalDataSource {
  final Map<String, UserModel> _users = {};

  @override
  Future<UserModel?> getUserById(String id) async {
    return _users[id];
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    return _users.values.toList();
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> cacheUsers(List<UserModel> users) async {
    for (final user in users) {
      _users[user.id] = user;
    }
  }
}



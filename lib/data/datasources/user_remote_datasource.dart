import '../datasources/datasource.dart';
import '../models/user_model.dart';
import '../models/business_model.dart';
import '../models/user_profile_model.dart';

/// Удаленный источник данных для пользователей (API)
/// В реальном проекте здесь будут HTTP запросы
abstract class UserRemoteDataSource extends DataSource {
  /// Получить пользователя по ID с сервера
  Future<UserModel> getUserById(String id);

  /// Получить всех пользователей с сервера
  Future<List<UserModel>> getAllUsers();

  /// Создать пользователя на сервере
  Future<UserModel> createUser(UserModel user);

  /// Получить список компаний пользователя
  Future<List<BusinessModel>> getUserBusinesses();

  /// Получить профиль пользователя в контексте компании
  Future<UserProfileModel> getUserProfile({String? businessId});
}

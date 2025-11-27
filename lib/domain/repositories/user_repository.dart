import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../entities/business.dart';
import '../entities/user_profile.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с пользователями
/// Реализация находится в data слое
abstract class UserRepository extends Repository {
  /// Получить пользователя по ID
  Future<Either<Failure, User>> getUserById(String id);

  /// Получить всех пользователей
  Future<Either<Failure, List<User>>> getAllUsers();

  /// Создать нового пользователя
  Future<Either<Failure, User>> createUser(User user);

  /// Получить список компаний пользователя
  Future<Either<Failure, List<Business>>> getUserBusinesses();

  /// Получить профиль пользователя в контексте компании
  Future<Either<Failure, UserProfile>> getUserProfile({String? businessId});
}

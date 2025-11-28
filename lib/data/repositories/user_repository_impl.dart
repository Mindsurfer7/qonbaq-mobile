import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../models/user_model.dart';
import '../models/employee_model.dart';
import '../datasources/user_remote_datasource.dart';
import '../datasources/user_local_datasource.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория пользователей
/// Использует Remote и Local DataSources
class UserRepositoryImpl extends RepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> getUserById(String id) async {
    try {
      // Сначала пробуем получить из локального хранилища
      final localUser = await localDataSource.getUserById(id);
      if (localUser != null) {
        return Right(localUser.toEntity());
      }

      // Если нет в локальном хранилище, получаем с сервера
      final remoteUser = await remoteDataSource.getUserById(id);

      // Кэшируем полученного пользователя
      await localDataSource.cacheUser(remoteUser);

      return Right(remoteUser.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении пользователя: $e'));
    }
  }

  @override
  Future<Either<Failure, List<User>>> getAllUsers() async {
    try {
      // Пробуем получить из локального хранилища
      final localUsers = await localDataSource.getAllUsers();
      if (localUsers.isNotEmpty) {
        return Right(localUsers.map((model) => model.toEntity()).toList());
      }

      // Если нет в локальном хранилище, получаем с сервера
      final remoteUsers = await remoteDataSource.getAllUsers();

      // Кэшируем полученных пользователей
      await localDataSource.cacheUsers(remoteUsers);

      return Right(remoteUsers.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении пользователей: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> createUser(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      final createdUser = await remoteDataSource.createUser(userModel);

      // Кэшируем созданного пользователя
      await localDataSource.cacheUser(createdUser);

      return Right(createdUser.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании пользователя: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Business>>> getUserBusinesses() async {
    try {
      final businesses = await remoteDataSource.getUserBusinesses();
      return Right(businesses.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении компаний: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> getUserProfile({
    String? businessId,
  }) async {
    try {
      final profile = await remoteDataSource.getUserProfile(
        businessId: businessId,
      );
      return Right(profile.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении профиля: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Employee>>> getBusinessEmployees(
    String businessId,
  ) async {
    try {
      final employees = await remoteDataSource.getBusinessEmployees(businessId);
      return Right(employees.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении сотрудников: $e'));
    }
  }
}

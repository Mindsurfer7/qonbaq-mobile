import 'package:dartz/dartz.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/error/failures.dart';
import '../../core/utils/token_storage.dart';
import '../models/register_request.dart';
import '../models/login_request.dart';
import '../datasources/auth_remote_datasource.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория аутентификации
class AuthRepositoryImpl extends RepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final request = RegisterRequest(
        email: email,
        username: username,
        password: password,
      );

      // Валидация
      final validationError = request.validate();
      if (validationError != null) {
        return Left(GeneralFailure(validationError));
      }

      final response = await remoteDataSource.register(request);
      // Сохраняем токен
      TokenStorage.instance.setAccessToken(response.accessToken);
      return Right(response.toUserEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(email: email, password: password);

      // Валидация
      final validationError = request.validate();
      if (validationError != null) {
        return Left(GeneralFailure(validationError));
      }

      final response = await remoteDataSource.login(request);
      // Сохраняем токен
      TokenStorage.instance.setAccessToken(response.accessToken);
      return Right(response.toUserEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

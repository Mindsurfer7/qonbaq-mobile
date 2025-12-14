import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для аутентификации
abstract class AuthRepository extends Repository {
  /// Регистрация пользователя
  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String username,
    required String password,
    String? inviteCode,
  });

  /// Вход пользователя
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  });

  /// Обновление токена через refresh token
  Future<Either<Failure, AuthUser>> refreshToken(String refreshToken);
}

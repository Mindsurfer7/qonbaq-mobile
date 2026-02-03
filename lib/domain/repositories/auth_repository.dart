import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../entities/business.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для аутентификации
abstract class AuthRepository extends Repository {
  /// Регистрация пользователя
  Future<Either<Failure, AuthUser>> register({
    required String email,
    String? username, // Никнейм опциональный
    required String password,
    String? inviteCode,
    String? firstName,
    String? lastName,
  });

  /// Вход пользователя
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  });

  /// Обновление токена через refresh token
  Future<Either<Failure, AuthUser>> refreshToken(String refreshToken);

  /// Гостевой вход
  Future<Either<Failure, AuthUser>> guestLogin({required String guestUuid});

  /// Получить демо-бизнес для гостя (доступен после успешного гостевого логина)
  Business? getGuestBusiness();
}

import 'package:dartz/dartz.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/business.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/error/failures.dart';
import '../../core/utils/token_storage.dart';
import '../models/register_request.dart';
import '../models/login_request.dart';
import '../models/guest_login_request.dart';
import '../datasources/auth_remote_datasource.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория аутентификации
class AuthRepositoryImpl extends RepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  Business? _guestBusiness; // Сохраняем демо-бизнес для гостей

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuthUser>> register({
    required String email,
    String? username, // Никнейм опциональный
    required String password,
    String? inviteCode,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final request = RegisterRequest(
        email: email,
        username: username,
        password: password,
        inviteCode: inviteCode,
        firstName: firstName,
        lastName: lastName,
      );

      // Валидация
      final validationError = request.validate();
      if (validationError != null) {
        return Left(GeneralFailure(validationError));
      }

      final response = await remoteDataSource.register(request);
      // Сохраняем оба токена
      await TokenStorage.instance.setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
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
      // Сохраняем оба токена
      await TokenStorage.instance.setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      return Right(response.toUserEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> refreshToken(String refreshToken) async {
    try {
      final response = await remoteDataSource.refreshToken(refreshToken);
      // Сохраняем обновленные токены
      await TokenStorage.instance.setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      return Right(response.toUserEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> guestLogin({required String guestUuid}) async {
    try {
      final request = GuestLoginRequest(guestUuid: guestUuid);

      // Валидация
      final validationError = request.validate();
      if (validationError != null) {
        return Left(GeneralFailure(validationError));
      }

      final response = await remoteDataSource.guestLogin(request);
      // Сохраняем оба токена
      await TokenStorage.instance.setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      
      // Сохраняем демо-бизнес из ответа
      if (response.business != null) {
        _guestBusiness = response.business!.toBusinessEntity();
      }
      
      return Right(response.toUserEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Получить демо-бизнес для гостя
  Business? getGuestBusiness() {
    return _guestBusiness;
  }
}

import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Параметры для регистрации
class RegisterParams {
  final String email;
  final String username;
  final String password;
  final String? inviteCode;
  final String? firstName;
  final String? lastName;

  RegisterParams({
    required this.email,
    required this.username,
    required this.password,
    this.inviteCode,
    this.firstName,
    this.lastName,
  });
}

/// Use Case для регистрации пользователя
class RegisterUser implements UseCase<AuthUser, RegisterParams> {
  final AuthRepository repository;

  RegisterUser(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(RegisterParams params) async {
    return await repository.register(
      email: params.email,
      username: params.username,
      password: params.password,
      inviteCode: params.inviteCode,
      firstName: params.firstName,
      lastName: params.lastName,
    );
  }
}

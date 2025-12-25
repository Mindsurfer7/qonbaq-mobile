import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Use Case для обновления токена через refresh token
class RefreshToken implements UseCase<AuthUser, String> {
  final AuthRepository repository;

  RefreshToken(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(String refreshToken) async {
    return await repository.refreshToken(refreshToken);
  }
}





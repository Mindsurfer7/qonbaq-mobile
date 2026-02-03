import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Параметры для гостевого входа
class GuestLoginParams {
  final String guestUuid;

  GuestLoginParams({required this.guestUuid});
}

/// Use Case для гостевого входа
class GuestLoginUser implements UseCase<AuthUser, GuestLoginParams> {
  final AuthRepository repository;

  GuestLoginUser(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(GuestLoginParams params) async {
    return await repository.guestLogin(guestUuid: params.guestUuid);
  }
}

import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/user_profile.dart';
import '../repositories/user_repository.dart';

/// Параметры для получения профиля
class GetUserProfileParams {
  final String? businessId;

  GetUserProfileParams({this.businessId});
}

/// Use Case для получения профиля пользователя
class GetUserProfile implements UseCase<UserProfile, GetUserProfileParams> {
  final UserRepository repository;

  GetUserProfile(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(GetUserProfileParams params) async {
    return await repository.getUserProfile(businessId: params.businessId);
  }
}



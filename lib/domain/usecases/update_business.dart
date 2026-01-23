import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/business.dart';
import '../repositories/user_repository.dart';

/// Параметры для обновления бизнеса
class UpdateBusinessParams {
  final String id;
  final Business business;

  UpdateBusinessParams({
    required this.id,
    required this.business,
  });
}

/// Use Case для обновления бизнеса
class UpdateBusiness implements UseCase<Business, UpdateBusinessParams> {
  final UserRepository repository;

  UpdateBusiness(this.repository);

  @override
  Future<Either<Failure, Business>> call(UpdateBusinessParams params) async {
    return await repository.updateBusiness(params.id, params.business);
  }
}

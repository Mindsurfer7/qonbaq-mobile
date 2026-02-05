import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/business.dart';
import '../repositories/user_repository.dart';

/// Параметры для частичного обновления бизнеса
class UpdateBusinessPartialParams {
  final String id;
  final Map<String, dynamic> updates;

  UpdateBusinessPartialParams({
    required this.id,
    required this.updates,
  });
}

/// Use Case для частичного обновления бизнеса
class UpdateBusinessPartial implements UseCase<Business, UpdateBusinessPartialParams> {
  final UserRepository repository;

  UpdateBusinessPartial(this.repository);

  @override
  Future<Either<Failure, Business>> call(UpdateBusinessPartialParams params) async {
    return await repository.updateBusinessPartial(params.id, params.updates);
  }
}

import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/business.dart';
import '../repositories/user_repository.dart';

/// Параметры для создания бизнеса
class CreateBusinessParams {
  final Business business;

  CreateBusinessParams({required this.business});
}

/// Use Case для создания бизнеса
class CreateBusiness implements UseCase<Business, CreateBusinessParams> {
  final UserRepository repository;

  CreateBusiness(this.repository);

  @override
  Future<Either<Failure, Business>> call(CreateBusinessParams params) async {
    return await repository.createBusiness(params.business);
  }
}




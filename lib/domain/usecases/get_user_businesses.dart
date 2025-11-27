import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/business.dart';
import '../repositories/user_repository.dart';

/// Use Case для получения списка компаний пользователя
class GetUserBusinesses implements UseCaseNoParams<List<Business>> {
  final UserRepository repository;

  GetUserBusinesses(this.repository);

  @override
  Future<Either<Failure, List<Business>>> call() async {
    return await repository.getUserBusinesses();
  }
}



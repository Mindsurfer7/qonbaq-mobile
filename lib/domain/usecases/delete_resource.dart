import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/resource_repository.dart';

/// Use Case для удаления ресурса
class DeleteResource implements UseCase<void, String> {
  final ResourceRepository repository;

  DeleteResource(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteResource(id);
  }
}




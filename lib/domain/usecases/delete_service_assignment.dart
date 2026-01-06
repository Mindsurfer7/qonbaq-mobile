import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/service_repository.dart';

/// Use Case для удаления назначения на услугу
class DeleteServiceAssignment implements UseCase<void, String> {
  final ServiceRepository repository;

  DeleteServiceAssignment(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteAssignment(id);
  }
}


import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/department.dart';
import '../repositories/department_repository.dart';

/// Параметры для удаления менеджера подразделения
class RemoveDepartmentManagerParams {
  final String departmentId;
  final bool isGeneralDirector;

  RemoveDepartmentManagerParams({
    required this.departmentId,
    required this.isGeneralDirector,
  });
}

/// Use Case для удаления менеджера подразделения
class RemoveDepartmentManager
    implements UseCase<Department, RemoveDepartmentManagerParams> {
  final DepartmentRepository repository;

  RemoveDepartmentManager(this.repository);

  @override
  Future<Either<Failure, Department>> call(
    RemoveDepartmentManagerParams params,
  ) async {
    // Проверка прав: только генеральный директор может убирать менеджеров
    if (!params.isGeneralDirector) {
      return Left(GeneralFailure(
        'Только генеральный директор может убирать менеджеров подразделений',
      ));
    }

    return await repository.removeDepartmentManager(params.departmentId);
  }
}


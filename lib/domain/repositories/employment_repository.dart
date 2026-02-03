import '../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../entities/employment_with_role.dart';

/// Репозиторий для работы с трудоустройствами и ролями
abstract class EmploymentRepository {
  /// Получить список сотрудников бизнеса с их ролями
  Future<Either<Failure, List<EmploymentWithRole>>> getBusinessEmploymentsWithRoles(
    String businessId,
  );

  /// Обновить роль одного сотрудника
  Future<Either<Failure, EmploymentWithRole>> updateEmploymentRole(
    String employmentId,
    String? roleCode,
  );

  /// Назначить роли нескольким сотрудникам
  Future<Either<Failure, List<EmploymentWithRole>>> assignEmploymentsRoles(
    Map<String, String?> employmentsRoles,
  );

  /// Обновить роли нескольких сотрудников
  Future<Either<Failure, List<EmploymentWithRole>>> updateEmploymentsRoles(
    Map<String, String?> employmentsRoles,
  );

  /// Обновить employment
  /// Если employmentId == null, обновляется текущее employment через /me
  Future<Either<Failure, EmploymentWithRole>> updateEmployment({
    String? employmentId,
    String? position,
    String? positionType,
    String? orgPosition,
    String? workPhone,
    int? workExperience,
    String? accountability,
    String? personnelNumber,
    DateTime? hireDate,
    String? roleCode,
    String? businessId,
  });

  /// Назначить функциональные роли сотрудникам
  /// assignments: список назначений, где каждое содержит employmentId и список permissions
  Future<Either<Failure, void>> assignFunctionalRoles({
    required String businessId,
    required List<Map<String, dynamic>> assignments,
  });
}
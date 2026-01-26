import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/employment_with_role.dart';
import '../repositories/employment_repository.dart';

/// Параметры для обновления employment
class UpdateEmploymentParams {
  final String? employmentId; // Если null, обновляется текущее employment через /me
  final String? position;
  final String? positionType;
  final String? orgPosition;
  final String? workPhone;
  final int? workExperience;
  final String? accountability;
  final String? personnelNumber;
  final DateTime? hireDate;
  final String? roleCode;
  final String? businessId; // Опционально для /me endpoint

  UpdateEmploymentParams({
    this.employmentId,
    this.position,
    this.positionType,
    this.orgPosition,
    this.workPhone,
    this.workExperience,
    this.accountability,
    this.personnelNumber,
    this.hireDate,
    this.roleCode,
    this.businessId,
  });
}

/// Use Case для обновления employment
class UpdateEmployment implements UseCase<EmploymentWithRole, UpdateEmploymentParams> {
  final EmploymentRepository repository;

  UpdateEmployment(this.repository);

  @override
  Future<Either<Failure, EmploymentWithRole>> call(UpdateEmploymentParams params) async {
    return await repository.updateEmployment(
      employmentId: params.employmentId,
      position: params.position,
      positionType: params.positionType,
      orgPosition: params.orgPosition,
      workPhone: params.workPhone,
      workExperience: params.workExperience,
      accountability: params.accountability,
      personnelNumber: params.personnelNumber,
      hireDate: params.hireDate,
      roleCode: params.roleCode,
      businessId: params.businessId,
    );
  }
}

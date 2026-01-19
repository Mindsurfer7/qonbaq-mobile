import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval_template.dart';
import '../repositories/approval_repository.dart';

/// Параметры для получения шаблона по коду
class GetApprovalTemplateByCodeParams {
  final String code;
  final String? businessId;

  GetApprovalTemplateByCodeParams({
    required this.code,
    this.businessId,
  });
}

/// Use Case для получения шаблона согласования по коду
class GetApprovalTemplateByCode
    implements UseCase<ApprovalTemplate, GetApprovalTemplateByCodeParams> {
  final ApprovalRepository repository;

  GetApprovalTemplateByCode(this.repository);

  @override
  Future<Either<Failure, ApprovalTemplate>> call(
      GetApprovalTemplateByCodeParams params) async {
    return await repository.getTemplateByCode(
      params.code,
      businessId: params.businessId,
    );
  }
}


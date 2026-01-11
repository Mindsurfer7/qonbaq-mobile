import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/templates_result.dart';
import '../repositories/approval_repository.dart';

/// Параметры для получения списка шаблонов
class GetApprovalTemplatesParams {
  final String? businessId;

  GetApprovalTemplatesParams({this.businessId});
}

/// Use Case для получения списка шаблонов согласований с метаданными
class GetApprovalTemplates implements UseCase<TemplatesResult, GetApprovalTemplatesParams> {
  final ApprovalRepository repository;

  GetApprovalTemplates(this.repository);

  @override
  Future<Either<Failure, TemplatesResult>> call(GetApprovalTemplatesParams params) async {
    return await repository.getTemplates(businessId: params.businessId);
  }
}


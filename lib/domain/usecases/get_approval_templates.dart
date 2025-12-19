import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval_template.dart';
import '../repositories/approval_repository.dart';

/// Параметры для получения списка шаблонов
class GetApprovalTemplatesParams {
  final String? businessId;

  GetApprovalTemplatesParams({this.businessId});
}

/// Use Case для получения списка шаблонов согласований
class GetApprovalTemplates implements UseCase<List<ApprovalTemplate>, GetApprovalTemplatesParams> {
  final ApprovalRepository repository;

  GetApprovalTemplates(this.repository);

  @override
  Future<Either<Failure, List<ApprovalTemplate>>> call(GetApprovalTemplatesParams params) async {
    return await repository.getTemplates(businessId: params.businessId);
  }
}


import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval_template.dart';
import '../repositories/approval_repository.dart';

/// Use Case для получения шаблона согласования по коду
class GetApprovalTemplateByCode implements UseCase<ApprovalTemplate, String> {
  final ApprovalRepository repository;

  GetApprovalTemplateByCode(this.repository);

  @override
  Future<Either<Failure, ApprovalTemplate>> call(String code) async {
    return await repository.getTemplateByCode(code);
  }
}


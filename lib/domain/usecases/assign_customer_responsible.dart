import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

/// Параметры для назначения ответственного за клиента
class AssignCustomerResponsibleParams {
  final String customerId;
  final String businessId;
  final String responsibleId;

  AssignCustomerResponsibleParams({
    required this.customerId,
    required this.businessId,
    required this.responsibleId,
  });
}

/// Use Case для назначения ответственного за клиента
class AssignCustomerResponsible implements UseCase<Customer, AssignCustomerResponsibleParams> {
  final CustomerRepository repository;

  AssignCustomerResponsible(this.repository);

  @override
  Future<Either<Failure, Customer>> call(AssignCustomerResponsibleParams params) async {
    return await repository.assignResponsible(
      params.customerId,
      params.businessId,
      params.responsibleId,
    );
  }
}

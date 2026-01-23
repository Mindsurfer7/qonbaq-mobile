import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/customer_repository.dart';

/// Параметры для удаления контакта клиента
class DeleteCustomerContactParams {
  final String id;
  final String businessId;

  DeleteCustomerContactParams({
    required this.id,
    required this.businessId,
  });
}

/// Use Case для удаления контакта клиента
class DeleteCustomerContact implements UseCase<void, DeleteCustomerContactParams> {
  final CustomerRepository repository;

  DeleteCustomerContact(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCustomerContactParams params) async {
    return await repository.deleteContact(
      params.id,
      params.businessId,
    );
  }
}

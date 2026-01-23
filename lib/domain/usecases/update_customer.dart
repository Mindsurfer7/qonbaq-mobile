import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

/// Параметры для обновления клиента
class UpdateCustomerParams {
  final String id;
  final String businessId;
  final Customer customer;

  UpdateCustomerParams({
    required this.id,
    required this.businessId,
    required this.customer,
  });
}

/// Use Case для обновления клиента
class UpdateCustomer implements UseCase<Customer, UpdateCustomerParams> {
  final CustomerRepository repository;

  UpdateCustomer(this.repository);

  @override
  Future<Either<Failure, Customer>> call(UpdateCustomerParams params) async {
    return await repository.updateCustomer(
      params.id,
      params.businessId,
      params.customer,
    );
  }
}

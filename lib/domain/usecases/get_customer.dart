import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

/// Параметры для получения клиента по ID
class GetCustomerParams {
  final String id;
  final String businessId;

  GetCustomerParams({
    required this.id,
    required this.businessId,
  });
}

/// Use Case для получения клиента по ID
class GetCustomer implements UseCase<Customer, GetCustomerParams> {
  final CustomerRepository repository;

  GetCustomer(this.repository);

  @override
  Future<Either<Failure, Customer>> call(GetCustomerParams params) async {
    return await repository.getCustomerById(params.id, params.businessId);
  }
}

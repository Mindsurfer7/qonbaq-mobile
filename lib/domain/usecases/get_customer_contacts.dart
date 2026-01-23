import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/customer_contact.dart';
import '../repositories/customer_repository.dart';

/// Параметры для получения контактов клиента
class GetCustomerContactsParams {
  final String customerId;
  final String businessId;

  GetCustomerContactsParams({
    required this.customerId,
    required this.businessId,
  });
}

/// Use Case для получения контактов клиента
class GetCustomerContacts implements UseCase<List<CustomerContact>, GetCustomerContactsParams> {
  final CustomerRepository repository;

  GetCustomerContacts(this.repository);

  @override
  Future<Either<Failure, List<CustomerContact>>> call(GetCustomerContactsParams params) async {
    return await repository.getContacts(
      params.customerId,
      params.businessId,
    );
  }
}

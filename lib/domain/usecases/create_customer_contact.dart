import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/customer_contact.dart';
import '../repositories/customer_repository.dart';

/// Параметры для создания контакта клиента
class CreateCustomerContactParams {
  final CustomerContact contact;
  final String businessId;

  CreateCustomerContactParams({
    required this.contact,
    required this.businessId,
  });
}

/// Use Case для создания контакта клиента
class CreateCustomerContact implements UseCase<CustomerContact, CreateCustomerContactParams> {
  final CustomerRepository repository;

  CreateCustomerContact(this.repository);

  @override
  Future<Either<Failure, CustomerContact>> call(CreateCustomerContactParams params) async {
    return await repository.createContact(
      params.contact,
      params.businessId,
    );
  }
}

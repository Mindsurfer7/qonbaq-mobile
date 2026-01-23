import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/customer_contact.dart';
import '../repositories/customer_repository.dart';

/// Параметры для обновления контакта клиента
class UpdateCustomerContactParams {
  final String id;
  final String businessId;
  final CustomerContact contact;

  UpdateCustomerContactParams({
    required this.id,
    required this.businessId,
    required this.contact,
  });
}

/// Use Case для обновления контакта клиента
class UpdateCustomerContact implements UseCase<CustomerContact, UpdateCustomerContactParams> {
  final CustomerRepository repository;

  UpdateCustomerContact(this.repository);

  @override
  Future<Either<Failure, CustomerContact>> call(UpdateCustomerContactParams params) async {
    return await repository.updateContact(
      params.id,
      params.businessId,
      params.contact,
    );
  }
}

import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/customer_observer.dart';
import '../repositories/customer_repository.dart';

/// Параметры для добавления наблюдателя за клиентом
class AddCustomerObserverParams {
  final String customerId;
  final String userId;
  final String businessId;

  AddCustomerObserverParams({
    required this.customerId,
    required this.userId,
    required this.businessId,
  });
}

/// Use Case для добавления наблюдателя за клиентом
class AddCustomerObserver implements UseCase<CustomerObserver, AddCustomerObserverParams> {
  final CustomerRepository repository;

  AddCustomerObserver(this.repository);

  @override
  Future<Either<Failure, CustomerObserver>> call(AddCustomerObserverParams params) async {
    return await repository.addObserver(
      params.customerId,
      params.userId,
      params.businessId,
    );
  }
}

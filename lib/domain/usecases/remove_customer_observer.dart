import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/customer_repository.dart';

/// Параметры для удаления наблюдателя за клиентом
class RemoveCustomerObserverParams {
  final String customerId;
  final String userId;
  final String businessId;

  RemoveCustomerObserverParams({
    required this.customerId,
    required this.userId,
    required this.businessId,
  });
}

/// Use Case для удаления наблюдателя за клиентом
class RemoveCustomerObserver implements UseCase<void, RemoveCustomerObserverParams> {
  final CustomerRepository repository;

  RemoveCustomerObserver(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveCustomerObserverParams params) async {
    return await repository.removeObserver(
      params.customerId,
      params.userId,
      params.businessId,
    );
  }
}

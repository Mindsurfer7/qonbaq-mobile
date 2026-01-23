import 'package:dartz/dartz.dart';
import '../entities/customer.dart';
import '../entities/customer_contact.dart';
import '../entities/customer_observer.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с клиентами CRM
/// Реализация находится в data слое
abstract class CustomerRepository extends Repository {
  /// Создать клиента
  Future<Either<Failure, Customer>> createCustomer(
    Customer customer,
  );

  /// Получить список клиентов
  Future<Either<Failure, List<Customer>>> getCustomers({
    required String businessId,
    SalesFunnelStage? salesFunnelStage,
    String? responsibleId,
    String? search,
    bool? showAll,
    int? limit,
    int? offset,
  });

  /// Получить клиента по ID
  Future<Either<Failure, Customer>> getCustomerById(
    String id,
    String businessId,
  );

  /// Обновить клиента
  Future<Either<Failure, Customer>> updateCustomer(
    String id,
    String businessId,
    Customer customer,
  );

  /// Обновить стадию воронки продаж
  Future<Either<Failure, Customer>> updateFunnelStage(
    String id,
    String businessId,
    SalesFunnelStage salesFunnelStage,
    String? refusalReason,
  );

  /// Добавить наблюдателя за клиентом
  Future<Either<Failure, CustomerObserver>> addObserver(
    String customerId,
    String userId,
    String businessId,
  );

  /// Удалить наблюдателя за клиентом
  Future<Either<Failure, void>> removeObserver(
    String customerId,
    String userId,
    String businessId,
  );

  /// Создать контакт клиента
  Future<Either<Failure, CustomerContact>> createContact(
    CustomerContact contact,
    String businessId,
  );

  /// Обновить контакт клиента
  Future<Either<Failure, CustomerContact>> updateContact(
    String id,
    String businessId,
    CustomerContact contact,
  );

  /// Удалить контакт клиента
  Future<Either<Failure, void>> deleteContact(
    String id,
    String businessId,
  );

  /// Получить контакты клиента
  Future<Either<Failure, List<CustomerContact>>> getContacts(
    String customerId,
    String businessId,
  );

  /// Назначить ответственного за клиента
  Future<Either<Failure, Customer>> assignResponsible(
    String customerId,
    String businessId,
    String responsibleId,
  );
}

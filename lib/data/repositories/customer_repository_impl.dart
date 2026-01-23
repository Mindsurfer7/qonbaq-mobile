import 'package:dartz/dartz.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/entities/customer_observer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../core/error/failures.dart';
import '../models/customer_model.dart';
import '../models/customer_contact_model.dart';
import '../datasources/customer_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../datasources/customer_remote_datasource_impl.dart';

/// Реализация репозитория клиентов CRM
/// Использует Remote DataSource
class CustomerRepositoryImpl extends RepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, Customer>> createCustomer(Customer customer) async {
    try {
      final customerModel = CustomerModel.fromEntity(customer);
      final createdCustomer = await remoteDataSource.createCustomer(
        customerModel,
        customer.businessId,
      );
      return Right(createdCustomer.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании клиента: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> getCustomers({
    required String businessId,
    SalesFunnelStage? salesFunnelStage,
    String? responsibleId,
    String? search,
    bool? showAll,
    int? limit,
    int? offset,
  }) async {
    try {
      final customers = await remoteDataSource.getCustomers(
        businessId: businessId,
        salesFunnelStage: salesFunnelStage,
        responsibleId: responsibleId,
        search: search,
        showAll: showAll,
        limit: limit,
        offset: offset,
      );
      return Right(customers.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении клиентов: $e'));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerById(
    String id,
    String businessId,
  ) async {
    try {
      final customer = await remoteDataSource.getCustomerById(id, businessId);
      return Right(customer.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении клиента: $e'));
    }
  }

  @override
  Future<Either<Failure, Customer>> updateCustomer(
    String id,
    String businessId,
    Customer customer,
  ) async {
    try {
      final customerModel = CustomerModel.fromEntity(customer);
      final updatedCustomer = await remoteDataSource.updateCustomer(
        id,
        businessId,
        customerModel,
      );
      return Right(updatedCustomer.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении клиента: $e'));
    }
  }

  @override
  Future<Either<Failure, Customer>> updateFunnelStage(
    String id,
    String businessId,
    SalesFunnelStage salesFunnelStage,
    String? refusalReason,
  ) async {
    try {
      final customer = await remoteDataSource.updateFunnelStage(
        id,
        businessId,
        salesFunnelStage,
        refusalReason,
      );
      return Right(customer.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении стадии воронки: $e'));
    }
  }

  @override
  Future<Either<Failure, CustomerObserver>> addObserver(
    String customerId,
    String userId,
    String businessId,
  ) async {
    try {
      final observer = await remoteDataSource.addObserver(
        customerId,
        userId,
        businessId,
      );
      return Right(observer.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при добавлении наблюдателя: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeObserver(
    String customerId,
    String userId,
    String businessId,
  ) async {
    try {
      await remoteDataSource.removeObserver(customerId, userId, businessId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении наблюдателя: $e'));
    }
  }

  @override
  Future<Either<Failure, CustomerContact>> createContact(
    CustomerContact contact,
    String businessId,
  ) async {
    try {
      final contactModel = CustomerContactModel.fromEntity(contact);
      final createdContact = await remoteDataSource.createContact(
        contactModel,
        businessId,
      );
      return Right(createdContact.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании контакта: $e'));
    }
  }

  @override
  Future<Either<Failure, CustomerContact>> updateContact(
    String id,
    String businessId,
    CustomerContact contact,
  ) async {
    try {
      final contactModel = CustomerContactModel.fromEntity(contact);
      final updatedContact = await remoteDataSource.updateContact(
        id,
        businessId,
        contactModel,
      );
      return Right(updatedContact.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении контакта: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteContact(
    String id,
    String businessId,
  ) async {
    try {
      await remoteDataSource.deleteContact(id, businessId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении контакта: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CustomerContact>>> getContacts(
    String customerId,
    String businessId,
  ) async {
    try {
      final contacts = await remoteDataSource.getContacts(customerId, businessId);
      return Right(contacts.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении контактов: $e'));
    }
  }

  @override
  Future<Either<Failure, Customer>> assignResponsible(
    String customerId,
    String businessId,
    String responsibleId,
  ) async {
    try {
      final customer = await remoteDataSource.assignResponsible(
        customerId,
        businessId,
        responsibleId,
      );
      return Right(customer.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при назначении ответственного: $e'));
    }
  }
}

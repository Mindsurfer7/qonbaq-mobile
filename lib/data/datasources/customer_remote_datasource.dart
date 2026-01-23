import '../datasources/datasource.dart';
import '../../domain/entities/customer.dart';
import '../models/customer_model.dart';
import '../models/customer_contact_model.dart';
import '../models/customer_observer_model.dart';

/// Удаленный источник данных для клиентов CRM (API)
abstract class CustomerRemoteDataSource extends DataSource {
  /// Создать клиента
  Future<CustomerModel> createCustomer(
    CustomerModel customer,
    String businessId,
  );

  /// Получить список клиентов
  Future<List<CustomerModel>> getCustomers({
    required String businessId,
    SalesFunnelStage? salesFunnelStage,
    String? responsibleId,
    String? search,
    bool? showAll,
    int? limit,
    int? offset,
  });

  /// Получить клиента по ID
  Future<CustomerModel> getCustomerById(
    String id,
    String businessId,
  );

  /// Обновить клиента
  Future<CustomerModel> updateCustomer(
    String id,
    String businessId,
    CustomerModel customer,
  );

  /// Обновить стадию воронки продаж
  Future<CustomerModel> updateFunnelStage(
    String id,
    String businessId,
    SalesFunnelStage salesFunnelStage,
    String? refusalReason,
  );

  /// Добавить наблюдателя за клиентом
  Future<CustomerObserverModel> addObserver(
    String customerId,
    String userId,
    String businessId,
  );

  /// Удалить наблюдателя за клиентом
  Future<void> removeObserver(
    String customerId,
    String userId,
    String businessId,
  );

  /// Создать контакт клиента
  Future<CustomerContactModel> createContact(
    CustomerContactModel contact,
    String businessId,
  );

  /// Обновить контакт клиента
  Future<CustomerContactModel> updateContact(
    String id,
    String businessId,
    CustomerContactModel contact,
  );

  /// Удалить контакт клиента
  Future<void> deleteContact(
    String id,
    String businessId,
  );

  /// Получить контакты клиента
  Future<List<CustomerContactModel>> getContacts(
    String customerId,
    String businessId,
  );

  /// Назначить ответственного за клиента
  Future<CustomerModel> assignResponsible(
    String customerId,
    String businessId,
    String responsibleId,
  );
}

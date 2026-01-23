import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../../core/utils/error_handler.dart';
import '../../domain/entities/customer.dart';
import '../datasources/customer_remote_datasource.dart';
import '../models/customer_model.dart';
import '../models/customer_contact_model.dart';
import '../models/customer_observer_model.dart';
import '../models/api_response.dart';
import '../models/validation_error.dart';

/// Реализация удаленного источника данных для клиентов CRM
class CustomerRemoteDataSourceImpl extends CustomerRemoteDataSource {
  final ApiClient apiClient;

  CustomerRemoteDataSourceImpl({required this.apiClient});

  Map<String, String> _getAuthHeaders() {
    final token = TokenStorage.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Токен авторизации не найден');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static String _salesFunnelStageToString(SalesFunnelStage stage) {
    switch (stage) {
      case SalesFunnelStage.unprocessed:
        return 'UNPROCESSED';
      case SalesFunnelStage.inProgress:
        return 'IN_PROGRESS';
      case SalesFunnelStage.interested:
        return 'INTERESTED';
      case SalesFunnelStage.contractSigned:
        return 'CONTRACT_SIGNED';
      case SalesFunnelStage.salesByContract:
        return 'SALES_BY_CONTRACT';
      case SalesFunnelStage.refused:
        return 'REFUSED';
    }
  }

  @override
  Future<CustomerModel> createCustomer(
    CustomerModel customer,
    String businessId,
  ) async {
    try {
      final response = await apiClient.post(
        '/api/crm/customers?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: customer.toCreateJson(),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => CustomerModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<List<CustomerModel>> getCustomers({
    required String businessId,
    SalesFunnelStage? salesFunnelStage,
    String? responsibleId,
    String? search,
    bool? showAll,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'businessId': businessId,
      };
      if (salesFunnelStage != null) {
        queryParams['salesFunnelStage'] = _salesFunnelStageToString(salesFunnelStage);
      }
      if (responsibleId != null) {
        queryParams['responsibleId'] = responsibleId;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (showAll != null) {
        queryParams['showAll'] = showAll.toString();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      if (offset != null) {
        queryParams['offset'] = offset.toString();
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await apiClient.get(
        '/api/crm/customers?$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final customersList = data as List<dynamic>;
            return customersList
                .map((item) =>
                    CustomerModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<CustomerModel> getCustomerById(
    String id,
    String businessId,
  ) async {
    try {
      final response = await apiClient.get(
        '/api/crm/customers/$id?businessId=$businessId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => CustomerModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception('Клиент не найден');
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<CustomerModel> updateCustomer(
    String id,
    String businessId,
    CustomerModel customer,
  ) async {
    try {
      final response = await apiClient.put(
        '/api/crm/customers/$id?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: customer.toUpdateJson(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => CustomerModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception('Клиент не найден');
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<CustomerModel> updateFunnelStage(
    String id,
    String businessId,
    SalesFunnelStage salesFunnelStage,
    String? refusalReason,
  ) async {
    try {
      final body = <String, dynamic>{
        'salesFunnelStage': _salesFunnelStageToString(salesFunnelStage),
      };
      if (refusalReason != null && refusalReason.isNotEmpty) {
        body['refusalReason'] = refusalReason;
      }

      final response = await apiClient.patch(
        '/api/crm/customers/$id/funnel-stage?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => CustomerModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception('Клиент не найден');
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<CustomerObserverModel> addObserver(
    String customerId,
    String userId,
    String businessId,
  ) async {
    try {
      final response = await apiClient.post(
        '/api/crm/customers/observers?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: {
          'customerId': customerId,
          'userId': userId,
        },
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => CustomerObserverModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<void> removeObserver(
    String customerId,
    String userId,
    String businessId,
  ) async {
    try {
      final response = await apiClient.delete(
        '/api/crm/customers/observers?businessId=$businessId&customerId=$customerId&userId=$userId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<CustomerContactModel> createContact(
    CustomerContactModel contact,
    String businessId,
  ) async {
    try {
      final response = await apiClient.post(
        '/api/crm/customers/contacts?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: contact.toCreateJson(),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => CustomerContactModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<CustomerContactModel> updateContact(
    String id,
    String businessId,
    CustomerContactModel contact,
  ) async {
    try {
      final response = await apiClient.put(
        '/api/crm/customers/contacts/$id?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: contact.toUpdateJson(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => CustomerContactModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception('Контакт не найден');
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<void> deleteContact(
    String id,
    String businessId,
  ) async {
    try {
      final response = await apiClient.delete(
        '/api/crm/customers/contacts/$id?businessId=$businessId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception('Контакт не найден');
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<List<CustomerContactModel>> getContacts(
    String customerId,
    String businessId,
  ) async {
    try {
      final response = await apiClient.get(
        '/api/crm/customers/contacts?businessId=$businessId&customerId=$customerId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final contactsList = data as List<dynamic>;
            return contactsList
                .map((item) =>
                    CustomerContactModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<CustomerModel> assignResponsible(
    String customerId,
    String businessId,
    String responsibleId,
  ) async {
    try {
      final response = await apiClient.post(
        '/api/crm/customers/$customerId/assign-responsible?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: {'responsibleId': responsibleId},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => CustomerModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception('Клиент не найден');
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }
}

/// Исключение для ошибок валидации
class ValidationException implements Exception {
  final ValidationErrorResponse validationResponse;

  ValidationException(this.validationResponse);

  @override
  String toString() => validationResponse.message ?? validationResponse.error;
}

import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../../core/utils/error_handler.dart';
import '../../domain/entities/order.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order_model.dart';
import '../models/order_observer_model.dart';
import '../models/api_response.dart';
import '../models/validation_error.dart';

/// Реализация удаленного источника данных для заказов
class OrderRemoteDataSourceImpl extends OrderRemoteDataSource {
  final ApiClient apiClient;

  OrderRemoteDataSourceImpl({required this.apiClient});

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

  static String _orderFunnelStageToString(OrderFunnelStage stage) {
    switch (stage) {
      case OrderFunnelStage.orderAccepted:
        return 'ORDER_ACCEPTED';
      case OrderFunnelStage.orderStarted:
        return 'ORDER_STARTED';
      case OrderFunnelStage.orderInProgress:
        return 'ORDER_IN_PROGRESS';
      case OrderFunnelStage.orderReady:
        return 'ORDER_READY';
      case OrderFunnelStage.orderDelivered:
        return 'ORDER_DELIVERED';
      case OrderFunnelStage.orderReturned:
        return 'ORDER_RETURNED';
    }
  }

  @override
  Future<OrderModel> createOrder(OrderModel order, String businessId) async {
    try {
      final response = await apiClient.post(
        '/api/crm/orders?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: order.toCreateJson(),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => OrderModel.fromJson(data as Map<String, dynamic>),
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
  Future<List<OrderModel>> getOrders({
    required String businessId,
    String? customerId,
    OrderFunnelStage? stage,
    bool? isPaid,
    bool? isOverdue,
    String? search,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'businessId': businessId,
      };
      if (customerId != null) {
        queryParams['customerId'] = customerId;
      }
      if (stage != null) {
        queryParams['stage'] = _orderFunnelStageToString(stage);
      }
      if (isPaid != null) {
        queryParams['isPaid'] = isPaid.toString();
      }
      if (isOverdue != null) {
        queryParams['isOverdue'] = isOverdue.toString();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
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
        '/api/crm/orders?$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final ordersList = data as List<dynamic>;
            return ordersList
                .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
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
  Future<OrderModel> getOrderById(String id, String businessId) async {
    try {
      final response = await apiClient.get(
        '/api/crm/orders/$id?businessId=$businessId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => OrderModel.fromJson(data as Map<String, dynamic>),
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
        throw Exception('Заказ не найден');
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
  Future<OrderModel> updateOrder(String id, String businessId, OrderModel order) async {
    try {
      final response = await apiClient.put(
        '/api/crm/orders/$id?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: order.toUpdateJson(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => OrderModel.fromJson(data as Map<String, dynamic>),
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
        throw Exception('Заказ не найден');
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
  Future<OrderModel> moveOrderStage(
    String id,
    String businessId,
    OrderFunnelStage stage,
    String? returnReason,
  ) async {
    try {
      final body = <String, dynamic>{
        'stage': _orderFunnelStageToString(stage),
      };
      if (returnReason != null && returnReason.isNotEmpty) {
        body['returnReason'] = returnReason;
      }

      final response = await apiClient.patch(
        '/api/crm/orders/$id/stage?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => OrderModel.fromJson(data as Map<String, dynamic>),
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
        throw Exception('Заказ не найден');
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
  Future<OrderModel> updateOrderPayment(
    String id,
    String businessId,
    double paidAmount,
    DateTime? paymentDueDate,
  ) async {
    try {
      final body = <String, dynamic>{
        'paidAmount': paidAmount,
      };
      if (paymentDueDate != null) {
        body['paymentDueDate'] = paymentDueDate.toIso8601String();
      }

      final response = await apiClient.patch(
        '/api/crm/orders/$id/payment?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => OrderModel.fromJson(data as Map<String, dynamic>),
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
        throw Exception('Заказ не найден');
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
  Future<OrderObserverModel> addObserver(
    String orderId,
    String userId,
    String businessId,
  ) async {
    try {
      final response = await apiClient.post(
        '/api/crm/orders/observers?businessId=$businessId',
        headers: _getAuthHeaders(),
        body: {
          'orderId': orderId,
          'userId': userId,
        },
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => OrderObserverModel.fromJson(data as Map<String, dynamic>),
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
  Future<void> removeObserver(
    String orderId,
    String userId,
    String businessId,
  ) async {
    try {
      final response = await apiClient.delete(
        '/api/crm/orders/observers?businessId=$businessId&orderId=$orderId&userId=$userId',
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
}

/// Исключение для ошибок валидации
class ValidationException implements Exception {
  final ValidationErrorResponse validationResponse;

  ValidationException(this.validationResponse);

  @override
  String toString() => validationResponse.message ?? validationResponse.error;
}

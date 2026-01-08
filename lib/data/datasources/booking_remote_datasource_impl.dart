import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../../core/utils/error_handler.dart';
import '../../domain/entities/booking.dart';
import '../datasources/booking_remote_datasource.dart';
import '../models/booking_model.dart';
import '../models/api_response.dart';
import '../models/validation_error.dart';

/// Реализация удаленного источника данных для бронирований
class BookingRemoteDataSourceImpl extends BookingRemoteDataSource {
  final ApiClient apiClient;

  BookingRemoteDataSourceImpl({required this.apiClient});

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

  String _statusToString(BookingStatus? status) {
    if (status == null) return '';
    switch (status) {
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.completed:
        return 'COMPLETED';
    }
  }

  @override
  Future<List<BookingModel>> getBookings({
    String? timeSlotId,
    String? serviceId,
    String? businessId,
    BookingStatus? status,
    String? clientId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (timeSlotId != null) queryParams['timeSlotId'] = timeSlotId;
      if (serviceId != null) queryParams['serviceId'] = serviceId;
      if (businessId != null) queryParams['businessId'] = businessId;
      if (status != null) queryParams['status'] = _statusToString(status);
      if (clientId != null) queryParams['clientId'] = clientId;

      final queryString = queryParams.isEmpty
          ? ''
          : '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

      final response = await apiClient.get(
        '/api/bookings$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final bookingsList = data as List<dynamic>;
            return bookingsList
                .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else {
        throw Exception(ErrorHandler.getErrorMessage(response.statusCode, response.body));
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<BookingModel> getBookingById(String id) async {
    try {
      final response = await apiClient.get(
        '/api/bookings/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => BookingModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Бронирование не найдено');
      } else {
        throw Exception(ErrorHandler.getErrorMessage(response.statusCode, response.body));
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    try {
      final body = booking.toCreateJson();
      final response = await apiClient.post(
        '/api/bookings',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => BookingModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception(ErrorHandler.getErrorMessage(response.statusCode, response.body));
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
  Future<BookingModel> updateBookingStatus(String id, BookingStatus status) async {
    try {
      final body = {'status': _statusToString(status)};
      final response = await apiClient.patch(
        '/api/bookings/$id/status',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => BookingModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Бронирование не найдено');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception(ErrorHandler.getErrorMessage(response.statusCode, response.body));
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
  Future<void> deleteBooking(String id) async {
    try {
      final response = await apiClient.delete(
        '/api/bookings/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Бронирование не найдено');
      } else {
        throw Exception(ErrorHandler.getErrorMessage(response.statusCode, response.body));
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




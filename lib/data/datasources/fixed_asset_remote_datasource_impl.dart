import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../../domain/entities/fixed_asset.dart';
import '../datasources/fixed_asset_remote_datasource.dart';
import '../models/fixed_asset_model.dart';
import '../models/validation_error.dart';
import '../models/api_response.dart';

/// Реализация удаленного источника данных для основных средств
class FixedAssetRemoteDataSourceImpl extends FixedAssetRemoteDataSource {
  final ApiClient apiClient;

  FixedAssetRemoteDataSourceImpl({required this.apiClient});

  /// Парсит сообщение об ошибке из body ответа
  String _parseErrorMessage(String body, String defaultMessage) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['error'] as String? ?? defaultMessage;
    } catch (e) {
      return defaultMessage;
    }
  }

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

  static String _assetTypeToString(AssetType? type) {
    if (type == null) return '';
    switch (type) {
      case AssetType.equipment:
        return 'EQUIPMENT';
      case AssetType.furniture:
        return 'FURNITURE';
      case AssetType.officeTech:
        return 'OFFICE_TECH';
      case AssetType.other:
        return 'OTHER';
    }
  }

  static String _assetConditionToString(AssetCondition? condition) {
    if (condition == null) return '';
    switch (condition) {
      case AssetCondition.newUpTo3Months:
        return 'NEW_UP_TO_3_MONTHS';
      case AssetCondition.good:
        return 'GOOD';
      case AssetCondition.satisfactory:
        return 'SATISFACTORY';
      case AssetCondition.notWorking:
        return 'NOT_WORKING';
      case AssetCondition.writtenOff:
        return 'WRITTEN_OFF';
    }
  }

  @override
  Future<ApiResponse<List<FixedAssetModel>>> getFixedAssets({
    required String businessId,
    String? projectId,
    String? departmentId,
    String? currentOwnerId,
    AssetCondition? condition,
    AssetType? type,
    bool? includeArchived,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['businessId'] = businessId;
      if (projectId != null) queryParams['projectId'] = projectId;
      if (departmentId != null) queryParams['departmentId'] = departmentId;
      if (currentOwnerId != null) queryParams['currentOwnerId'] = currentOwnerId;
      if (condition != null) {
        queryParams['condition'] = _assetConditionToString(condition);
      }
      if (type != null) {
        queryParams['type'] = _assetTypeToString(type);
      }
      if (includeArchived != null) {
        queryParams['includeArchived'] = includeArchived.toString();
      }
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final queryString = queryParams.isEmpty
          ? ''
          : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await apiClient.get(
        '/api/fixed-assets$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final assetsList = data as List<dynamic>;
            return assetsList
                .map((item) =>
                    FixedAssetModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );
        return apiResponse;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка при получении списка активов: ${response.statusCode}',
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
  Future<FixedAssetModel> getFixedAssetById(String id) async {
    try {
      final response = await apiClient.get(
        '/api/fixed-assets/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => FixedAssetModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Актив не найден');
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка при получении актива: ${response.statusCode}',
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
  Future<FixedAssetModel> createFixedAsset(FixedAssetModel asset) async {
    try {
      final response = await apiClient.post(
        '/api/fixed-assets',
        headers: _getAuthHeaders(),
        body: asset.toCreateJson(),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => FixedAssetModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка при создании актива: ${response.statusCode}',
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
  Future<FixedAssetModel> updateFixedAsset(String id, FixedAssetModel asset) async {
    try {
      final response = await apiClient.patch(
        '/api/fixed-assets/$id',
        headers: _getAuthHeaders(),
        body: asset.toUpdateJson(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => FixedAssetModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Актив не найден');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка при обновлении актива: ${response.statusCode}',
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
  Future<void> transferFixedAsset(
    String id, {
    required String toUserId,
    DateTime? transferDate,
    String? reason,
    String? comment,
  }) async {
    try {
      final body = <String, dynamic>{
        'toUserId': toUserId,
      };
      if (transferDate != null) {
        body['transferDate'] = transferDate.toIso8601String();
      }
      if (reason != null) body['reason'] = reason;
      if (comment != null) body['comment'] = comment;

      final response = await apiClient.post(
        '/api/fixed-assets/$id/transfer',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Актив не найден');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка при передаче актива: ${response.statusCode}',
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
  Future<void> addRepair(
    String id, {
    required DateTime repairDate,
    required String repairType,
    required double cost,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{
        'repairDate': repairDate.toIso8601String(),
        'repairType': repairType,
        'cost': cost,
      };
      if (description != null) body['description'] = description;

      final response = await apiClient.post(
        '/api/fixed-assets/$id/repairs',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Актив не найден');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка при добавлении ремонта: ${response.statusCode}',
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
  Future<void> addInventory(
    String id, {
    required DateTime inventoryDate,
    String? status,
    String? comment,
  }) async {
    try {
      final body = <String, dynamic>{
        'inventoryDate': inventoryDate.toIso8601String(),
      };
      if (status != null) body['status'] = status;
      if (comment != null) body['comment'] = comment;

      final response = await apiClient.post(
        '/api/fixed-assets/$id/inventories',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Актив не найден');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка при добавлении инвентаризации: ${response.statusCode}',
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
  Future<void> addPhoto(
    String id, {
    required String fileUrl,
    String? fileName,
    String? fileType,
    bool? isInventoryPhoto,
    String? inventoryId,
  }) async {
    try {
      final body = <String, dynamic>{
        'fileUrl': fileUrl,
      };
      if (fileName != null) body['fileName'] = fileName;
      if (fileType != null) body['fileType'] = fileType;
      if (isInventoryPhoto != null) body['isInventoryPhoto'] = isInventoryPhoto;
      if (inventoryId != null) body['inventoryId'] = inventoryId;

      final response = await apiClient.post(
        '/api/fixed-assets/$id/photos',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Актив не найден');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка при добавлении фото: ${response.statusCode}',
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
  Future<void> writeOffFixedAsset(
    String id, {
    required DateTime writeOffDate,
    required String reason,
    double? writeOffAmount,
    String? documentUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        'writeOffDate': writeOffDate.toIso8601String(),
        'reason': reason,
      };
      if (writeOffAmount != null) body['writeOffAmount'] = writeOffAmount;
      if (documentUrl != null) body['documentUrl'] = documentUrl;

      final response = await apiClient.post(
        '/api/fixed-assets/$id/write-off',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Актив не найден');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка при списании актива: ${response.statusCode}',
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
  Future<void> archiveFixedAsset(String id) async {
    try {
      final response = await apiClient.delete(
        '/api/fixed-assets/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Актив не найден');
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка при архивации актива: ${response.statusCode}',
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

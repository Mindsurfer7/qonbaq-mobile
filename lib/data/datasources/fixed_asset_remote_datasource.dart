import '../datasources/datasource.dart';
import '../../domain/entities/fixed_asset.dart';
import '../models/fixed_asset_model.dart';

/// Удаленный источник данных для основных средств (API)
abstract class FixedAssetRemoteDataSource extends DataSource {
  /// Получить список активов
  Future<List<FixedAssetModel>> getFixedAssets({
    required String businessId,
    String? projectId,
    String? departmentId,
    String? currentOwnerId,
    AssetCondition? condition,
    AssetType? type,
    bool? includeArchived,
    int? page,
    int? limit,
  });

  /// Получить актив по ID
  Future<FixedAssetModel> getFixedAssetById(String id);

  /// Создать актив
  Future<FixedAssetModel> createFixedAsset(FixedAssetModel asset);

  /// Обновить актив
  Future<FixedAssetModel> updateFixedAsset(String id, FixedAssetModel asset);

  /// Передать актив (владелец)
  Future<void> transferFixedAsset(
    String id, {
    required String toUserId,
    DateTime? transferDate,
    String? reason,
    String? comment,
  });

  /// Добавить ремонт
  Future<void> addRepair(
    String id, {
    required DateTime repairDate,
    required String repairType,
    required double cost,
    String? description,
  });

  /// Добавить инвентаризацию
  Future<void> addInventory(
    String id, {
    required DateTime inventoryDate,
    String? status,
    String? comment,
  });

  /// Добавить фото
  Future<void> addPhoto(
    String id, {
    required String fileUrl,
    String? fileName,
    String? fileType,
    bool? isInventoryPhoto,
    String? inventoryId,
  });

  /// Списать актив
  Future<void> writeOffFixedAsset(
    String id, {
    required DateTime writeOffDate,
    required String reason,
    double? writeOffAmount,
    String? documentUrl,
  });

  /// Архивировать актив
  Future<void> archiveFixedAsset(String id);
}

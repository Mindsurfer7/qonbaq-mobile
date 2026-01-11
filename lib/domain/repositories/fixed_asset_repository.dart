import 'package:dartz/dartz.dart';
import '../entities/fixed_asset.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с основными средствами
/// Реализация находится в data слое
abstract class FixedAssetRepository extends Repository {
  /// Получить список активов
  Future<Either<Failure, List<FixedAsset>>> getFixedAssets({
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
  Future<Either<Failure, FixedAsset>> getFixedAssetById(String id);

  /// Создать актив
  Future<Either<Failure, FixedAsset>> createFixedAsset(FixedAsset asset);

  /// Обновить актив
  Future<Either<Failure, FixedAsset>> updateFixedAsset(String id, FixedAsset asset);

  /// Передать актив (владелец)
  Future<Either<Failure, void>> transferFixedAsset(
    String id, {
    required String toUserId,
    DateTime? transferDate,
    String? reason,
    String? comment,
  });

  /// Добавить ремонт
  Future<Either<Failure, void>> addRepair(
    String id, {
    required DateTime repairDate,
    required String repairType,
    required double cost,
    String? description,
  });

  /// Добавить инвентаризацию
  Future<Either<Failure, void>> addInventory(
    String id, {
    required DateTime inventoryDate,
    String? status,
    String? comment,
  });

  /// Добавить фото
  Future<Either<Failure, void>> addPhoto(
    String id, {
    required String fileUrl,
    String? fileName,
    String? fileType,
    bool? isInventoryPhoto,
    String? inventoryId,
  });

  /// Списать актив
  Future<Either<Failure, void>> writeOffFixedAsset(
    String id, {
    required DateTime writeOffDate,
    required String reason,
    double? writeOffAmount,
    String? documentUrl,
  });

  /// Архивировать актив
  Future<Either<Failure, void>> archiveFixedAsset(String id);
}

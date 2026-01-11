import 'package:dartz/dartz.dart';
import '../../domain/entities/fixed_asset.dart';
import '../../domain/repositories/fixed_asset_repository.dart';
import '../../core/error/failures.dart';
import '../models/fixed_asset_model.dart';
import '../datasources/fixed_asset_remote_datasource.dart';
import '../datasources/fixed_asset_remote_datasource_impl.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория основных средств
/// Использует Remote DataSource
class FixedAssetRepositoryImpl extends RepositoryImpl implements FixedAssetRepository {
  final FixedAssetRemoteDataSource remoteDataSource;

  FixedAssetRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
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
  }) async {
    try {
      final assets = await remoteDataSource.getFixedAssets(
        businessId: businessId,
        projectId: projectId,
        departmentId: departmentId,
        currentOwnerId: currentOwnerId,
        condition: condition,
        type: type,
        includeArchived: includeArchived,
        page: page,
        limit: limit,
      );
      return Right(assets.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении списка активов: $e'));
    }
  }

  @override
  Future<Either<Failure, FixedAsset>> getFixedAssetById(String id) async {
    try {
      final asset = await remoteDataSource.getFixedAssetById(id);
      return Right(asset.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении актива: $e'));
    }
  }

  @override
  Future<Either<Failure, FixedAsset>> createFixedAsset(FixedAsset asset) async {
    try {
      final assetModel = FixedAssetModel.fromEntity(asset);
      final createdAsset = await remoteDataSource.createFixedAsset(assetModel);
      return Right(createdAsset.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании актива: $e'));
    }
  }

  @override
  Future<Either<Failure, FixedAsset>> updateFixedAsset(String id, FixedAsset asset) async {
    try {
      final assetModel = FixedAssetModel.fromEntity(asset);
      final updatedAsset = await remoteDataSource.updateFixedAsset(id, assetModel);
      return Right(updatedAsset.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении актива: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> transferFixedAsset(
    String id, {
    required String toUserId,
    DateTime? transferDate,
    String? reason,
    String? comment,
  }) async {
    try {
      await remoteDataSource.transferFixedAsset(
        id,
        toUserId: toUserId,
        transferDate: transferDate,
        reason: reason,
        comment: comment,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при передаче актива: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addRepair(
    String id, {
    required DateTime repairDate,
    required String repairType,
    required double cost,
    String? description,
  }) async {
    try {
      await remoteDataSource.addRepair(
        id,
        repairDate: repairDate,
        repairType: repairType,
        cost: cost,
        description: description,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при добавлении ремонта: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addInventory(
    String id, {
    required DateTime inventoryDate,
    String? status,
    String? comment,
  }) async {
    try {
      await remoteDataSource.addInventory(
        id,
        inventoryDate: inventoryDate,
        status: status,
        comment: comment,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при добавлении инвентаризации: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addPhoto(
    String id, {
    required String fileUrl,
    String? fileName,
    String? fileType,
    bool? isInventoryPhoto,
    String? inventoryId,
  }) async {
    try {
      await remoteDataSource.addPhoto(
        id,
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
        isInventoryPhoto: isInventoryPhoto,
        inventoryId: inventoryId,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при добавлении фото: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> writeOffFixedAsset(
    String id, {
    required DateTime writeOffDate,
    required String reason,
    double? writeOffAmount,
    String? documentUrl,
  }) async {
    try {
      await remoteDataSource.writeOffFixedAsset(
        id,
        writeOffDate: writeOffDate,
        reason: reason,
        writeOffAmount: writeOffAmount,
        documentUrl: documentUrl,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при списании актива: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> archiveFixedAsset(String id) async {
    try {
      await remoteDataSource.archiveFixedAsset(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при архивации актива: $e'));
    }
  }
}

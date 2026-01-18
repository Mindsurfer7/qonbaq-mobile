import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/fixed_asset.dart';
import '../entities/paginated_result.dart';
import '../repositories/fixed_asset_repository.dart';

/// Параметры для получения списка основных средств
class GetFixedAssetsParams {
  final String businessId;
  final String? projectId;
  final String? departmentId;
  final String? currentOwnerId;
  final AssetCondition? condition;
  final AssetType? type;
  final bool? includeArchived;
  final int? page;
  final int? limit;

  GetFixedAssetsParams({
    required this.businessId,
    this.projectId,
    this.departmentId,
    this.currentOwnerId,
    this.condition,
    this.type,
    this.includeArchived,
    this.page,
    this.limit,
  });
}

/// Use Case для получения списка основных средств
class GetFixedAssets implements UseCase<PaginatedResult<FixedAsset>, GetFixedAssetsParams> {
  final FixedAssetRepository repository;

  GetFixedAssets(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<FixedAsset>>> call(GetFixedAssetsParams params) async {
    return await repository.getFixedAssets(
      businessId: params.businessId,
      projectId: params.projectId,
      departmentId: params.departmentId,
      currentOwnerId: params.currentOwnerId,
      condition: params.condition,
      type: params.type,
      includeArchived: params.includeArchived,
      page: params.page,
      limit: params.limit,
    );
  }
}

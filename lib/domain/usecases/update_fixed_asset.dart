import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/fixed_asset.dart';
import '../repositories/fixed_asset_repository.dart';

/// Параметры для обновления основного средства
class UpdateFixedAssetParams {
  final String id;
  final FixedAsset asset;

  UpdateFixedAssetParams({required this.id, required this.asset});
}

/// Use Case для обновления основного средства
class UpdateFixedAsset implements UseCase<FixedAsset, UpdateFixedAssetParams> {
  final FixedAssetRepository repository;

  UpdateFixedAsset(this.repository);

  @override
  Future<Either<Failure, FixedAsset>> call(UpdateFixedAssetParams params) async {
    return await repository.updateFixedAsset(params.id, params.asset);
  }
}

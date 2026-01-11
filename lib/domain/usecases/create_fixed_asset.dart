import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/fixed_asset.dart';
import '../repositories/fixed_asset_repository.dart';

/// Параметры для создания основного средства
class CreateFixedAssetParams {
  final FixedAsset asset;

  CreateFixedAssetParams({required this.asset});
}

/// Use Case для создания основного средства
class CreateFixedAsset implements UseCase<FixedAsset, CreateFixedAssetParams> {
  final FixedAssetRepository repository;

  CreateFixedAsset(this.repository);

  @override
  Future<Either<Failure, FixedAsset>> call(CreateFixedAssetParams params) async {
    return await repository.createFixedAsset(params.asset);
  }
}

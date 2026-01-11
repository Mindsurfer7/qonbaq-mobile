import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/fixed_asset.dart';
import '../repositories/fixed_asset_repository.dart';

/// Use Case для получения основного средства по ID
class GetFixedAssetById implements UseCase<FixedAsset, String> {
  final FixedAssetRepository repository;

  GetFixedAssetById(this.repository);

  @override
  Future<Either<Failure, FixedAsset>> call(String id) async {
    return await repository.getFixedAssetById(id);
  }
}

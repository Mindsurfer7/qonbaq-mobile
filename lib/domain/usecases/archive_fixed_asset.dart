import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/fixed_asset_repository.dart';

/// Use Case для архивации актива
class ArchiveFixedAsset implements UseCase<void, String> {
  final FixedAssetRepository repository;

  ArchiveFixedAsset(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.archiveFixedAsset(id);
  }
}

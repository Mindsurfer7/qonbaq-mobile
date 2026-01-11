import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/fixed_asset_repository.dart';

/// Параметры для передачи актива
class TransferFixedAssetParams {
  final String id;
  final String toUserId;
  final DateTime? transferDate;
  final String? reason;
  final String? comment;

  TransferFixedAssetParams({
    required this.id,
    required this.toUserId,
    this.transferDate,
    this.reason,
    this.comment,
  });
}

/// Use Case для передачи актива
class TransferFixedAsset implements UseCase<void, TransferFixedAssetParams> {
  final FixedAssetRepository repository;

  TransferFixedAsset(this.repository);

  @override
  Future<Either<Failure, void>> call(TransferFixedAssetParams params) async {
    return await repository.transferFixedAsset(
      params.id,
      toUserId: params.toUserId,
      transferDate: params.transferDate,
      reason: params.reason,
      comment: params.comment,
    );
  }
}

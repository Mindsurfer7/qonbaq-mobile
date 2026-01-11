import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/fixed_asset_repository.dart';

/// Параметры для списания актива
class WriteOffFixedAssetParams {
  final String id;
  final DateTime writeOffDate;
  final String reason;
  final double? writeOffAmount;
  final String? documentUrl;

  WriteOffFixedAssetParams({
    required this.id,
    required this.writeOffDate,
    required this.reason,
    this.writeOffAmount,
    this.documentUrl,
  });
}

/// Use Case для списания актива
class WriteOffFixedAsset implements UseCase<void, WriteOffFixedAssetParams> {
  final FixedAssetRepository repository;

  WriteOffFixedAsset(this.repository);

  @override
  Future<Either<Failure, void>> call(WriteOffFixedAssetParams params) async {
    return await repository.writeOffFixedAsset(
      params.id,
      writeOffDate: params.writeOffDate,
      reason: params.reason,
      writeOffAmount: params.writeOffAmount,
      documentUrl: params.documentUrl,
    );
  }
}

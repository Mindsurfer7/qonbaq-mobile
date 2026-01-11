import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/fixed_asset_repository.dart';

/// Параметры для добавления инвентаризации
class AddInventoryParams {
  final String id;
  final DateTime inventoryDate;
  final String? status;
  final String? comment;

  AddInventoryParams({
    required this.id,
    required this.inventoryDate,
    this.status,
    this.comment,
  });
}

/// Use Case для добавления инвентаризации
class AddInventory implements UseCase<void, AddInventoryParams> {
  final FixedAssetRepository repository;

  AddInventory(this.repository);

  @override
  Future<Either<Failure, void>> call(AddInventoryParams params) async {
    return await repository.addInventory(
      params.id,
      inventoryDate: params.inventoryDate,
      status: params.status,
      comment: params.comment,
    );
  }
}

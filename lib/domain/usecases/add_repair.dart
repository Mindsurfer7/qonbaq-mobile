import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/fixed_asset_repository.dart';

/// Параметры для добавления ремонта
class AddRepairParams {
  final String id;
  final DateTime repairDate;
  final String repairType;
  final double cost;
  final String? description;

  AddRepairParams({
    required this.id,
    required this.repairDate,
    required this.repairType,
    required this.cost,
    this.description,
  });
}

/// Use Case для добавления ремонта
class AddRepair implements UseCase<void, AddRepairParams> {
  final FixedAssetRepository repository;

  AddRepair(this.repository);

  @override
  Future<Either<Failure, void>> call(AddRepairParams params) async {
    return await repository.addRepair(
      params.id,
      repairDate: params.repairDate,
      repairType: params.repairType,
      cost: params.cost,
      description: params.description,
    );
  }
}

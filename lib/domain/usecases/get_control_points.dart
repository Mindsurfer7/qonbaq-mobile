import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/control_point.dart';
import '../entities/paginated_result.dart';
import '../repositories/control_point_repository.dart';

/// Параметры для получения точек контроля
class GetControlPointsParams {
  final String? businessId;
  final String? assignedTo;
  final bool? isActive;
  final int? page;
  final int? limit;
  final bool? showAll; // Показать все точки контроля бизнеса (для гендиректора)

  GetControlPointsParams({
    this.businessId,
    this.assignedTo,
    this.isActive,
    this.page,
    this.limit,
    this.showAll,
  });
}

/// Use Case для получения списка точек контроля
class GetControlPoints
    implements UseCase<PaginatedResult<ControlPoint>, GetControlPointsParams> {
  final ControlPointRepository repository;

  GetControlPoints(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<ControlPoint>>> call(
      GetControlPointsParams params) async {
    print('UseCase: Calling repository.getControlPoints with params:');
    print('  businessId: ${params.businessId}');
    print('  assignedTo: ${params.assignedTo}');
    print('  isActive: ${params.isActive}');
    print('  page: ${params.page}');
    print('  limit: ${params.limit}');
    print('  showAll: ${params.showAll}');
    
    final result = await repository.getControlPoints(
      businessId: params.businessId,
      assignedTo: params.assignedTo,
      isActive: params.isActive,
      page: params.page,
      limit: params.limit,
      showAll: params.showAll,
    );
    
    result.fold(
      (failure) {
        print('UseCase: Repository returned Left (failure): ${failure.message}');
      },
      (success) {
        print('UseCase: Repository returned Right (success): ${success.items.length} items');
      },
    );
    
    return result;
  }
}

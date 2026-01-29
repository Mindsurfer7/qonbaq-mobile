import 'package:dartz/dartz.dart' hide Task;
import '../../domain/entities/control_point.dart';
import '../../domain/repositories/control_point_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/control_point_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../../domain/entities/paginated_result.dart';

/// Реализация репозитория точек контроля
/// Использует Remote DataSource
class ControlPointRepositoryImpl extends RepositoryImpl
    implements ControlPointRepository {
  final ControlPointRemoteDataSource remoteDataSource;

  ControlPointRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, PaginatedResult<ControlPoint>>> getControlPoints({
    String? businessId,
    String? assignedTo,
    bool? isActive,
    int? page,
    int? limit,
    bool? showAll,
  }) async {
    try {
      print('Repository: Getting control points...');
      final apiResponse = await remoteDataSource.getControlPoints(
        businessId: businessId,
        assignedTo: assignedTo,
        isActive: isActive,
        page: page,
        limit: limit,
        showAll: showAll,
      );

      print('Repository: API response received, data count: ${apiResponse.data.length}');
      
      final items = <ControlPoint>[];
      for (var i = 0; i < apiResponse.data.length; i++) {
        try {
          print('Repository: Converting model $i to entity...');
          final entity = apiResponse.data[i].toEntity();
          items.add(entity);
          print('Repository: Model $i converted successfully');
        } catch (e, stackTrace) {
          print('Repository: ERROR converting model $i to entity: $e');
          print('Repository: Stack trace: $stackTrace');
          rethrow;
        }
      }

      print('Repository: Converted ${items.length} items to entities');

      // Преобразуем метаданные из ApiResponse в PaginationMeta
      PaginationMeta? meta;
      if (apiResponse.meta != null) {
        meta = PaginationMeta(
          total: apiResponse.meta!.total,
          page: apiResponse.meta!.page,
          limit: apiResponse.meta!.limit,
          totalPages: apiResponse.meta!.totalPages,
        );
        print('Repository: Meta created: total=${meta.total}, page=${meta.page}');
      }

      final result = PaginatedResult<ControlPoint>(
        items: items,
        meta: meta,
      );
      
      print('Repository: Returning Right with ${result.items.length} items');
      return Right(result);
    } catch (e, stackTrace) {
      // Извлекаем понятное сообщение об ошибке
      print('Repository: ERROR caught: $e');
      print('Repository: Stack trace: $stackTrace');
      String errorMessage;
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = 'Ошибка при получении точек контроля: $e';
      }
      print('Repository: Returning Left with error: $errorMessage');
      return Left(ServerFailure(errorMessage));
    }
  }

  @override
  Future<Either<Failure, ControlPoint>> getControlPointById(String id) async {
    try {
      final controlPoint = await remoteDataSource.getControlPointById(id);
      return Right(controlPoint.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении точки контроля: $e'));
    }
  }
}

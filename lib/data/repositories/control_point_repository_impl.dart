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
      final apiResponse = await remoteDataSource.getControlPoints(
        businessId: businessId,
        assignedTo: assignedTo,
        isActive: isActive,
        page: page,
        limit: limit,
        showAll: showAll,
      );

      final items =
          apiResponse.data.map((model) => model.toEntity()).toList();

      // Преобразуем метаданные из ApiResponse в PaginationMeta
      PaginationMeta? meta;
      if (apiResponse.meta != null) {
        meta = PaginationMeta(
          total: apiResponse.meta!.total,
          page: apiResponse.meta!.page,
          limit: apiResponse.meta!.limit,
          totalPages: apiResponse.meta!.totalPages,
        );
      }

      return Right(PaginatedResult<ControlPoint>(
        items: items,
        meta: meta,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении точек контроля: $e'));
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

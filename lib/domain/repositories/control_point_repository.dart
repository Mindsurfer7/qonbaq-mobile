import 'package:dartz/dartz.dart';
import '../entities/control_point.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';
import '../entities/paginated_result.dart';

/// Интерфейс репозитория для работы с точками контроля
/// Реализация находится в data слое
abstract class ControlPointRepository extends Repository {
  /// Получить список точек контроля с пагинацией
  Future<Either<Failure, PaginatedResult<ControlPoint>>> getControlPoints({
    String? businessId,
    String? assignedTo,
    bool? isActive,
    int? page,
    int? limit,
    bool? showAll,
  });

  /// Получить точку контроля по ID
  Future<Either<Failure, ControlPoint>> getControlPointById(String id);
}

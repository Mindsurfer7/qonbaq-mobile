import '../datasources/datasource.dart';
import '../../domain/entities/control_point.dart';
import '../models/control_point_model.dart';
import '../models/api_response.dart';

/// Удаленный источник данных для точек контроля (API)
abstract class ControlPointRemoteDataSource extends DataSource {
  /// Получить список точек контроля с метаданными пагинации
  Future<ApiResponse<List<ControlPointModel>>> getControlPoints({
    String? businessId,
    String? assignedTo,
    bool? isActive,
    int? page,
    int? limit,
    bool? showAll,
  });

  /// Получить точку контроля по ID
  Future<ControlPointModel> getControlPointById(String id);
}

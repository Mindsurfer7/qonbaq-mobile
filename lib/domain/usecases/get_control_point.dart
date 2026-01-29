import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/control_point.dart';
import '../repositories/control_point_repository.dart';

/// Use Case для получения точки контроля по ID
class GetControlPoint implements UseCase<ControlPoint, String> {
  final ControlPointRepository repository;

  GetControlPoint(this.repository);

  @override
  Future<Either<Failure, ControlPoint>> call(String id) async {
    return await repository.getControlPointById(id);
  }
}

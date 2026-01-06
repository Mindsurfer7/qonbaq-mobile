import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/time_slot.dart';
import '../repositories/time_slot_repository.dart';

/// Use Case для получения тайм-слотов по serviceId с группировкой по исполнителю
class GetTimeSlotsByService implements UseCase<List<TimeSlotGroup>, String> {
  final TimeSlotRepository repository;

  GetTimeSlotsByService(this.repository);

  @override
  Future<Either<Failure, List<TimeSlotGroup>>> call(String serviceId) async {
    return await repository.getTimeSlotsByService(serviceId);
  }
}


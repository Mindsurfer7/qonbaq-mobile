import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/time_slot.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с тайм-слотами
abstract class TimeSlotRepository extends Repository {
  /// Получить список тайм-слотов
  Future<Either<Failure, List<TimeSlot>>> getTimeSlots({
    String? employmentId,
    String? resourceId,
    String? serviceId,
    DateTime? date,
    DateTime? from,
    DateTime? to,
    TimeSlotStatus? status,
  });

  /// Получить тайм-слот по ID
  Future<Either<Failure, TimeSlot>> getTimeSlotById(String id);

  /// Создать тайм-слот
  Future<Either<Failure, TimeSlot>> createTimeSlot(TimeSlot timeSlot);

  /// Массовая генерация тайм-слотов
  Future<Either<Failure, List<TimeSlot>>> generateTimeSlots(Map<String, dynamic> params);

  /// Обновить тайм-слот
  Future<Either<Failure, TimeSlot>> updateTimeSlot(String id, TimeSlot timeSlot);

  /// Удалить тайм-слот
  Future<Either<Failure, void>> deleteTimeSlot(String id);
}


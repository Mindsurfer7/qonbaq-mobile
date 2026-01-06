import '../../domain/entities/time_slot.dart';
import '../models/time_slot_model.dart';

/// Интерфейс удаленного источника данных для тайм-слотов
abstract class TimeSlotRemoteDataSource {
  /// Получить список тайм-слотов
  Future<List<TimeSlotModel>> getTimeSlots({
    String? employmentId,
    String? resourceId,
    String? serviceId,
    DateTime? date,
    DateTime? from,
    DateTime? to,
    TimeSlotStatus? status,
  });

  /// Получить тайм-слоты по serviceId с группировкой по исполнителю
  Future<List<TimeSlotGroupModel>> getTimeSlotsByService(String serviceId);

  /// Получить тайм-слот по ID
  Future<TimeSlotModel> getTimeSlotById(String id);

  /// Создать тайм-слот
  Future<TimeSlotModel> createTimeSlot(TimeSlotModel timeSlot);

  /// Массовая генерация тайм-слотов
  Future<List<TimeSlotModel>> generateTimeSlots(Map<String, dynamic> params);

  /// Обновить тайм-слот
  Future<TimeSlotModel> updateTimeSlot(String id, TimeSlotModel timeSlot);

  /// Удалить тайм-слот
  Future<void> deleteTimeSlot(String id);
}


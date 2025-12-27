import '../datasources/datasource.dart';
import '../models/workday_model.dart';

/// Удаленный источник данных для рабочего дня (API)
abstract class WorkDayRemoteDataSource extends DataSource {
  /// Начать рабочий день
  Future<WorkDayModel> startWorkDay(String businessId);

  /// Завершить рабочий день
  Future<WorkDayModel> endWorkDay(String businessId);

  /// Отметить отсутствие
  Future<WorkDayModel> markAbsent(String businessId, String reason);

  /// Получить статус рабочего дня на сегодня
  Future<WorkDayModel?> getTodayStatus(String businessId);

  /// Получить статистику за месяц
  Future<WorkDayStatisticsModel> getStatistics(String businessId, String month);
}






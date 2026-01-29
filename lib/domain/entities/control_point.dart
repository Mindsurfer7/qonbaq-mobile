import '../entities/entity.dart';
import 'business.dart';
import 'user_profile.dart';
import 'task.dart';

/// Метрика точки контроля
class ControlPointMetric {
  final String id;
  final String controlPointId;
  final String name;
  final double targetValue;
  final MeasurementUnit unit;
  final String? customUnit; // Кастомная единица, если unit = CUSTOM
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ControlPointMetric({
    required this.id,
    required this.controlPointId,
    required this.name,
    required this.targetValue,
    required this.unit,
    this.customUnit,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Доменная сущность точки контроля
class ControlPoint extends Entity {
  final String id;
  final String businessId;
  final String title;
  final String? description;
  final String assignedTo; // ID исполнителя
  final String? assignedBy; // ID поручителя
  final String createdBy; // ID создателя шаблона
  final bool isActive;
  final RecurrenceFrequency frequency;
  final int interval;
  final String? timeOfDay; // Время создания задачи в формате "HH:MM"
  final List<int>? daysOfWeek; // JSON массив дней недели для WEEKLY (0-6, где 0=воскресенье)
  final int? dayOfMonth; // Число месяца для MONTHLY
  final DateTime startDate;
  final DateTime? endDate; // null = бесконечно
  final bool isImportant;
  final bool dontForget;
  final int? deadlineOffset; // Смещение дедлайна в часах
  final List<String> observerIds; // Массив ID наблюдателей
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deactivatedAt;

  // Связи
  final List<ControlPointMetric>? metrics;
  final Business? business;
  final ProfileUser? assignee;
  final ProfileUser? assigner;
  final ProfileUser? creator;

  const ControlPoint({
    required this.id,
    required this.businessId,
    required this.title,
    this.description,
    required this.assignedTo,
    this.assignedBy,
    required this.createdBy,
    required this.isActive,
    required this.frequency,
    this.interval = 1,
    this.timeOfDay,
    this.daysOfWeek,
    this.dayOfMonth,
    required this.startDate,
    this.endDate,
    this.isImportant = false,
    this.dontForget = false,
    this.deadlineOffset,
    this.observerIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deactivatedAt,
    this.metrics,
    this.business,
    this.assignee,
    this.assigner,
    this.creator,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ControlPoint &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ControlPoint(id: $id, title: $title)';
}

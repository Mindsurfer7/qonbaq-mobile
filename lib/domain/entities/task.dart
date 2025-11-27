import '../entities/entity.dart';

/// Статус задачи
enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

/// Приоритет задачи
enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

/// Частота повторения
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

/// Параметры рекуррентности задачи
class TaskRecurrence {
  final RecurrenceFrequency frequency;
  final int interval;
  final DateTime? endDate;
  final List<int>? daysOfWeek; // 0-6, где 0 = воскресенье
  final int? dayOfMonth;

  const TaskRecurrence({
    required this.frequency,
    this.interval = 1,
    this.endDate,
    this.daysOfWeek,
    this.dayOfMonth,
  });
}

/// Вложение задачи
class TaskAttachment {
  final String id;
  final String url;
  final String? fileName;
  final String? fileType;
  final int? fileSize;

  const TaskAttachment({
    required this.id,
    required this.url,
    this.fileName,
    this.fileType,
    this.fileSize,
  });
}

/// Индикатор для точки контроля
class TaskIndicator {
  final String id;
  final String name;
  final String? description;
  final String? value;

  const TaskIndicator({
    required this.id,
    required this.name,
    this.description,
    this.value,
  });
}

/// Доменная сущность задачи
class Task extends Entity {
  final String id;
  final String businessId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority? priority;
  final String? assignedTo; // ID исполнителя
  final String? assignedBy; // ID поручителя
  final DateTime? assignmentDate;
  final DateTime? deadline;
  final bool isImportant;
  final bool isRecurring;
  final bool hasControlPoint;
  final String? voiceNoteUrl;
  final String? resultText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? observerIds; // ID наблюдателей
  final List<TaskAttachment>? attachments;
  final List<TaskIndicator>? indicators;
  final TaskRecurrence? recurrence;

  const Task({
    required this.id,
    required this.businessId,
    required this.title,
    this.description,
    this.status = TaskStatus.pending,
    this.priority,
    this.assignedTo,
    this.assignedBy,
    this.assignmentDate,
    this.deadline,
    this.isImportant = false,
    this.isRecurring = false,
    this.hasControlPoint = false,
    this.voiceNoteUrl,
    this.resultText,
    required this.createdAt,
    required this.updatedAt,
    this.observerIds,
    this.attachments,
    this.indicators,
    this.recurrence,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Task(id: $id, title: $title)';
}


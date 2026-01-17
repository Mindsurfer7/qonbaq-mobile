import '../entities/entity.dart';
import 'business.dart';
import 'user_profile.dart';
import 'task_comment.dart';
import 'approval.dart';

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
  final String id;
  final String taskId;
  final RecurrenceFrequency frequency;
  final int interval;
  final DateTime? endDate;
  final List<int>? daysOfWeek; // 0-6, где 0 = воскресенье
  final int? dayOfMonth;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskRecurrence({
    required this.id,
    required this.taskId,
    required this.frequency,
    this.interval = 1,
    this.endDate,
    this.daysOfWeek,
    this.dayOfMonth,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Вложение задачи
class TaskAttachment {
  final String id;
  final String taskId;
  final String fileUrl;
  final String? fileName;
  final String? fileType;
  final bool isResult;
  final DateTime createdAt;

  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.fileUrl,
    this.fileName,
    this.fileType,
    this.isResult = false,
    required this.createdAt,
  });
}

/// Индикатор для точки контроля
class TaskIndicator {
  final String id;
  final String taskId;
  final String name;
  final double? targetValue;
  final double? actualValue;
  final String? unit;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskIndicator({
    required this.id,
    required this.taskId,
    required this.name,
    this.targetValue,
    this.actualValue,
    this.unit,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Наблюдатель задачи
class TaskObserver {
  final String id;
  final DateTime createdAt;
  final ProfileUser user;

  const TaskObserver({
    required this.id,
    required this.createdAt,
    required this.user,
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
  final bool dontForget;
  final String? voiceNoteUrl;
  final String? resultText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? observerIds; // ID наблюдателей (для списка задач)
  final List<TaskAttachment>? attachments;
  final List<TaskIndicator>? indicators;
  final TaskRecurrence? recurrence;
  final String? approvalId; // ID согласования (если задача создана для исполнения согласования)
  
  // Детальные данные (для детальной страницы)
  final Business? business;
  final ProfileUser? assignee;
  final ProfileUser? assigner;
  final List<TaskObserver>? observers;
  final List<TaskComment>? comments;
  final Approval? approval; // Связанное согласование

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
    this.dontForget = false,
    this.voiceNoteUrl,
    this.resultText,
    required this.createdAt,
    required this.updatedAt,
    this.observerIds,
    this.attachments,
    this.indicators,
    this.recurrence,
    this.approvalId,
    this.business,
    this.assignee,
    this.assigner,
    this.observers,
    this.comments,
    this.approval,
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


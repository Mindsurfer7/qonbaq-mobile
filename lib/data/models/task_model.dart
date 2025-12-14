import '../../domain/entities/task.dart';
import '../models/model.dart';

/// Модель задачи
class TaskModel extends Task implements Model {
  const TaskModel({
    required super.id,
    required super.businessId,
    required super.title,
    super.description,
    super.status,
    super.priority,
    super.assignedTo,
    super.assignedBy,
    super.assignmentDate,
    super.deadline,
    super.isImportant,
    super.isRecurring,
    super.hasControlPoint,
    super.voiceNoteUrl,
    super.resultText,
    required super.createdAt,
    required super.updatedAt,
    super.observerIds,
    super.attachments,
    super.indicators,
    super.recurrence,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String?),
      priority: _parsePriority(json['priority'] as String?),
      assignedTo: json['assignedTo'] as String?,
      assignedBy: json['assignedBy'] as String?,
      assignmentDate: json['assignmentDate'] != null
          ? DateTime.parse(json['assignmentDate'] as String)
          : null,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      isImportant: json['isImportant'] as bool? ?? false,
      isRecurring: json['isRecurring'] as bool? ?? false,
      hasControlPoint: json['hasControlPoint'] as bool? ?? false,
      voiceNoteUrl: json['voiceNoteUrl'] as String?,
      resultText: json['resultText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      observerIds: json['observers'] != null
          ? (json['observers'] as List<dynamic>)
              .map((obs) => (obs['user']?['id'] ?? obs['userId']) as String)
              .toList()
          : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List<dynamic>)
              .map((att) => TaskAttachment(
                    id: att['id'] as String,
                    url: att['url'] as String,
                    fileName: att['fileName'] as String?,
                    fileType: att['fileType'] as String?,
                    fileSize: att['fileSize'] as int?,
                  ))
              .toList()
          : null,
      indicators: json['indicators'] != null
          ? (json['indicators'] as List<dynamic>)
              .map((ind) => TaskIndicator(
                    id: ind['id'] as String,
                    name: ind['name'] as String,
                    description: ind['description'] as String?,
                    value: ind['value'] as String?,
                  ))
              .toList()
          : null,
      recurrence: json['recurrence'] != null
          ? TaskRecurrence(
              frequency: _parseRecurrenceFrequency(
                  json['recurrence']['frequency'] as String),
              interval: json['recurrence']['interval'] as int? ?? 1,
              endDate: json['recurrence']['endDate'] != null
                  ? DateTime.parse(json['recurrence']['endDate'] as String)
                  : null,
              daysOfWeek: json['recurrence']['daysOfWeek'] != null
                  ? (json['recurrence']['daysOfWeek'] as List<dynamic>)
                      .map((d) => d as int)
                      .toList()
                  : null,
              dayOfMonth: json['recurrence']['dayOfMonth'] as int?,
            )
          : null,
    );
  }

  static TaskStatus _parseStatus(String? status) {
    if (status == null) return TaskStatus.pending;
    switch (status.toUpperCase()) {
      case 'PENDING':
        return TaskStatus.pending;
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'COMPLETED':
        return TaskStatus.completed;
      case 'CANCELLED':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }

  static TaskPriority? _parsePriority(String? priority) {
    if (priority == null) return null;
    switch (priority.toUpperCase()) {
      case 'LOW':
        return TaskPriority.low;
      case 'MEDIUM':
        return TaskPriority.medium;
      case 'HIGH':
        return TaskPriority.high;
      case 'URGENT':
        return TaskPriority.urgent;
      default:
        return null;
    }
  }

  static RecurrenceFrequency _parseRecurrenceFrequency(String frequency) {
    switch (frequency.toUpperCase()) {
      case 'DAILY':
        return RecurrenceFrequency.daily;
      case 'WEEKLY':
        return RecurrenceFrequency.weekly;
      case 'MONTHLY':
        return RecurrenceFrequency.monthly;
      case 'YEARLY':
        return RecurrenceFrequency.yearly;
      default:
        return RecurrenceFrequency.daily;
    }
  }

  static String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'PENDING';
      case TaskStatus.inProgress:
        return 'IN_PROGRESS';
      case TaskStatus.completed:
        return 'COMPLETED';
      case TaskStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static String? _priorityToString(TaskPriority? priority) {
    if (priority == null) return null;
    switch (priority) {
      case TaskPriority.low:
        return 'LOW';
      case TaskPriority.medium:
        return 'MEDIUM';
      case TaskPriority.high:
        return 'HIGH';
      case TaskPriority.urgent:
        return 'URGENT';
    }
  }

  static String _recurrenceFrequencyToString(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'DAILY';
      case RecurrenceFrequency.weekly:
        return 'WEEKLY';
      case RecurrenceFrequency.monthly:
        return 'MONTHLY';
      case RecurrenceFrequency.yearly:
        return 'YEARLY';
    }
  }

  /// Форматирование даты в ISO8601 с указанием часового пояса UTC
  /// Формат: YYYY-MM-DDTHH:mm:ss.000Z (с миллисекундами и Z для UTC)
  /// Бэкенд ожидает полный формат ISO 8601 с указанием часового пояса
  static String _formatDateTime(DateTime dateTime) {
    // Преобразуем в UTC, если дата не в UTC
    final utcDateTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
    
    final year = utcDateTime.year.toString().padLeft(4, '0');
    final month = utcDateTime.month.toString().padLeft(2, '0');
    final day = utcDateTime.day.toString().padLeft(2, '0');
    final hour = utcDateTime.hour.toString().padLeft(2, '0');
    final minute = utcDateTime.minute.toString().padLeft(2, '0');
    final second = utcDateTime.second.toString().padLeft(2, '0');
    final millisecond = utcDateTime.millisecond.toString().padLeft(3, '0');
    
    // Формат: 2025-12-14T12:00:00.000Z
    return '$year-$month-${day}T$hour:$minute:$second.${millisecond}Z';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'title': title,
      if (description != null) 'description': description,
      'status': _statusToString(status),
      if (priority != null) 'priority': _priorityToString(priority),
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (assignedBy != null) 'assignedBy': assignedBy,
      if (assignmentDate != null)
        'assignmentDate': _formatDateTime(assignmentDate!),
      if (deadline != null) 'deadline': _formatDateTime(deadline!),
      'isImportant': isImportant,
      'isRecurring': isRecurring,
      'hasControlPoint': hasControlPoint,
      if (voiceNoteUrl != null) 'voiceNoteUrl': voiceNoteUrl,
      if (resultText != null) 'resultText': resultText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (observerIds != null && observerIds!.isNotEmpty)
        'observerIds': observerIds,
      if (attachments != null && attachments!.isNotEmpty)
        'attachments': attachments!.map((a) => {
              'id': a.id,
              'url': a.url,
              if (a.fileName != null) 'fileName': a.fileName,
              if (a.fileType != null) 'fileType': a.fileType,
              if (a.fileSize != null) 'fileSize': a.fileSize,
            }).toList(),
      if (indicators != null && indicators!.isNotEmpty)
        'indicators': indicators!.map((i) => {
              'id': i.id,
              'name': i.name,
              if (i.description != null) 'description': i.description,
              if (i.value != null) 'value': i.value,
            }).toList(),
      if (recurrence != null)
        'recurrence': {
          'frequency': _recurrenceFrequencyToString(recurrence!.frequency),
          'interval': recurrence!.interval,
          if (recurrence!.endDate != null)
            'endDate': _formatDateTime(recurrence!.endDate!),
          if (recurrence!.daysOfWeek != null)
            'daysOfWeek': recurrence!.daysOfWeek,
          if (recurrence!.dayOfMonth != null)
            'dayOfMonth': recurrence!.dayOfMonth,
        },
    };
  }

  /// Преобразование в JSON для создания задачи (без id, createdAt, updatedAt)
  Map<String, dynamic> toCreateJson() {
    return {
      'businessId': businessId,
      'title': title,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (status != TaskStatus.pending) 'status': _statusToString(status),
      if (priority != null) 'priority': _priorityToString(priority),
      if (assignedTo != null && assignedTo!.isNotEmpty) 'assignedTo': assignedTo,
      if (assignedBy != null && assignedBy!.isNotEmpty) 'assignedBy': assignedBy,
      if (assignmentDate != null)
        'assignmentDate': _formatDateTime(assignmentDate!),
      if (deadline != null) 'deadline': _formatDateTime(deadline!),
      if (isImportant) 'isImportant': isImportant,
      if (isRecurring) 'isRecurring': isRecurring,
      if (hasControlPoint) 'hasControlPoint': hasControlPoint,
      if (voiceNoteUrl != null && voiceNoteUrl!.isNotEmpty)
        'voiceNoteUrl': voiceNoteUrl,
      if (observerIds != null && observerIds!.isNotEmpty)
        'observerIds': observerIds,
      if (attachments != null && attachments!.isNotEmpty)
        'attachments': attachments!.map((a) => {
              'url': a.url,
              if (a.fileName != null) 'fileName': a.fileName,
              if (a.fileType != null) 'fileType': a.fileType,
              if (a.fileSize != null) 'fileSize': a.fileSize,
            }).toList(),
      if (indicators != null && indicators!.isNotEmpty)
        'indicators': indicators!.map((i) => {
              'name': i.name,
              if (i.description != null) 'description': i.description,
              if (i.value != null) 'value': i.value,
            }).toList(),
      if (recurrence != null)
        'recurrence': {
          'frequency': _recurrenceFrequencyToString(recurrence!.frequency),
          'interval': recurrence!.interval,
          if (recurrence!.endDate != null)
            'endDate': _formatDateTime(recurrence!.endDate!),
          if (recurrence!.daysOfWeek != null)
            'daysOfWeek': recurrence!.daysOfWeek,
          if (recurrence!.dayOfMonth != null)
            'dayOfMonth': recurrence!.dayOfMonth,
        },
    };
  }

  Task toEntity() {
    return Task(
      id: id,
      businessId: businessId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assignedTo: assignedTo,
      assignedBy: assignedBy,
      assignmentDate: assignmentDate,
      deadline: deadline,
      isImportant: isImportant,
      isRecurring: isRecurring,
      hasControlPoint: hasControlPoint,
      voiceNoteUrl: voiceNoteUrl,
      resultText: resultText,
      createdAt: createdAt,
      updatedAt: updatedAt,
      observerIds: observerIds,
      attachments: attachments,
      indicators: indicators,
      recurrence: recurrence,
    );
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      businessId: task.businessId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      assignedTo: task.assignedTo,
      assignedBy: task.assignedBy,
      assignmentDate: task.assignmentDate,
      deadline: task.deadline,
      isImportant: task.isImportant,
      isRecurring: task.isRecurring,
      hasControlPoint: task.hasControlPoint,
      voiceNoteUrl: task.voiceNoteUrl,
      resultText: task.resultText,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      observerIds: task.observerIds,
      attachments: task.attachments,
      indicators: task.indicators,
      recurrence: task.recurrence,
    );
  }
}


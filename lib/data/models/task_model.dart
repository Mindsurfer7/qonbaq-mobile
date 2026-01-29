import '../../domain/entities/task.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/customer.dart';
import '../models/model.dart';
import 'task_comment_model.dart';
import 'approval_model.dart';
import 'customer_model.dart';

/// Модель задачи
class TaskModel extends Task implements Model {
  // Временные поля для создания задачи (не сохраняются в entity)
  final String? _timeOfDay; // Время создания задачи в формате "HH:MM"
  final DateTime? _startDate; // Дата начала создания задач
  final int? _deadlineOffset; // Смещение дедлайна в часах
  final List<Map<String, dynamic>>?
  _controlPointMetrics; // Метрики для точки контроля

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
    super.dontForget,
    super.voiceNoteUrl,
    super.resultText,
    super.resultFileId,
    required super.createdAt,
    required super.updatedAt,
    super.observerIds,
    super.attachments,
    super.indicators,
    super.recurrence,
    super.approvalId,
    super.customerId,
    super.business,
    super.assignee,
    super.assigner,
    super.observers,
    super.comments,
    super.approval,
    super.customer,
    String? timeOfDay,
    DateTime? startDate,
    int? deadlineOffset,
    List<Map<String, dynamic>>? controlPointMetrics,
  }) : _timeOfDay = timeOfDay,
       _startDate = startDate,
       _deadlineOffset = deadlineOffset,
       _controlPointMetrics = controlPointMetrics;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // Парсинг business
    Business? business;
    if (json['business'] != null) {
      final businessJson = json['business'] as Map<String, dynamic>;
      business = Business(
        id: businessJson['id'] as String,
        name: businessJson['name'] as String,
      );
    }

    // Парсинг assignee (исполнитель)
    ProfileUser? assignee;
    if (json['assignee'] != null) {
      final assigneeJson = json['assignee'] as Map<String, dynamic>;
      assignee = ProfileUser(
        id: assigneeJson['id'] as String,
        email: assigneeJson['email'] as String,
        firstName: assigneeJson['firstName'] as String?,
        lastName: assigneeJson['lastName'] as String?,
        patronymic: assigneeJson['patronymic'] as String?,
        phone: assigneeJson['phone'] as String?,
      );
    }

    // Парсинг assigner (поручитель)
    ProfileUser? assigner;
    if (json['assigner'] != null) {
      final assignerJson = json['assigner'] as Map<String, dynamic>;
      assigner = ProfileUser(
        id: assignerJson['id'] as String,
        email: assignerJson['email'] as String,
        firstName: assignerJson['firstName'] as String?,
        lastName: assignerJson['lastName'] as String?,
        patronymic: assignerJson['patronymic'] as String?,
        phone: assignerJson['phone'] as String?,
      );
    }

    // Парсинг observers (наблюдатели)
    List<TaskObserver>? observers;
    if (json['observers'] != null) {
      final observersList = json['observers'] as List<dynamic>;
      observers =
          observersList.map((obsJson) {
            final userJson = obsJson['user'] as Map<String, dynamic>;
            return TaskObserver(
              id: obsJson['id'] as String,
              createdAt: DateTime.parse(obsJson['createdAt'] as String),
              user: ProfileUser(
                id: userJson['id'] as String,
                email: userJson['email'] as String,
                firstName: userJson['firstName'] as String?,
                lastName: userJson['lastName'] as String?,
                patronymic: userJson['patronymic'] as String?,
                phone: userJson['phone'] as String?,
              ),
            );
          }).toList();
    }

    // Парсинг observerIds (для обратной совместимости со списком задач)
    List<String>? observerIds;
    if (observers != null) {
      observerIds = observers.map((obs) => obs.user.id).toList();
    } else if (json['observers'] != null) {
      observerIds =
          (json['observers'] as List<dynamic>)
              .map((obs) => (obs['user']?['id'] ?? obs['userId']) as String)
              .toList();
    }

    // Парсинг attachments
    List<TaskAttachment>? attachments;
    if (json['attachments'] != null) {
      final attachmentsList = json['attachments'] as List<dynamic>;
      attachments =
          attachmentsList.map((att) {
            return TaskAttachment(
              id: att['id'] as String,
              taskId: att['taskId'] as String,
              fileUrl: att['fileUrl'] as String,
              fileName: att['fileName'] as String?,
              fileType: att['fileType'] as String?,
              isResult: att['isResult'] as bool? ?? false,
              createdAt: DateTime.parse(att['createdAt'] as String),
            );
          }).toList();
    }

    // Парсинг indicators
    List<TaskIndicator>? indicators;
    if (json['indicators'] != null) {
      final indicatorsList = json['indicators'] as List<dynamic>;
      indicators =
          indicatorsList.map((ind) {
            return TaskIndicator(
              id: ind['id'] as String,
              taskId: ind['taskId'] as String,
              name: ind['name'] as String,
              targetValue:
                  ind['targetValue'] != null
                      ? (ind['targetValue'] as num).toDouble()
                      : null,
              actualValue:
                  ind['actualValue'] != null
                      ? (ind['actualValue'] as num).toDouble()
                      : null,
              unit: ind['unit'] as String?,
              createdAt: DateTime.parse(ind['createdAt'] as String),
              updatedAt: DateTime.parse(ind['updatedAt'] as String),
            );
          }).toList();
    }

    // Парсинг recurrence
    TaskRecurrence? recurrence;
    if (json['recurrence'] != null) {
      final recJson = json['recurrence'] as Map<String, dynamic>;
      // Обработка daysOfWeek - может быть JSON строкой или массивом
      List<int>? daysOfWeek;
      if (recJson['daysOfWeek'] != null) {
        if (recJson['daysOfWeek'] is String) {
          // Если это JSON строка, парсим её
          try {
            final daysStr = recJson['daysOfWeek'] as String;
            if (daysStr.isNotEmpty) {
              // Простой парсинг массива чисел из строки вида "[1,3,5]"
              final cleaned =
                  daysStr.replaceAll('[', '').replaceAll(']', '').trim();
              if (cleaned.isNotEmpty) {
                daysOfWeek =
                    cleaned.split(',').map((d) => int.parse(d.trim())).toList();
              }
            }
          } catch (e) {
            // Если не получилось распарсить, оставляем null
          }
        } else if (recJson['daysOfWeek'] is List) {
          daysOfWeek =
              (recJson['daysOfWeek'] as List<dynamic>)
                  .map((d) => d as int)
                  .toList();
        }
      }

      recurrence = TaskRecurrence(
        id: recJson['id'] as String,
        taskId: recJson['taskId'] as String,
        frequency: _parseRecurrenceFrequency(recJson['frequency'] as String),
        interval: recJson['interval'] as int? ?? 1,
        endDate:
            recJson['endDate'] != null
                ? DateTime.parse(recJson['endDate'] as String)
                : null,
        daysOfWeek: daysOfWeek,
        dayOfMonth: recJson['dayOfMonth'] as int?,
        createdAt: DateTime.parse(recJson['createdAt'] as String),
        updatedAt: DateTime.parse(recJson['updatedAt'] as String),
      );
    }

    // Парсинг comments
    List<TaskComment>? comments;
    if (json['comments'] != null) {
      final commentsList = json['comments'] as List<dynamic>;
      comments =
          commentsList
              .map(
                (commentJson) =>
                    TaskCommentModel.fromJson(
                      commentJson as Map<String, dynamic>,
                    ).toEntity(),
              )
              .toList();
      // Комментарии отсортированы по createdAt desc на бэкенде
    }

    // Парсинг approval (согласование)
    Approval? approval;
    if (json['approval'] != null) {
      final approvalJson = json['approval'] as Map<String, dynamic>;
      approval = ApprovalModel.fromJson(approvalJson).toEntity();
    }

    // Парсинг customer (клиент)
    Customer? customer;
    if (json['customer'] != null) {
      try {
        final customerJson = json['customer'] as Map<String, dynamic>;
        // Проверяем наличие обязательных полей перед парсингом
        if (customerJson['id'] != null &&
            customerJson['businessId'] != null &&
            customerJson['customerType'] != null &&
            customerJson['createdAt'] != null &&
            customerJson['updatedAt'] != null) {
          customer = CustomerModel.fromJson(customerJson).toEntity();
        }
      } catch (e) {
        // Если не удалось распарсить customer, оставляем null
        // Это не критично, так как customer - опциональное поле
        customer = null;
      }
    }

    return TaskModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String?),
      priority: _parsePriority(json['priority'] as String?),
      assignedTo: json['assignedTo'] as String?,
      assignedBy: json['assignedBy'] as String?,
      assignmentDate:
          json['assignmentDate'] != null
              ? DateTime.parse(json['assignmentDate'] as String)
              : null,
      deadline:
          json['deadline'] != null
              ? DateTime.parse(json['deadline'] as String)
              : null,
      isImportant: json['isImportant'] as bool? ?? false,
      isRecurring: json['isRecurring'] as bool? ?? false,
      hasControlPoint: json['hasControlPoint'] as bool? ?? false,
      dontForget: json['dontForget'] as bool? ?? false,
      voiceNoteUrl: json['voiceNoteUrl'] as String?,
      resultText: json['resultText'] as String?,
      resultFileId: json['resultFileId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      observerIds: observerIds,
      attachments: attachments,
      indicators: indicators,
      recurrence: recurrence,
      approvalId: json['approvalId'] as String?,
      customerId: json['customerId'] as String?,
      business: business,
      assignee: assignee,
      assigner: assigner,
      observers: observers,
      comments: comments,
      approval: approval,
      customer: customer,
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

  static String measurementUnitToString(MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.kilogram:
        return 'KILOGRAM';
      case MeasurementUnit.gram:
        return 'GRAM';
      case MeasurementUnit.ton:
        return 'TON';
      case MeasurementUnit.meter:
        return 'METER';
      case MeasurementUnit.kilometer:
        return 'KILOMETER';
      case MeasurementUnit.hour:
        return 'HOUR';
      case MeasurementUnit.minute:
        return 'MINUTE';
      case MeasurementUnit.piece:
        return 'PIECE';
      case MeasurementUnit.liter:
        return 'LITER';
      case MeasurementUnit.custom:
        return 'CUSTOM';
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
      'dontForget': dontForget,
      if (voiceNoteUrl != null) 'voiceNoteUrl': voiceNoteUrl,
      if (resultText != null) 'resultText': resultText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (approvalId != null) 'approvalId': approvalId,
      if (customerId != null) 'customerId': customerId,
      if (observerIds != null && observerIds!.isNotEmpty)
        'observerIds': observerIds,
      if (attachments != null && attachments!.isNotEmpty)
        'attachments':
            attachments!
                .map(
                  (a) => {
                    'id': a.id,
                    'taskId': a.taskId,
                    'fileUrl': a.fileUrl,
                    if (a.fileName != null) 'fileName': a.fileName,
                    if (a.fileType != null) 'fileType': a.fileType,
                    'isResult': a.isResult,
                    'createdAt': a.createdAt.toIso8601String(),
                  },
                )
                .toList(),
      if (indicators != null && indicators!.isNotEmpty)
        'indicators':
            indicators!
                .map(
                  (i) => {
                    'id': i.id,
                    'taskId': i.taskId,
                    'name': i.name,
                    if (i.targetValue != null) 'targetValue': i.targetValue,
                    if (i.actualValue != null) 'actualValue': i.actualValue,
                    if (i.unit != null) 'unit': i.unit,
                    'createdAt': i.createdAt.toIso8601String(),
                    'updatedAt': i.updatedAt.toIso8601String(),
                  },
                )
                .toList(),
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
      if (assignedTo != null && assignedTo!.isNotEmpty)
        'assignedTo': assignedTo,
      if (assignedBy != null && assignedBy!.isNotEmpty)
        'assignedBy': assignedBy,
      if (assignmentDate != null)
        'assignmentDate': _formatDateTime(assignmentDate!),
      // Для обычных задач отправляем deadline
      if (!isRecurring && !hasControlPoint && deadline != null)
        'deadline': _formatDateTime(deadline!),
      if (isImportant) 'isImportant': isImportant,
      if (dontForget) 'dontForget': dontForget,
      if (approvalId != null && approvalId!.isNotEmpty)
        'approvalId': approvalId,
      if (customerId != null && customerId!.isNotEmpty)
        'customerId': customerId,
      if (voiceNoteUrl != null && voiceNoteUrl!.isNotEmpty)
        'voiceNoteUrl': voiceNoteUrl,
      if (resultText != null && resultText!.isNotEmpty)
        'resultText': resultText,
      if (resultFileId != null && resultFileId!.isNotEmpty)
        'resultFileId': resultFileId,
      if (observerIds != null && observerIds!.isNotEmpty)
        'observerIds': observerIds,
      // Флаги типа задачи
      if (isRecurring) 'isRecurring': isRecurring,
      if (hasControlPoint) 'isControlPoint': hasControlPoint,
      // Поля для регулярных задач и точек контроля
      if (isRecurring || hasControlPoint) ...{
        if (recurrence != null)
          'frequency': _recurrenceFrequencyToString(recurrence!.frequency),
        if (recurrence != null) 'interval': recurrence!.interval,
        if (_timeOfDay != null && _timeOfDay.isNotEmpty)
          'timeOfDay': _timeOfDay,
        if (recurrence?.daysOfWeek != null)
          'daysOfWeek': recurrence!.daysOfWeek,
        if (recurrence?.dayOfMonth != null)
          'dayOfMonth': recurrence!.dayOfMonth,
        if (_startDate != null) 'startDate': _formatDateTime(_startDate),
        if (recurrence?.endDate != null)
          'endDate': _formatDateTime(recurrence!.endDate!),
        if (_deadlineOffset != null) 'deadlineOffset': _deadlineOffset,
      },
      // Метрики для точек контроля
      if (hasControlPoint &&
          _controlPointMetrics != null &&
          _controlPointMetrics.isNotEmpty)
        'metrics': _controlPointMetrics,
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
      dontForget: dontForget,
      voiceNoteUrl: voiceNoteUrl,
      resultText: resultText,
      resultFileId: resultFileId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      observerIds: observerIds,
      attachments: attachments,
      indicators: indicators,
      recurrence: recurrence,
      approvalId: approvalId,
      business: business,
      assignee: assignee,
      assigner: assigner,
      observers: observers,
      comments: comments,
      approval: approval,
    );
  }

  factory TaskModel.fromEntity(
    Task task, {
    String? timeOfDay,
    DateTime? startDate,
    int? deadlineOffset,
    List<Map<String, dynamic>>? controlPointMetrics,
  }) {
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
      dontForget: task.dontForget,
      voiceNoteUrl: task.voiceNoteUrl,
      resultText: task.resultText,
      resultFileId: task.resultFileId,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      observerIds: task.observerIds,
      attachments: task.attachments,
      indicators: task.indicators,
      recurrence: task.recurrence,
      approvalId: task.approvalId,
      customerId: task.customerId,
      business: task.business,
      assignee: task.assignee,
      assigner: task.assigner,
      observers: task.observers,
      comments: task.comments,
      approval: task.approval,
      customer: task.customer,
      timeOfDay: timeOfDay,
      startDate: startDate,
      deadlineOffset: deadlineOffset,
      controlPointMetrics: controlPointMetrics,
    );
  }
}

import '../../domain/entities/control_point.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/task.dart';
import '../models/model.dart';

/// Модель точки контроля
class ControlPointModel extends ControlPoint implements Model {
  const ControlPointModel({
    required super.id,
    required super.businessId,
    required super.title,
    super.description,
    required super.assignedTo,
    super.assignedBy,
    required super.createdBy,
    required super.isActive,
    required super.frequency,
    super.interval,
    super.timeOfDay,
    super.daysOfWeek,
    super.dayOfMonth,
    required super.startDate,
    super.endDate,
    super.isImportant,
    super.dontForget,
    super.deadlineOffset,
    super.observerIds,
    required super.createdAt,
    required super.updatedAt,
    super.deactivatedAt,
    super.metrics,
    super.business,
    super.assignee,
    super.assigner,
    super.creator,
  });

  factory ControlPointModel.fromJson(Map<String, dynamic> json) {
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

    // Парсинг creator (создатель)
    ProfileUser? creator;
    if (json['creator'] != null) {
      final creatorJson = json['creator'] as Map<String, dynamic>;
      creator = ProfileUser(
        id: creatorJson['id'] as String,
        email: creatorJson['email'] as String,
        firstName: creatorJson['firstName'] as String?,
        lastName: creatorJson['lastName'] as String?,
        patronymic: creatorJson['patronymic'] as String?,
        phone: creatorJson['phone'] as String?,
      );
    }

    // Парсинг daysOfWeek - может быть JSON строкой или массивом
    List<int>? daysOfWeek;
    if (json['daysOfWeek'] != null) {
      if (json['daysOfWeek'] is String) {
        // Если это JSON строка, парсим её
        try {
          final daysStr = json['daysOfWeek'] as String;
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
      } else if (json['daysOfWeek'] is List) {
        daysOfWeek =
            (json['daysOfWeek'] as List<dynamic>).map((d) => d as int).toList();
      }
    }

    // Парсинг метрик
    List<ControlPointMetric>? metrics;
    if (json['metrics'] != null) {
      final metricsList = json['metrics'] as List<dynamic>;
      if (metricsList.isNotEmpty) {
        metrics = metricsList.map((m) {
          return ControlPointMetric(
            id: m['id'] as String,
            controlPointId: m['controlPointId'] as String,
            name: m['name'] as String,
            targetValue: (m['targetValue'] as num).toDouble(),
            unit: _parseMeasurementUnit(m['unit'] as String),
            customUnit: m['customUnit'] as String?,
            sortOrder: m['sortOrder'] as int? ?? 0,
            createdAt: DateTime.parse(m['createdAt'] as String),
            updatedAt: DateTime.parse(m['updatedAt'] as String),
          );
        }).toList();
      } else {
        metrics = [];
      }
    }

    // Парсинг observerIds
    List<String> observerIds = [];
    if (json['observerIds'] != null) {
      observerIds = (json['observerIds'] as List<dynamic>)
          .map((id) => id as String)
          .toList();
    }

    return ControlPointModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      assignedTo: json['assignedTo'] as String,
      assignedBy: json['assignedBy'] as String?,
      createdBy: json['createdBy'] as String,
      isActive: json['isActive'] as bool? ?? true,
      frequency: _parseRecurrenceFrequency(json['frequency'] as String),
      interval: json['interval'] as int? ?? 1,
      timeOfDay: json['timeOfDay'] as String?,
      daysOfWeek: daysOfWeek,
      dayOfMonth: json['dayOfMonth'] as int?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isImportant: json['isImportant'] as bool? ?? false,
      dontForget: json['dontForget'] as bool? ?? false,
      deadlineOffset: json['deadlineOffset'] as int?,
      observerIds: observerIds,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deactivatedAt: json['deactivatedAt'] != null
          ? DateTime.parse(json['deactivatedAt'] as String)
          : null,
      metrics: metrics,
      business: business,
      assignee: assignee,
      assigner: assigner,
      creator: creator,
    );
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

  static MeasurementUnit _parseMeasurementUnit(String unit) {
    switch (unit.toUpperCase()) {
      case 'KILOGRAM':
        return MeasurementUnit.kilogram;
      case 'GRAM':
        return MeasurementUnit.gram;
      case 'TON':
        return MeasurementUnit.ton;
      case 'METER':
        return MeasurementUnit.meter;
      case 'KILOMETER':
        return MeasurementUnit.kilometer;
      case 'HOUR':
        return MeasurementUnit.hour;
      case 'MINUTE':
        return MeasurementUnit.minute;
      case 'PIECE':
        return MeasurementUnit.piece;
      case 'LITER':
        return MeasurementUnit.liter;
      case 'CUSTOM':
        return MeasurementUnit.custom;
      default:
        return MeasurementUnit.piece;
    }
  }

  ControlPoint toEntity() {
    return ControlPoint(
      id: id,
      businessId: businessId,
      title: title,
      description: description,
      assignedTo: assignedTo,
      assignedBy: assignedBy,
      createdBy: createdBy,
      isActive: isActive,
      frequency: frequency,
      interval: interval,
      timeOfDay: timeOfDay,
      daysOfWeek: daysOfWeek,
      dayOfMonth: dayOfMonth,
      startDate: startDate,
      endDate: endDate,
      isImportant: isImportant,
      dontForget: dontForget,
      deadlineOffset: deadlineOffset,
      observerIds: observerIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deactivatedAt: deactivatedAt,
      metrics: metrics,
      business: business,
      assignee: assignee,
      assigner: assigner,
      creator: creator,
    );
  }

  factory ControlPointModel.fromEntity(ControlPoint controlPoint) {
    return ControlPointModel(
      id: controlPoint.id,
      businessId: controlPoint.businessId,
      title: controlPoint.title,
      description: controlPoint.description,
      assignedTo: controlPoint.assignedTo,
      assignedBy: controlPoint.assignedBy,
      createdBy: controlPoint.createdBy,
      isActive: controlPoint.isActive,
      frequency: controlPoint.frequency,
      interval: controlPoint.interval,
      timeOfDay: controlPoint.timeOfDay,
      daysOfWeek: controlPoint.daysOfWeek,
      dayOfMonth: controlPoint.dayOfMonth,
      startDate: controlPoint.startDate,
      endDate: controlPoint.endDate,
      isImportant: controlPoint.isImportant,
      dontForget: controlPoint.dontForget,
      deadlineOffset: controlPoint.deadlineOffset,
      observerIds: controlPoint.observerIds,
      createdAt: controlPoint.createdAt,
      updatedAt: controlPoint.updatedAt,
      deactivatedAt: controlPoint.deactivatedAt,
      metrics: controlPoint.metrics,
      business: controlPoint.business,
      assignee: controlPoint.assignee,
      assigner: controlPoint.assigner,
      creator: controlPoint.creator,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'title': title,
      if (description != null) 'description': description,
      'assignedTo': assignedTo,
      if (assignedBy != null) 'assignedBy': assignedBy,
      'createdBy': createdBy,
      'isActive': isActive,
      'frequency': _recurrenceFrequencyToString(frequency),
      'interval': interval,
      if (timeOfDay != null) 'timeOfDay': timeOfDay,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
      if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
      'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'isImportant': isImportant,
      'dontForget': dontForget,
      if (deadlineOffset != null) 'deadlineOffset': deadlineOffset,
      'observerIds': observerIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (deactivatedAt != null) 'deactivatedAt': deactivatedAt!.toIso8601String(),
      if (metrics != null)
        'metrics': metrics!.map((m) => {
              'id': m.id,
              'controlPointId': m.controlPointId,
              'name': m.name,
              'targetValue': m.targetValue,
              'unit': _measurementUnitToString(m.unit),
              if (m.customUnit != null) 'customUnit': m.customUnit,
              'sortOrder': m.sortOrder,
              'createdAt': m.createdAt.toIso8601String(),
              'updatedAt': m.updatedAt.toIso8601String(),
            }).toList(),
    };
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

  static String _measurementUnitToString(MeasurementUnit unit) {
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
}

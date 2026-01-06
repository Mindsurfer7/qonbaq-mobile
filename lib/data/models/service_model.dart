import '../../domain/entities/service.dart';
import '../../domain/entities/user_profile.dart';
import '../models/model.dart';
import 'service_assignment_model.dart';

/// Модель услуги
class ServiceModel extends Service implements Model {
  const ServiceModel({
    required super.id,
    required super.businessId,
    required super.name,
    super.description,
    required super.type,
    super.duration,
    super.price,
    super.currency,
    super.capacity,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.assignments,
    super.users,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // Парсинг assignments
    List<ServiceAssignment>? assignments;
    if (json['assignments'] != null) {
      final assignmentsList = json['assignments'] as List<dynamic>;
      assignments = assignmentsList
          .map((item) => ServiceAssignmentModel.fromJson(item as Map<String, dynamic>).toEntity())
          .toList();
    }

    // Парсинг users
    List<ProfileUser>? users;
    if (json['users'] != null) {
      final usersList = json['users'] as List<dynamic>;
      users = usersList.map((userJson) {
        final user = userJson as Map<String, dynamic>;
        return ProfileUser(
          id: user['id'] as String,
          email: '', // Email не приходит в API для users
          firstName: user['firstName'] as String?,
          lastName: user['lastName'] as String?,
        );
      }).toList();
    }

    // Парсинг type
    final type = ServiceType.fromString(json['type'] as String? ?? 'PERSON_BASED');

    // Парсинг duration - опционально
    int? duration;
    if (json['duration'] != null) {
      duration = json['duration'] as int;
    }

    // Парсинг price - может быть строкой или числом, опционально
    double? price;
    if (json['price'] != null) {
      if (json['price'] is String) {
        price = double.tryParse(json['price'] as String);
      } else if (json['price'] is num) {
        price = (json['price'] as num).toDouble();
      }
    }

    // Парсинг capacity - опционально
    int? capacity;
    if (json['capacity'] != null) {
      capacity = json['capacity'] as int;
    }

    return ServiceModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: type,
      duration: duration,
      price: price,
      currency: json['currency'] as String?,
      capacity: capacity,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      assignments: assignments,
      users: users,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      if (description != null) 'description': description,
      'type': type.value,
      if (duration != null) 'duration': duration,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (capacity != null) 'capacity': capacity,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (assignments != null && assignments!.isNotEmpty)
        'assignments': assignments!.map((a) {
          if (a is ServiceAssignmentModel) {
            return a.toJson();
          }
          return ServiceAssignmentModel.fromEntity(a).toJson();
        }).toList(),
    };
  }

  /// Преобразование в JSON для создания услуги
  Map<String, dynamic> toCreateJson({List<String>? employmentIds}) {
    return {
      'name': name,
      if (description != null && description!.isNotEmpty) 'description': description,
      'type': type.value,
      if (duration != null) 'duration': duration,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (capacity != null) 'capacity': capacity,
      if (employmentIds != null && employmentIds.isNotEmpty) 'employmentIds': employmentIds,
    };
  }

  /// Преобразование в JSON для обновления услуги
  Map<String, dynamic> toUpdateJson() {
    return {
      if (name.isNotEmpty) 'name': name,
      if (description != null) 'description': description,
      'type': type.value,
      if (duration != null && duration! > 0) 'duration': duration,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (capacity != null) 'capacity': capacity,
      'isActive': isActive,
    };
  }

  Service toEntity() {
    return Service(
      id: id,
      businessId: businessId,
      name: name,
      description: description,
      type: type,
      duration: duration,
      price: price,
      currency: currency,
      capacity: capacity,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      assignments: assignments,
      users: users,
    );
  }

  factory ServiceModel.fromEntity(Service service) {
    return ServiceModel(
      id: service.id,
      businessId: service.businessId,
      name: service.name,
      description: service.description,
      type: service.type,
      duration: service.duration,
      price: service.price,
      currency: service.currency,
      capacity: service.capacity,
      isActive: service.isActive,
      createdAt: service.createdAt,
      updatedAt: service.updatedAt,
      assignments: service.assignments,
      users: service.users,
    );
  }
}


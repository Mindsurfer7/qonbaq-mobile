import '../../domain/entities/customer_observer.dart';
import '../../domain/entities/user.dart';
import '../models/model.dart';

/// Модель наблюдателя за клиентом
class CustomerObserverModel extends CustomerObserver implements Model {
  const CustomerObserverModel({
    required super.id,
    required super.customerId,
    required super.userId,
    required super.createdAt,
    super.user,
  });

  factory CustomerObserverModel.fromJson(Map<String, dynamic> json) {
    // Парсинг user
    User? user;
    if (json['user'] != null) {
      final userJson = json['user'] as Map<String, dynamic>;
      user = User(
        id: userJson['id'] as String,
        name: userJson['firstName'] != null && userJson['lastName'] != null
            ? '${userJson['firstName']} ${userJson['lastName']}'
            : userJson['email'] as String? ?? '',
        email: userJson['email'] as String,
      );
    }

    return CustomerObserverModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: user,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      if (user != null)
        'user': {
          'id': user!.id,
          'email': user!.email,
        },
    };
  }

  /// Преобразование в JSON для создания наблюдателя
  Map<String, dynamic> toCreateJson() {
    return {
      'customerId': customerId,
      'userId': userId,
    };
  }

  CustomerObserver toEntity() {
    return CustomerObserver(
      id: id,
      customerId: customerId,
      userId: userId,
      createdAt: createdAt,
      user: user,
    );
  }

  factory CustomerObserverModel.fromEntity(CustomerObserver observer) {
    return CustomerObserverModel(
      id: observer.id,
      customerId: observer.customerId,
      userId: observer.userId,
      createdAt: observer.createdAt,
      user: observer.user,
    );
  }
}

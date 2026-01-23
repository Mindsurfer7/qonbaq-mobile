import '../../domain/entities/order.dart';
import '../../domain/entities/user.dart';
import '../models/model.dart';
import 'user_model.dart';

/// Модель наблюдателя за заказом
class OrderObserverModel extends OrderObserver implements Model {
  const OrderObserverModel({
    required super.id,
    required super.orderId,
    required super.userId,
    required super.createdAt,
    super.user,
  });

  factory OrderObserverModel.fromJson(Map<String, dynamic> json) {
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

    return OrderObserverModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: user,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      if (user != null) 'user': {
        'id': user!.id,
        'email': user!.email,
        'firstName': user!.name.split(' ').first,
        'lastName': user!.name.split(' ').length > 1 ? user!.name.split(' ').last : '',
      },
    };
  }

  OrderObserver toEntity() {
    return OrderObserver(
      id: id,
      orderId: orderId,
      userId: userId,
      createdAt: createdAt,
      user: user,
    );
  }

  factory OrderObserverModel.fromEntity(OrderObserver observer) {
    return OrderObserverModel(
      id: observer.id,
      orderId: observer.orderId,
      userId: observer.userId,
      createdAt: observer.createdAt,
      user: observer.user,
    );
  }
}

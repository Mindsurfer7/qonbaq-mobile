import '../models/model.dart';

/// Модель запроса регистрации
class RegisterRequest implements Model {
  final String email;
  final String username;
  final String password;
  final String? inviteCode;
  final String? firstName;
  final String? lastName;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
    this.inviteCode,
    this.firstName,
    this.lastName,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = {
      'email': email,
      'username': username,
      'password': password,
    };
    if (inviteCode != null && inviteCode!.isNotEmpty) {
      json['inviteCode'] = inviteCode!;
    }
    if (firstName != null && firstName!.isNotEmpty) {
      json['firstName'] = firstName!;
    }
    if (lastName != null && lastName!.isNotEmpty) {
      json['lastName'] = lastName!;
    }
    return json;
  }

  /// Валидация данных
  String? validate() {
    if (email.isEmpty) {
      return 'Email обязателен';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Неверный формат email';
    }
    if (username.isEmpty) {
      return 'Имя пользователя обязательно';
    }
    if (username.length < 3 || username.length > 30) {
      return 'Имя пользователя должно быть от 3 до 30 символов';
    }
    if (password.isEmpty) {
      return 'Пароль обязателен';
    }
    if (password.length < 6 || password.length > 100) {
      return 'Пароль должен быть от 6 до 100 символов';
    }
    return null;
  }
}

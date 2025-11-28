import '../../domain/entities/employee.dart';
import '../models/model.dart';

/// Модель сотрудника компании
class EmployeeModel extends Employee implements Model {
  const EmployeeModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.patronymic,
    super.email,
    super.position,
    super.department,
    super.employmentId,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    // API возвращает структуру с employment и user
    final user = json['user'] as Map<String, dynamic>? ?? json;
    final employment = json['employment'] as Map<String, dynamic>?;

    // Обрабатываем nullable поля - используем fallback значения
    final firstNameValue = user['firstName'] as String?;
    final lastNameValue = user['lastName'] as String?;
    final usernameValue = user['username'] as String?;
    
    // Если firstName/lastName null, используем username или пустую строку
    final firstName = firstNameValue ?? usernameValue ?? '';
    final lastName = lastNameValue ?? '';

    return EmployeeModel(
      id: user['id'] as String,
      firstName: firstName,
      lastName: lastName,
      patronymic: user['patronymic'] as String?,
      email: user['email'] as String?,
      position: employment?['position'] as String?,
      department: employment?['department'] as String?,
      employmentId: employment?['id'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      if (patronymic != null) 'patronymic': patronymic,
      if (email != null) 'email': email,
      if (position != null) 'position': position,
      if (department != null) 'department': department,
      if (employmentId != null) 'employmentId': employmentId,
    };
  }

  Employee toEntity() {
    return Employee(
      id: id,
      firstName: firstName,
      lastName: lastName,
      patronymic: patronymic,
      email: email,
      position: position,
      department: department,
      employmentId: employmentId,
    );
  }

  factory EmployeeModel.fromEntity(Employee employee) {
    return EmployeeModel(
      id: employee.id,
      firstName: employee.firstName,
      lastName: employee.lastName,
      patronymic: employee.patronymic,
      email: employee.email,
      position: employee.position,
      department: employee.department,
      employmentId: employee.employmentId,
    );
  }
}


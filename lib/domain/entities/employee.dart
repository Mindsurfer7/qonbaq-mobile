import '../entities/entity.dart';

/// Доменная сущность сотрудника компании
class Employee extends Entity {
  final String id; // ID пользователя
  final String firstName;
  final String lastName;
  final String? patronymic;
  final String? email;
  final String? position; // Должность из employment
  final String? department; // Отдел из employment
  final String? employmentId; // ID employment

  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.patronymic,
    this.email,
    this.position,
    this.department,
    this.employmentId,
  });

  /// Роль в бизнесе (используем position как роль)
  String? get role => position;

  /// Полное имя
  String get fullName {
    final parts = [lastName, firstName];
    if (patronymic != null && patronymic!.isNotEmpty) {
      parts.add(patronymic!);
    }
    return parts.join(' ');
  }

  /// Краткое имя (Фамилия И.О.)
  String get shortName {
    final lastNamePart = lastName;
    final firstNamePart = firstName.isNotEmpty ? firstName[0] : '';
    final patronymicPart =
        patronymic != null && patronymic!.isNotEmpty ? patronymic![0] : '';
    return '$lastNamePart $firstNamePart.$patronymicPart.'.trim();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Employee(id: $id, name: $fullName)';
}

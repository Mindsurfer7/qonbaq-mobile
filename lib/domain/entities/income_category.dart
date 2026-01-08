import 'entity.dart';

/// Категория дохода
class IncomeCategory extends Entity {
  final String id;
  final String name;

  const IncomeCategory({
    required this.id,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

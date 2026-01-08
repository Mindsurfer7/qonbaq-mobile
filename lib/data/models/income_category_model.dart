import '../../domain/entities/income_category.dart';

class IncomeCategoryModel extends IncomeCategory {
  const IncomeCategoryModel({
    required super.id,
    required super.name,
  });

  factory IncomeCategoryModel.fromJson(Map<String, dynamic> json) {
    return IncomeCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}



import '../datasources/datasource.dart';
import '../models/financial_form_model.dart';

/// Удаленный источник данных для финансовых форм (API)
abstract class FinancialRemoteDataSource extends DataSource {
  /// Получить форму для безналичной оплаты
  Future<FinancialFormModel> getCashlessForm({required String businessId});

  /// Получить форму для наличной оплаты
  Future<FinancialFormModel> getCashForm({required String businessId});
}


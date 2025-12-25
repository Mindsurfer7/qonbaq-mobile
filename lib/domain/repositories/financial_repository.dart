import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/approval_template.dart';

/// Репозиторий для финансовых форм
abstract class FinancialRepository {
  /// Получить форму для безналичной оплаты
  Future<Either<Failure, ApprovalTemplate>> getCashlessForm({
    required String businessId,
  });

  /// Получить форму для наличной оплаты
  Future<Either<Failure, ApprovalTemplate>> getCashForm({
    required String businessId,
  });
}


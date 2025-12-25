import 'package:dartz/dartz.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/repositories/financial_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/financial_remote_datasource.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория финансовых форм
class FinancialRepositoryImpl extends RepositoryImpl implements FinancialRepository {
  final FinancialRemoteDataSource remoteDataSource;

  FinancialRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, ApprovalTemplate>> getCashlessForm({
    required String businessId,
  }) async {
    try {
      final formModel = await remoteDataSource.getCashlessForm(businessId: businessId);
      return Right(formModel.toApprovalTemplate());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении формы безналичной оплаты: $e'));
    }
  }

  @override
  Future<Either<Failure, ApprovalTemplate>> getCashForm({
    required String businessId,
  }) async {
    try {
      final formModel = await remoteDataSource.getCashForm(businessId: businessId);
      return Right(formModel.toApprovalTemplate());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении формы наличной оплаты: $e'));
    }
  }
}


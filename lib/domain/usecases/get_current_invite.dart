import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/invite.dart';
import '../repositories/invite_repository.dart';

/// Use Case для получения текущего активного приглашения
class GetCurrentInvite implements UseCase<CreateInviteResult?, NoParams> {
  final InviteRepository repository;

  GetCurrentInvite(this.repository);

  @override
  Future<Either<Failure, CreateInviteResult?>> call(NoParams params) async {
    return await repository.getCurrentInvite();
  }
}


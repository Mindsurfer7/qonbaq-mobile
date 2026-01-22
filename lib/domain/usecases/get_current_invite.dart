import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/invite.dart';
import '../repositories/invite_repository.dart';

/// Use Case для получения текущих приглашений
class GetCurrentInvite implements UseCase<InvitesList?, NoParams> {
  final InviteRepository repository;

  GetCurrentInvite(this.repository);

  @override
  Future<Either<Failure, InvitesList?>> call(NoParams params) async {
    return await repository.getCurrentInvites();
  }
}








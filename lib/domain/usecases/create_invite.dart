import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/invite.dart';
import '../repositories/invite_repository.dart';

/// Параметры для создания приглашения
class CreateInviteParams {
  final String? inviteType;
  final int? maxUses;
  final DateTime? expiresAt;

  CreateInviteParams({
    this.inviteType,
    this.maxUses,
    this.expiresAt,
  });
}

/// Use Case для создания приглашения
class CreateInvite implements UseCase<InvitesList, CreateInviteParams> {
  final InviteRepository repository;

  CreateInvite(this.repository);

  @override
  Future<Either<Failure, InvitesList>> call(
    CreateInviteParams params,
  ) async {
    return await repository.createInvite(
      inviteType: params.inviteType,
      maxUses: params.maxUses,
      expiresAt: params.expiresAt,
    );
  }
}








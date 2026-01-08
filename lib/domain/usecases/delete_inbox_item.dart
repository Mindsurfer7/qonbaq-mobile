import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/inbox_repository.dart';

/// Параметры для удаления Inbox Item
class DeleteInboxItemParams {
  final String id;

  DeleteInboxItemParams({required this.id});
}

/// Use Case для удаления Inbox Item
class DeleteInboxItem implements UseCase<void, DeleteInboxItemParams> {
  final InboxRepository repository;

  DeleteInboxItem(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteInboxItemParams params) async {
    return await repository.deleteInboxItem(params.id);
  }
}




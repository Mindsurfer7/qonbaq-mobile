import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/inbox_item.dart';
import '../repositories/inbox_repository.dart';

/// Параметры для обновления Inbox Item
class UpdateInboxItemParams {
  final String id;
  final InboxItem inboxItem;

  UpdateInboxItemParams({
    required this.id,
    required this.inboxItem,
  });
}

/// Use Case для обновления Inbox Item
class UpdateInboxItem implements UseCase<InboxItem, UpdateInboxItemParams> {
  final InboxRepository repository;

  UpdateInboxItem(this.repository);

  @override
  Future<Either<Failure, InboxItem>> call(UpdateInboxItemParams params) async {
    return await repository.updateInboxItem(params.id, params.inboxItem);
  }
}


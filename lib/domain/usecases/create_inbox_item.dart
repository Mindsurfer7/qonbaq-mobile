import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/inbox_item.dart';
import '../repositories/inbox_repository.dart';

/// Параметры для создания Inbox Item
class CreateInboxItemParams {
  final InboxItem inboxItem;

  CreateInboxItemParams({required this.inboxItem});
}

/// Use Case для создания Inbox Item
class CreateInboxItem implements UseCase<InboxItem, CreateInboxItemParams> {
  final InboxRepository repository;

  CreateInboxItem(this.repository);

  @override
  Future<Either<Failure, InboxItem>> call(CreateInboxItemParams params) async {
    return await repository.createInboxItem(params.inboxItem);
  }
}


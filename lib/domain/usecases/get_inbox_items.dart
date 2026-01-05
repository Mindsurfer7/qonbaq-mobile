import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/inbox_item.dart';
import '../repositories/inbox_repository.dart';

/// Параметры для получения списка Inbox Items
class GetInboxItemsParams {
  final String? businessId;
  final bool? isArchived;
  final int? page;
  final int? limit;
  final String? sortBy;
  final String? sortOrder;

  GetInboxItemsParams({
    this.businessId,
    this.isArchived,
    this.page,
    this.limit,
    this.sortBy,
    this.sortOrder,
  });
}

/// Use Case для получения списка Inbox Items
class GetInboxItems implements UseCase<List<InboxItem>, GetInboxItemsParams> {
  final InboxRepository repository;

  GetInboxItems(this.repository);

  @override
  Future<Either<Failure, List<InboxItem>>> call(
    GetInboxItemsParams params,
  ) async {
    return await repository.getInboxItems(
      businessId: params.businessId,
      isArchived: params.isArchived,
      page: params.page,
      limit: params.limit,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}


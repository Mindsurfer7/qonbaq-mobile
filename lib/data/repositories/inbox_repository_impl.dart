import 'package:dartz/dartz.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/repositories/inbox_repository.dart';
import '../../core/error/failures.dart';
import '../models/inbox_item_model.dart';
import '../datasources/inbox_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../datasources/inbox_remote_datasource_impl.dart';
import '../models/validation_error.dart';

/// Реализация репозитория Inbox Items
/// Использует Remote DataSource
class InboxRepositoryImpl extends RepositoryImpl implements InboxRepository {
  final InboxRemoteDataSource remoteDataSource;

  InboxRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, InboxItem>> createInboxItem(
    InboxItem inboxItem,
  ) async {
    try {
      final inboxItemModel = InboxItemModel.fromEntity(inboxItem);
      final createdItem = await remoteDataSource.createInboxItem(inboxItemModel);
      return Right(createdItem.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании inbox item: $e'));
    }
  }

  @override
  Future<Either<Failure, InboxItem>> createInboxItemFromVoice({
    String? audioFile,
    List<int>? audioBytes,
    String filename = 'voice.m4a',
    required String businessId,
  }) async {
    try {
      final createdItem = await remoteDataSource.createInboxItemFromVoice(
        audioFile: audioFile,
        audioBytes: audioBytes,
        filename: filename,
        businessId: businessId,
      );
      return Right(createdItem.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании inbox item из голосового сообщения: $e'));
    }
  }

  @override
  Future<Either<Failure, InboxItem>> getInboxItemById(String id) async {
    try {
      final item = await remoteDataSource.getInboxItemById(id);
      return Right(item.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении inbox item: $e'));
    }
  }

  @override
  Future<Either<Failure, List<InboxItem>>> getInboxItems({
    String? businessId,
    bool? isArchived,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final items = await remoteDataSource.getInboxItems(
        businessId: businessId,
        isArchived: isArchived,
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      return Right(items.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении inbox items: $e'));
    }
  }

  @override
  Future<Either<Failure, InboxItem>> updateInboxItem(
    String id,
    InboxItem inboxItem,
  ) async {
    try {
      final inboxItemModel = InboxItemModel.fromEntity(inboxItem);
      final updatedItem = await remoteDataSource.updateInboxItem(id, inboxItemModel);
      return Right(updatedItem.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении inbox item: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInboxItem(String id) async {
    try {
      await remoteDataSource.deleteInboxItem(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении inbox item: $e'));
    }
  }
}


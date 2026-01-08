import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/inbox_item.dart';
import '../repositories/inbox_repository.dart';

/// Параметры для создания Inbox Item через голосовое сообщение
class CreateInboxItemFromVoiceParams {
  final String? audioFile;
  final List<int>? audioBytes;
  final String filename;
  final String businessId;

  CreateInboxItemFromVoiceParams({
    this.audioFile,
    this.audioBytes,
    this.filename = 'voice.m4a',
    required this.businessId,
  });
}

/// Use Case для создания Inbox Item через голосовое сообщение
class CreateInboxItemFromVoice implements UseCase<InboxItem, CreateInboxItemFromVoiceParams> {
  final InboxRepository repository;

  CreateInboxItemFromVoice(this.repository);

  @override
  Future<Either<Failure, InboxItem>> call(CreateInboxItemFromVoiceParams params) async {
    return await repository.createInboxItemFromVoice(
      audioFile: params.audioFile,
      audioBytes: params.audioBytes,
      filename: params.filename,
      businessId: params.businessId,
    );
  }
}




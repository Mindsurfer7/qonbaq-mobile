import '../datasources/datasource.dart';
import '../models/task_model.dart';

/// Удаленный источник данных для голосового ассистента
abstract class VoiceAssistRemoteDataSource extends DataSource {
  /// Отправить аудиофайл на обработку голосовым ассистентом
  /// 
  /// [audioFile] - файл с аудио (для мобильных платформ)
  /// [audioBytes] - байты аудио (для веб-платформы)
  /// [filename] - имя файла
  /// [context] - контекст: "task" или "approval"
  /// [templateCode] - код шаблона согласования (для approval)
  /// [templateId] - UUID шаблона согласования (для approval)
  /// 
  /// Возвращает предзаполненные данные задачи
  Future<TaskModel> processVoiceMessage({
    String? audioFile,
    List<int>? audioBytes,
    String filename = 'voice.m4a',
    required String context,
    String? templateCode,
    String? templateId,
  });
}


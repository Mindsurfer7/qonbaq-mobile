import '../datasources/datasource.dart';
import '../models/transcription_response.dart';

/// Удаленный источник данных для транскрипции аудио
abstract class TranscriptionRemoteDataSource extends DataSource {
  /// Отправить аудиофайл на транскрипцию
  /// 
  /// [audioFile] - файл с аудио (для мобильных платформ)
  /// [audioBytes] - байты аудио (для веб-платформы)
  /// [filename] - имя файла
  Future<TranscriptionResponse> transcribeAudio({
    String? audioFile,
    List<int>? audioBytes,
    String filename = 'voice.m4a',
  });
}


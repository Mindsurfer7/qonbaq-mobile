import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, ChangeNotifier, debugPrint;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/transcription_remote_datasource_impl.dart';

/// Состояния записи голоса
enum RecordingState {
  idle, // Не записываем - начальное состояние
  recording, // Идет запись - активная запись
  recorded, // Есть готовая запись - запись остановлена, но не отправлена
  loading, // Обрабатываем запись - отправка на backend
}

/// Сервис для управления записью аудио
class AudioRecordingService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final TranscriptionRemoteDataSourceImpl _transcriptionDataSource;

  RecordingState _state = RecordingState.idle;
  int _recordingDuration = 0;
  Timer? _timer;
  String? _currentRecordingPath;

  AudioRecordingService(this._transcriptionDataSource);

  /// Текущее состояние записи
  RecordingState get state => _state;

  /// Длительность текущей записи в секундах
  int get recordingDuration => _recordingDuration;

  /// Путь к текущей записи (для мобильных платформ)
  String? get currentRecordingPath => _currentRecordingPath;

  /// Запускает таймер записи
  void _startTimer() {
    debugPrint('🎤 Запускаем таймер записи');
    _timer?.cancel();
    _recordingDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state != RecordingState.recording) {
        timer.cancel();
        return;
      }
      _recordingDuration++;
      notifyListeners();
      debugPrint('🎤 Время записи: $_recordingDuration сек');

      // Лимит 5 минут
      if (_recordingDuration >= 300) {
        debugPrint('📢 Останавливаем запись по таймеру (5 минут)');
        stopRecording();
      }
    });
  }

  /// Обновляет состояние и уведомляет слушателей
  void _updateState(RecordingState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Начинает запись
  Future<void> startRecording() async {
    debugPrint('📢 === AudioRecordingService: startRecording ===');

    // Проверяем состояние recorder'а
    try {
      final isRecording = await _recorder.isRecording();
      debugPrint('🎤 Состояние recorder: isRecording=$isRecording');
      if (isRecording) {
        debugPrint('⚠️ Recorder уже записывает, останавливаем');
        await _recorder.stop();
      }
    } catch (e) {
      debugPrint('❌ Ошибка проверки состояния recorder: $e');
    }

    // Проверка разрешений
    try {
      final hasPermission = await _recorder.hasPermission();
      debugPrint('🎤 Разрешения на микрофон: $hasPermission');
      if (!hasPermission) {
        debugPrint('❌ Нет разрешения на микрофон');
        throw Exception('Нет разрешения на микрофон');
      }
    } catch (e) {
      debugPrint('❌ Ошибка проверки разрешений: $e');
      throw Exception('Ошибка проверки разрешений: $e');
    }

    // Создаем путь для записи (только для не-веб)
    String? recordingPath;
    if (!kIsWeb) {
      try {
        final dir = await getTemporaryDirectory();
        recordingPath =
            "${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a";
        debugPrint('📢 Путь для записи: $recordingPath');
      } catch (e) {
        debugPrint('❌ Ошибка получения временной директории: $e');
        throw Exception('Ошибка доступа к хранилищу');
      }
    }

    // Начинаем запись
    try {
      // Используем оптимальные параметры для речи
      // AAC LC для мобильных, Opus для веба (но record пакет не поддерживает Opus напрямую, используем AAC)
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000, // Достаточно для речи
        bitRate: 24000, // 24 кбит/с - оптимально для голоса
        numChannels: 1, // Моно для голосовых сообщений
      );
      if (kIsWeb) {
        await _recorder.start(config, path: '');
        debugPrint('📢 Запись (веб) началась успешно');
      } else {
        await _recorder.start(config, path: recordingPath!);
        debugPrint('📢 Запись (мобильная) началась успешно');
      }

      // Проверяем что запись началась
      final isRecordingAfterStart = await _recorder.isRecording();
      debugPrint('🎤 isRecording после start: $isRecordingAfterStart');

      _currentRecordingPath = recordingPath;
      _updateState(RecordingState.recording);
      _startTimer();
      debugPrint('✅ Запись успешно начата');
    } catch (e) {
      debugPrint('❌ Ошибка начала записи: $e');
      throw Exception('Не удалось начать запись: $e');
    }
  }

  /// Останавливает запись
  Future<void> stopRecording() async {
    debugPrint('📢 === AudioRecordingService: stopRecording ===');

    if (_state != RecordingState.recording) {
      debugPrint('⚠️ Запись не активна');
      return;
    }

    try {
      // Проверяем состояние перед остановкой
      final isRecording = await _recorder.isRecording();
      debugPrint('🎤 isRecording перед stop: $isRecording');

      final result = await _recorder.stop();
      debugPrint('📢 Запись остановлена, результат: $result');

      _timer?.cancel();

      String? finalPath;

      if (kIsWeb) {
        if (result != null) {
          finalPath = result.toString();
          debugPrint('📢 Веб-запись: ${finalPath.length} символов');
        }
      } else {
      if (result != null && result.isNotEmpty) {
        finalPath = result;
          // Проверяем файл
          try {
            final file = File(finalPath);
            final exists = await file.exists();
            debugPrint('📢 Файл существует: $exists');
            if (exists) {
              final size = await file.length();
              debugPrint('📢 Размер файла: $size байт');
            }
          } catch (e) {
            debugPrint('❌ Ошибка проверки файла: $e');
          }
        }
      }

      if (finalPath != null && finalPath.isNotEmpty) {
        _currentRecordingPath = finalPath;
        _updateState(RecordingState.recorded);
        debugPrint('✅ Запись успешно остановлена');
      } else {
        debugPrint('❌ Результат записи пустой');
        cancelRecording();
      }
    } catch (e) {
      debugPrint('❌ Ошибка остановки записи: $e');
      cancelRecording();
      throw Exception('Ошибка остановки записи: $e');
    }
  }

  /// Отменяет запись
  void cancelRecording() {
    debugPrint('📢 === AudioRecordingService: cancelRecording ===');
    _timer?.cancel();

    // Удаляем файл
    if (_currentRecordingPath != null && !kIsWeb) {
      final file = File(_currentRecordingPath!);
      file.delete().catchError((e) {
        debugPrint("⚠️ Не удалось удалить файл: $e");
        return file;
      });
    }

    _currentRecordingPath = null;
    _recordingDuration = 0;
    _updateState(RecordingState.idle);
    debugPrint('✅ Запись отменена');
  }

  /// Принимает запись и отправляет на транскрипцию
  Future<String> acceptRecording() async {
    debugPrint('📢 === AudioRecordingService: acceptRecording ===');

    if (_currentRecordingPath == null) {
      throw Exception('Нет записи для обработки');
    }

    final recordingPath = _currentRecordingPath!;
    _updateState(RecordingState.loading);

    try {
      String transcription;

      if (kIsWeb) {
        transcription = await _handleWebRecord(recordingPath);
      } else {
        transcription = await _handleNonWebRecord(recordingPath);
      }

      debugPrint('✅ Транскрипция завершена: $transcription');
      return transcription;
    } catch (e) {
      debugPrint('❌ Ошибка транскрипции: $e');
      rethrow;
    } finally {
      _currentRecordingPath = null;
      _recordingDuration = 0;
      _updateState(RecordingState.idle);
    }
  }

  /// Обрабатывает файл для мобильных платформ
  Future<String> _handleNonWebRecord(String filePath) async {
    final file = File(filePath);
    final fileSize = await file.length();
    debugPrint('📢 Обрабатываем файл: размер $fileSize байт');

    if (fileSize == 0) {
      throw Exception('Файл записи пустой');
    }

    if (!TranscriptionRemoteDataSourceImpl.isValidFileSize(fileSize)) {
      throw Exception('Файл слишком большой. Максимум: 25 МБ');
    }

    final transcriptionResponse = await _transcriptionDataSource.transcribeAudio(
      audioFile: filePath,
      filename: 'voice.m4a',
    );

    // Удаляем временный файл
    try {
      if (await file.exists()) {
        await file.delete();
        debugPrint("🗑️ Временный файл удален");
      }
    } catch (e) {
      debugPrint("⚠️ Не удалось удалить временный файл: $e");
    }

    if (transcriptionResponse.text.trim().isEmpty) {
      throw Exception('Распознан пустой текст');
    }

    return transcriptionResponse.text;
  }

  /// Обрабатывает Blob для веб
  Future<String> _handleWebRecord(String blobUrl) async {
    final audioResponse = await http.get(Uri.parse(blobUrl));
    if (audioResponse.statusCode != 200) {
      throw Exception('Ошибка загрузки из Blob: ${audioResponse.statusCode}');
    }

    final audioBytes = audioResponse.bodyBytes;
    debugPrint('📢 Получено ${audioBytes.length} байт из Blob');

    if (audioBytes.isEmpty) {
      throw Exception("Запись пустая");
    }

    if (!TranscriptionRemoteDataSourceImpl.isValidFileSize(audioBytes.length)) {
      throw Exception("Файл слишком большой. Максимум: 25 МБ");
    }

    final transcriptionResponse = await _transcriptionDataSource.transcribeAudio(
      audioBytes: audioBytes,
      filename: 'voice.m4a',
    );

    if (transcriptionResponse.text.trim().isEmpty) {
      throw Exception("Распознан пустой текст");
    }

    return transcriptionResponse.text;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}


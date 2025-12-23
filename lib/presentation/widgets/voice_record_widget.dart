import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_recording_service.dart';
import 'dart:math' as math;

/// Переиспользуемый виджет для записи голоса
///
/// Виджет может быть встроен в разные части приложения:
/// - В чат для отправки сообщений с голосом
/// - В форму создания задачи с голосовым описанием
/// - В заметки для голосовых заметок
class VoiceRecordWidget extends StatefulWidget {
  /// Callback, вызываемый когда получен текст транскрипции
  final void Function(String transcription)? onTranscriptionReceived;

  /// Callback, вызываемый при ошибке
  final void Function(String error)? onError;

  /// Вид интерфейса записи
  final VoiceRecordStyle style;

  /// Кнопка для начала записи (когда запись не активна)
  final Widget? recordButton;

  const VoiceRecordWidget({
    super.key,
    this.onTranscriptionReceived,
    this.onError,
    this.style = VoiceRecordStyle.compact,
    this.recordButton,
  });

  @override
  State<VoiceRecordWidget> createState() => _VoiceRecordWidgetState();
}

class _VoiceRecordWidgetState extends State<VoiceRecordWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioRecordingService>(
      builder: (context, audioService, child) {
        // Если запись не активна, показываем кнопку записи
        if (audioService.state == RecordingState.idle) {
          return _buildIdleState(context, audioService);
        }

        // Если идет запись или обработка, показываем интерфейс записи
        if (widget.style == VoiceRecordStyle.fullscreen) {
          return _buildFullscreenInterface(context, audioService);
        } else {
          return _buildCompactInterface(context, audioService);
        }
      },
    );
  }

  /// Строит интерфейс в состоянии покоя (кнопка записи)
  Widget _buildIdleState(
    BuildContext context,
    AudioRecordingService audioService,
  ) {
    if (widget.recordButton != null) {
      return GestureDetector(
        onTap: () => _startRecording(context, audioService),
        child: widget.recordButton,
      );
    }

    return IconButton(
      icon: const Icon(Icons.mic_none),
      onPressed: () => _startRecording(context, audioService),
      tooltip: 'Начать запись',
    );
  }

  /// Компактный интерфейс (для встраивания в чат и т.д.)
  Widget _buildCompactInterface(
    BuildContext context,
    AudioRecordingService audioService,
  ) {
    final minutes = audioService.recordingDuration ~/ 60;
    final seconds = audioService.recordingDuration % 60;
    final timeText =
        "${minutes.toString()}:${seconds.toString().padLeft(2, '0')}";

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 225, 225, 225),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color.fromARGB(255, 57, 57, 57),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Область записи сверху
          Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Индикатор записи
                Expanded(
                  child:
                      audioService.state == RecordingState.loading
                          ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : const Row(
                            children: [
                              Icon(Icons.mic, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Запись...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                ),
                // Таймер справа
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Кнопки управления
          if (audioService.state == RecordingState.recording ||
              audioService.state == RecordingState.recorded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Кнопка отмены
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => _cancelRecording(audioService),
                    tooltip: 'Отменить',
                  ),
                  // Кнопка подтверждения
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _acceptRecording(context, audioService),
                    tooltip: 'Подтвердить',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Полноэкранный интерфейс (для более иммерсивного опыта)
  Widget _buildFullscreenInterface(
    BuildContext context,
    AudioRecordingService audioService,
  ) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Column(
          children: [
            // Верхняя панель с кнопками
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Крестик (отмена)
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => _cancelRecording(audioService),
                  ),
                  // Таймер и статус
                  Column(
                    children: [
                      if (audioService.state == RecordingState.recording) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(audioService.recordingDuration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ] else if (audioService.state ==
                          RecordingState.loading) ...[
                        const Text(
                          "Обработка...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Галочка (принять)
                  IconButton(
                    icon: Icon(
                      audioService.state == RecordingState.loading
                          ? Icons.hourglass_empty
                          : Icons.check,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed:
                        audioService.state == RecordingState.loading
                            ? null
                            : () => _acceptRecording(context, audioService),
                  ),
                ],
              ),
            ),
            // Центральная часть с анимацией волн
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Анимированные волны
                    if (audioService.state == RecordingState.recording)
                      SizedBox(
                        height: 100,
                        child: AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: WavePainter(_waveController.value),
                              size: Size(
                                MediaQuery.of(context).size.width,
                                100,
                              ),
                            );
                          },
                        ),
                      ),
                    // Индикатор загрузки
                    if (audioService.state == RecordingState.loading)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    const SizedBox(height: 20),
                    // Текстовая подсказка
                    Text(
                      _getHintText(audioService.state),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  String _getHintText(RecordingState state) {
    switch (state) {
      case RecordingState.recording:
        return "Говорите...\nНажмите ✓ чтобы остановить запись";
      case RecordingState.recorded:
        return "Запись готова\nНажмите ✓ чтобы отправить\nили ✕ чтобы отменить";
      case RecordingState.loading:
        return "Обрабатываем запись...";
      case RecordingState.idle:
        return "";
    }
  }

  /// Начинает запись
  Future<void> _startRecording(
    BuildContext context,
    AudioRecordingService audioService,
  ) async {
    try {
      await audioService.startRecording();
    } catch (e) {
      final errorMessage = 'Ошибка начала записи: $e';
      if (widget.onError != null) {
        widget.onError!(errorMessage);
      } else if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  /// Отменяет запись
  void _cancelRecording(AudioRecordingService audioService) {
    audioService.cancelRecording();
  }

  /// Принимает запись и отправляет на транскрипцию
  Future<void> _acceptRecording(
    BuildContext context,
    AudioRecordingService audioService,
  ) async {
    if (audioService.state == RecordingState.recording) {
      // Сначала останавливаем запись
      await audioService.stopRecording();
    } else if (audioService.state == RecordingState.recorded) {
      // Отправляем на транскрипцию
      try {
        final transcription = await audioService.acceptRecording();
        if (context.mounted) {
          widget.onTranscriptionReceived?.call(transcription);
        }
      } catch (e) {
        final errorMessage = 'Ошибка транскрипции: $e';
        if (widget.onError != null) {
          widget.onError!(errorMessage);
        } else if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    }
  }
}

/// Отрисовщик волн для анимации записи
class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    const waveCount = 8;

    for (int i = 0; i < waveCount; i++) {
      final path = Path();
      final startX =
          -size.width +
          (animationValue * size.width * 2) +
          (i * size.width / waveCount);

      path.moveTo(startX, centerY);

      for (double x = startX; x <= startX + size.width; x += 20) {
        final y =
            centerY +
            20 * math.sin((x - startX) * 0.02 + animationValue * 2 * math.pi);
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Стиль интерфейса записи
enum VoiceRecordStyle {
  /// Компактный интерфейс (для встраивания в чат и т.д.)
  compact,

  /// Полноэкранный интерфейс (для более иммерсивного опыта)
  fullscreen,
}

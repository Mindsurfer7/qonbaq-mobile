import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_recording_service.dart';
import '../../core/services/voice_context.dart';
import 'dart:math' as math;

/// Переиспользуемый виджет для записи голоса
///
/// Виджет может быть встроен в разные части приложения:
/// - В чат для отправки сообщений с голосом (VoiceContext.transcription)
/// - В форму создания задачи с голосовым описанием (VoiceContext.task)
/// - В форму создания согласования (VoiceContext.approval)
/// - В страницу "Не забыть выполнить" (VoiceContext.dontForget)
class VoiceRecordWidget extends StatefulWidget {
  /// Контекст использования голосового сообщения
  /// Определяет, какой endpoint будет вызван и какой тип данных вернется
  final VoiceContext context;

  /// Callback, вызываемый когда получен результат обработки
  ///
  /// Тип результата зависит от контекста:
  /// - VoiceContext.transcription → String (текст транскрипции)
  /// - VoiceContext.task → TaskModel (предзаполненные данные задачи)
  /// - VoiceContext.approval → ApprovalModel (предзаполненные данные согласования)
  /// - VoiceContext.dontForget → TaskModel (предзаполненные данные задачи)
  final void Function(dynamic result) onResultReceived;

  /// Callback, вызываемый при ошибке
  final void Function(String error)? onError;

  /// Вид интерфейса записи
  final VoiceRecordStyle style;

  /// Кнопка для начала записи (когда запись не активна)
  final Widget? recordButton;

  /// Код шаблона согласования (для VoiceContext.approval)
  final String? templateCode;

  /// UUID шаблона согласования (для VoiceContext.approval)
  final String? templateId;

  const VoiceRecordWidget({
    super.key,
    required this.context,
    required this.onResultReceived,
    this.onError,
    this.style = VoiceRecordStyle.compact,
    this.recordButton,
    this.templateCode,
    this.templateId,
  });

  @override
  State<VoiceRecordWidget> createState() => _VoiceRecordWidgetState();
}

class _VoiceRecordWidgetState extends State<VoiceRecordWidget>
    with TickerProviderStateMixin {
  late AnimationController _barsAnimationController;
  late Animation<double> _barsAnimation;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    // Анимация для компактных палочек
    _barsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _barsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barsAnimationController, curve: Curves.linear),
    );

    // Анимация для полноэкранных волн
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _barsAnimationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioRecordingService>(
      builder: (context, audioService, child) {
        // Управляем анимацией в зависимости от состояния записи
        if (audioService.state == RecordingState.recording) {
          if (!_barsAnimationController.isAnimating) {
            _barsAnimationController.repeat();
          }
        } else {
          if (_barsAnimationController.isAnimating) {
            _barsAnimationController.stop();
            _barsAnimationController.reset();
          }
        }

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
          // Область записи сверху (анимация и таймер)
          Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Область с движущимися палочками
                Expanded(
                  child: Container(
                    height: 30,
                    child:
                        audioService.state == RecordingState.loading
                            ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : ClipRect(
                              // Обрезаем содержимое чтобы палочки не выходили за границы
                              child: _buildCompactMovingBars(),
                            ),
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
          // Кнопки управления снизу
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
                  // Кнопка подтверждения (галочка)
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

  /// Компактные движущиеся палочки для нижнего блока
  Widget _buildCompactMovingBars() {
    return AnimatedBuilder(
      animation: _barsAnimation,
      builder: (context, child) {
        return Container(
          height: 30,
          child: CustomPaint(
            painter: CompactMovingBarsPainter(_barsAnimation.value),
            size: const Size(double.infinity, 30),
          ),
        );
      },
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

  /// Принимает запись и отправляет на обработку в зависимости от контекста
  Future<void> _acceptRecording(
    BuildContext context,
    AudioRecordingService audioService,
  ) async {
    try {
      // Если запись идет, сначала останавливаем ее
      if (audioService.state == RecordingState.recording) {
        await audioService.stopRecording();
      }

      // Отправляем на обработку с указанным контекстом
      final result = await audioService.processRecordingWithContext(
        widget.context,
        templateCode: widget.templateCode,
        templateId: widget.templateId,
      );

      if (context.mounted) {
        widget.onResultReceived(result);
      }
    } catch (e) {
      final errorMessage = 'Ошибка обработки голосового сообщения: $e';
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

/// Класс для рисования компактных движущихся палочек
class CompactMovingBarsPainter extends CustomPainter {
  final double animationValue;

  const CompactMovingBarsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black54
          ..strokeCap = StrokeCap.round;

    // Параметры палочек для компактного вида
    const barWidth = 1.5;
    const barSpacing = 4.0;

    // Смещение для плавного движения
    final offset = animationValue * barSpacing * 4;

    // Рисуем палочки начиная с отрицательной позиции для плавного появления
    final startIndex = -(offset / barSpacing).floor() - 5;
    final endIndex = startIndex + (size.width / barSpacing).ceil() + 15;

    // Рисуем палочки с плавным движением
    for (int i = startIndex; i < endIndex; i++) {
      // Позиция X
      final x = (i * barSpacing) - offset;

      // Показываем только палочки, которые видны на экране
      if (x >= -barWidth && x <= size.width + barWidth) {
        // Высота палочки с вариацией (используем абсолютное значение индекса)
        final heights = [4.0, 8.0, 12.0, 6.0, 10.0, 5.0, 14.0];
        final barHeight = heights[i.abs() % heights.length];

        // Центрируем палочку по вертикали
        final y1 = (size.height - barHeight) / 2;
        final y2 = y1 + barHeight;

        paint.strokeWidth = barWidth;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Отрисовщик волн для анимации записи (полноэкранный режим)
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/voice_context.dart';
import '../../core/services/audio_recording_service.dart';
import 'voice_record_widget.dart';

/// Блок с информацией о голосовой записи и кнопкой записи
///
/// Отображает текст слева и иконку записи справа.
/// Когда запись активна, скрывает текст и показывает полный интерфейс записи.
class VoiceRecordBlock extends StatelessWidget {
  /// Контекст использования голосового сообщения
  final VoiceContext context;

  /// Callback, вызываемый когда получен результат обработки
  final void Function(dynamic result) onResultReceived;

  /// Callback, вызываемый при ошибке
  final void Function(String error)? onError;

  /// Код шаблона согласования (для VoiceContext.approval)
  final String? templateCode;

  /// UUID шаблона согласования (для VoiceContext.approval)
  final String? templateId;

  /// Текст подсказки (опционально, по умолчанию стандартный)
  final String? hintText;

  const VoiceRecordBlock({
    super.key,
    required this.context,
    required this.onResultReceived,
    this.onError,
    this.templateCode,
    this.templateId,
    this.hintText,
  });

  String _getDefaultHintText() {
    switch (context) {
      case VoiceContext.task:
        return 'Вы можете проговорить голосом все, что нужно по этой задаче, ИИ заполнит ее сам';
      case VoiceContext.approval:
        return 'Вы можете проговорить голосом все, что нужно по этому согласованию, ИИ заполнит его сам';
      case VoiceContext.dontForget:
        return 'Вы можете проговорить голосом все, что нужно, ИИ заполнит сам';
      case VoiceContext.transcription:
        return 'Вы можете проговорить сообщение голосом';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioRecordingService>(
      builder: (context, audioService, child) {
        // Если запись активна (recording, recorded, loading), показываем полный интерфейс
        if (audioService.state != RecordingState.idle) {
          return VoiceRecordWidget(
            context: this.context,
            style: VoiceRecordStyle.compact,
            onResultReceived: onResultReceived,
            onError: onError,
            templateCode: templateCode,
            templateId: templateId,
          );
        }

        // Когда запись не активна, показываем блок с текстом и кнопкой
        final hint = hintText ?? _getDefaultHintText();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: Row(
            children: [
              // Текст слева
              Expanded(
                child: Text(
                  hint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Иконка записи справа
              VoiceRecordWidget(
                context: this.context,
                style: VoiceRecordStyle.compact,
                recordButton: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 24),
                ),
                onResultReceived: onResultReceived,
                onError: onError,
                templateCode: templateCode,
                templateId: templateId,
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/voice_context.dart';
import '../../core/services/audio_recording_service.dart';
import '../../data/models/task_model.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/create_task.dart';
import '../../data/models/validation_error.dart';
import '../../core/error/failures.dart';
import 'voice_record_block.dart';
import 'create_task_form.dart';

/// Диалог для голосового создания задачи
/// 
/// Имеет два этапа:
/// 1. Этап записи - показывает поп-ап с компактной анимацией (движущиеся палочки)
/// 2. Этап формы - показывает форму с предзаполненными данными из голосового сообщения
class VoiceTaskDialog extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final CreateTask createTaskUseCase;

  const VoiceTaskDialog({
    super.key,
    required this.businessId,
    required this.userRepository,
    required this.createTaskUseCase,
  });

  @override
  State<VoiceTaskDialog> createState() => _VoiceTaskDialogState();
}

class _VoiceTaskDialogState extends State<VoiceTaskDialog> {
  TaskModel? _initialTaskData;
  String? _error;
  List<ValidationError>? _validationErrors;
  bool _showForm = false; // Флаг для переключения между этапом записи и формой

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioRecordingService>(
      builder: (context, audioService, child) {
        // Если запись активна или еще не показана форма, показываем этап записи
        if (!_showForm && audioService.state != RecordingState.idle) {
          return _buildRecordingStage(context, audioService);
        }

        // Если форма должна быть показана, показываем форму
        if (_showForm) {
          return _buildFormStage(context);
        }

        // Начальное состояние - показываем этап записи с кнопкой старта
        return _buildRecordingStage(context, audioService);
      },
    );
  }

  /// Этап записи - поп-ап с компактной анимацией (движущиеся палочки)
  Widget _buildRecordingStage(
    BuildContext context,
    AudioRecordingService audioService,
  ) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Отменяем запись если она активна
        if (audioService.state != RecordingState.idle) {
          audioService.cancelRecording();
        }
        Navigator.of(context).pop();
      },
      child: Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок с кнопкой закрытия
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Создать задачу голосом',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // Отменяем запись если она активна
                      if (audioService.state != RecordingState.idle) {
                        audioService.cancelRecording();
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Блок голосовой записи с компактной анимацией
              VoiceRecordBlock(
                context: VoiceContext.task,
                onResultReceived: (result) {
                  // Результат - TaskModel для контекста task
                  final taskData = result as TaskModel;
                  setState(() {
                    _initialTaskData = taskData;
                    _showForm = true;
                  });
                },
                onError: (error) {
                  setState(() {
                    _error = error;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Этап формы - форма создания задачи с предзаполненными данными
  Widget _buildFormStage(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Создать задачу',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Форма
            Expanded(
              child: CreateTaskForm(
                businessId: widget.businessId,
                userRepository: widget.userRepository,
                initialTaskData: _initialTaskData,
                error: _error,
                validationErrors: _validationErrors,
                onError: (error) {
                  setState(() {
                    _error = error;
                  });
                },
                onSubmit: (task) async {
                  setState(() {
                    _error = null;
                    _validationErrors = null;
                  });

                  final result = await widget.createTaskUseCase.call(
                    CreateTaskParams(task: task),
                  );

                  result.fold(
                    (failure) {
                      // Обрабатываем ошибки валидации
                      if (failure is ValidationFailure) {
                        setState(() {
                          _error = failure.serverMessage ?? failure.message;
                          _validationErrors = failure.errors;
                        });
                      } else {
                        setState(() {
                          _error = _getErrorMessage(failure);
                          _validationErrors = null;
                        });
                      }
                    },
                    (createdTask) {
                      // Закрываем диалог и показываем успех
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Задача успешно создана'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  );
                },
                onCancel: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.serverMessage ?? failure.message;
    } else if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }
}

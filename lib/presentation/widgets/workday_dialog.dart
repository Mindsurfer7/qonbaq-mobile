import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/usecases/start_workday.dart';
import '../../domain/usecases/end_workday.dart';
import '../../domain/usecases/mark_absent.dart';
import '../../domain/entities/workday.dart';
import '../../core/services/local_notification_service.dart';
import '../providers/profile_provider.dart';

/// Диалог для работы с рабочим днем
class WorkDayDialog extends StatefulWidget {
  const WorkDayDialog({super.key});

  @override
  State<WorkDayDialog> createState() => _WorkDayDialogState();
}

class _WorkDayDialogState extends State<WorkDayDialog> {
  String? _selectedReason;
  bool _isLoading = false;
  String? _error;
  WorkDayAction? _selectedAction;

  // Опции для причины отсутствия
  static const List<String> _absenceReasons = [
    'Отпуск',
    'Больничный',
    'Без содержания',
  ];

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleAction(WorkDayAction action) async {
    if (_isLoading) return;

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;

    if (businessId == null) {
      setState(() {
        _error = 'Компания не выбрана';
      });
      return;
    }

    // Если выбрано отсутствие, проверяем наличие причины
    if (action == WorkDayAction.absent) {
      if (_selectedReason == null || _selectedReason!.isEmpty) {
        setState(() {
          _error = 'Выберите причину отсутствия';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _selectedAction = action;
    });

    try {
      switch (action) {
        case WorkDayAction.start:
          final startWorkDay = Provider.of<StartWorkDay>(context, listen: false);
          final result = await startWorkDay.call(
            StartWorkDayParams(businessId: businessId),
          );
          result.fold(
            (failure) {
              setState(() {
                _error = failure.message;
                _isLoading = false;
              });
            },
            (workDay) async {
              // Обновляем профиль, чтобы получить актуальный workDay
              final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
              await profileProvider.loadProfile();
              
              // Показываем локальное уведомление
              final startTimeStr = _formatTime(workDay.startTime);
              await LocalNotificationService().showWorkDayStartedNotification(
                startTime: startTimeStr,
              );
              
              // Закрываем диалог и сразу переходим на страницу задач
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/tasks');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Рабочий день начат в $startTimeStr',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          );
          break;
        case WorkDayAction.end:
          final endWorkDay = Provider.of<EndWorkDay>(context, listen: false);
          final result = await endWorkDay.call(
            EndWorkDayParams(businessId: businessId),
          );
          result.fold(
            (failure) {
              setState(() {
                _error = failure.message;
                _isLoading = false;
              });
            },
            (workDay) async {
              // Обновляем профиль, чтобы получить актуальный workDay
              final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
              await profileProvider.loadProfile();
              
              // Показываем локальное уведомление
              final endTimeStr = _formatTime(workDay.endTime);
              await LocalNotificationService().showWorkDayEndedNotification(
                endTime: endTimeStr,
              );
              
              Navigator.of(context).pop(true);
              
              // Навигация на страницу табелирования
              if (context.mounted) {
                Navigator.of(context).pushNamed('/business/admin/timesheet');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Рабочий день завершен в $endTimeStr',
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
          );
          break;
        case WorkDayAction.absent:
          final markAbsent = Provider.of<MarkAbsent>(context, listen: false);
          final result = await markAbsent.call(
            MarkAbsentParams(
              businessId: businessId,
              reason: _selectedReason!,
            ),
          );
          result.fold(
            (failure) {
              setState(() {
                _error = failure.message;
                _isLoading = false;
              });
            },
            (workDay) {
              Navigator.of(context).pop(true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Отсутствие отмечено'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          );
          break;
      }
    } catch (e) {
      setState(() {
        _error = 'Произошла ошибка: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final workDay = profileProvider.profile?.workDay;
    final isStarted = workDay?.status == WorkDayStatus.started;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Рабочий день',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Показываем кнопку "Начать рабочий день" только если день не начат
            if (!isStarted) ...[
              _buildActionButton(
                context,
                'Начать рабочий день',
                Icons.play_arrow,
                Colors.green,
                WorkDayAction.start,
              ),
              const SizedBox(height: 12),
            ],
            // Показываем кнопку "Завершить рабочий день" только если день начат
            if (isStarted) ...[
              _buildActionButton(
                context,
                'Завершить рабочий день',
                Icons.stop,
                Colors.red,
                WorkDayAction.end,
              ),
              const SizedBox(height: 12),
            ],
            _buildActionButton(
              context,
              'Отсутствую по причине',
              Icons.cancel,
              Colors.orange,
              WorkDayAction.absent,
            ),
            if (_selectedAction == WorkDayAction.absent) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Причина отсутствия',
                  border: OutlineInputBorder(),
                ),
                items: _absenceReasons.map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedReason = value;
                          _error = null;
                        });
                      },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _handleAction(WorkDayAction.absent),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Подтвердить отсутствие'),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    WorkDayAction action,
  ) {
    final isDisabled = _isLoading && _selectedAction != action;

    return ElevatedButton.icon(
      onPressed: isDisabled
          ? null
          : () {
              if (action == WorkDayAction.absent) {
                setState(() {
                  _selectedAction = action;
                  _selectedReason = null;
                  _error = null;
                });
              } else {
                _handleAction(action);
              }
            },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Действия для рабочего дня
enum WorkDayAction {
  start,
  end,
  absent,
}


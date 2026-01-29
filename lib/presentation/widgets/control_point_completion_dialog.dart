import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';

/// Диалог для заполнения метрик точки контроля при завершении задачи
class ControlPointCompletionDialog extends StatefulWidget {
  final String taskTitle;
  final List<TaskIndicator> indicators;

  const ControlPointCompletionDialog({
    super.key,
    required this.taskTitle,
    required this.indicators,
  });

  @override
  State<ControlPointCompletionDialog> createState() =>
      _ControlPointCompletionDialogState();
}

class _ControlPointCompletionDialogState
    extends State<ControlPointCompletionDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double?> _values = {};

  @override
  void initState() {
    super.initState();
    // Создаем контроллеры для каждой метрики
    for (final indicator in widget.indicators) {
      _controllers[indicator.id] = TextEditingController(
        text: indicator.actualValue?.toString() ?? '',
      );
      _values[indicator.id] = indicator.actualValue;
    }
  }

  @override
  void dispose() {
    // Освобождаем контроллеры
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getUnitText(String? unit) {
    if (unit == null) return '';
    switch (unit.toUpperCase()) {
      case 'KILOGRAM':
        return 'кг';
      case 'GRAM':
        return 'г';
      case 'TON':
        return 'т';
      case 'METER':
        return 'м';
      case 'KILOMETER':
        return 'км';
      case 'HOUR':
        return 'ч';
      case 'MINUTE':
        return 'мин';
      case 'PIECE':
        return 'шт';
      case 'LITER':
        return 'л';
      default:
        return unit; // Кастомная единица
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Проверяем, что все метрики заполнены
    for (final indicator in widget.indicators) {
      if (_values[indicator.id] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заполните значение для метрики "${indicator.name}"'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Формируем результат с обновленными метриками
    final updatedIndicators = widget.indicators.map((indicator) {
      return TaskIndicator(
        id: indicator.id,
        taskId: indicator.taskId,
        name: indicator.name,
        targetValue: indicator.targetValue,
        actualValue: _values[indicator.id],
        unit: indicator.unit,
        createdAt: indicator.createdAt,
        updatedAt: DateTime.now(),
      );
    }).toList();

    // Возвращаем результат
    Navigator.of(context).pop({
      'indicators': updatedIndicators,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Завершить точку контроля'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.taskTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Заполните фактические значения метрик',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 24),
                      ...widget.indicators.map((indicator) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      indicator.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (indicator.targetValue != null)
                                    Text(
                                      'Цель: ${indicator.targetValue} ${_getUnitText(indicator.unit)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _controllers[indicator.id],
                                decoration: InputDecoration(
                                  labelText: 'Фактическое значение *',
                                  hintText: 'Введите значение',
                                  suffixText: _getUnitText(indicator.unit),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Введите значение';
                                  }
                                  final numValue = double.tryParse(value);
                                  if (numValue == null) {
                                    return 'Введите корректное число';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  final numValue = double.tryParse(value);
                                  setState(() {
                                    _values[indicator.id] = numValue;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    child: const Text('Завершить'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/invite.dart';
import '../../domain/entities/employment_enums.dart';

/// Виджет формы для заполнения данных трудоустройства
class EmploymentFormWidget extends StatefulWidget {
  /// Endpoint для обновления employment
  /// Если null, используется /api/employments/me
  /// Если указан, используется /api/employments/{employmentId}
  final String? endpoint;
  
  /// Тип invite кода (для определения обязательности поля roleCode)
  final InviteType? inviteType;
  
  /// Начальные значения полей
  final String? initialWorkPhone;
  final String? initialRoleCode;
  
  /// Callback при успешном сохранении
  final ValueChanged<Map<String, dynamic>>? onSaved;
  
  /// Callback для выполнения запроса (должен быть передан извне)
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> data)? onSave;

  const EmploymentFormWidget({
    super.key,
    this.endpoint,
    this.inviteType,
    this.initialWorkPhone,
    this.initialRoleCode,
    this.onSaved,
    this.onSave,
  });

  @override
  State<EmploymentFormWidget> createState() => _EmploymentFormWidgetState();
}

class _EmploymentFormWidgetState extends State<EmploymentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _workPhoneController = TextEditingController();
  
  String? _selectedRoleCode;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _workPhoneController.text = widget.initialWorkPhone ?? '';
    _selectedRoleCode = widget.initialRoleCode;
  }

  @override
  void dispose() {
    _workPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.onSave == null) {
      setState(() {
        _error = 'Функция сохранения не указана';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final data = <String, dynamic>{};
    if (_selectedRoleCode != null && _selectedRoleCode!.isNotEmpty) {
      data['roleCode'] = _selectedRoleCode;
    }
    if (_workPhoneController.text.isNotEmpty) {
      data['workPhone'] = _workPhoneController.text.trim();
    }

    try {
      final result = await widget.onSave!(data);
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
        widget.onSaved?.call(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные успешно сохранены'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Ошибка при сохранении данных';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusiness = widget.inviteType == InviteType.business;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Поле roleCode (обязательно для business)
            if (isBusiness) ...[
              DropdownButtonFormField<String>(
                value: _selectedRoleCode,
                decoration: const InputDecoration(
                  labelText: 'Должность *',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Обязательное поле для бизнеса',
                ),
                isExpanded: true,
                items: RoleCode.values.map((role) {
                  return DropdownMenuItem<String>(
                    value: role.code,
                    child: Text(role.nameRu, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoleCode = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите должность';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Поле workPhone
            TextFormField(
              controller: _workPhoneController,
              decoration: const InputDecoration(
                labelText: 'Рабочий телефон',
                hintText: '+7 999 123 45 67',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            
            // Ошибка
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Кнопка сохранения
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/invite.dart';

/// Виджет формы для заполнения данных трудоустройства
class EmploymentFormWidget extends StatefulWidget {
  /// Endpoint для обновления employment
  /// Если null, используется /api/employments/me
  /// Если указан, используется /api/employments/{employmentId}
  final String? endpoint;
  
  /// Тип invite кода (для определения лейбла поля position)
  final InviteType? inviteType;
  
  /// Начальные значения полей
  final String? initialPosition;
  final String? initialPositionType;
  final String? initialOrgPosition;
  final String? initialWorkPhone;
  final int? initialWorkExperience;
  final String? initialAccountability;
  final String? initialPersonnelNumber;
  final DateTime? initialHireDate;
  final String? initialRoleCode;
  
  /// Callback при успешном сохранении
  final ValueChanged<Map<String, dynamic>>? onSaved;
  
  /// Callback для выполнения запроса (должен быть передан извне)
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> data)? onSave;

  const EmploymentFormWidget({
    super.key,
    this.endpoint,
    this.inviteType,
    this.initialPosition,
    this.initialPositionType,
    this.initialOrgPosition,
    this.initialWorkPhone,
    this.initialWorkExperience,
    this.initialAccountability,
    this.initialPersonnelNumber,
    this.initialHireDate,
    this.initialRoleCode,
    this.onSaved,
    this.onSave,
  });

  @override
  State<EmploymentFormWidget> createState() => _EmploymentFormWidgetState();
}

class _EmploymentFormWidgetState extends State<EmploymentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _positionController = TextEditingController();
  final _positionTypeController = TextEditingController();
  final _orgPositionController = TextEditingController();
  final _workPhoneController = TextEditingController();
  // final _workExperienceController = TextEditingController();
  // final _accountabilityController = TextEditingController();
  // final _personnelNumberController = TextEditingController();
  
  String? _selectedRoleCode;
  // DateTime? _hireDate;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _positionController.text = widget.initialPosition ?? '';
    _positionTypeController.text = widget.initialPositionType ?? '';
    _orgPositionController.text = widget.initialOrgPosition ?? '';
    _workPhoneController.text = widget.initialWorkPhone ?? '';
    // _workExperienceController.text = widget.initialWorkExperience?.toString() ?? '';
    // _accountabilityController.text = widget.initialAccountability ?? '';
    // _personnelNumberController.text = widget.initialPersonnelNumber ?? '';
    _selectedRoleCode = widget.initialRoleCode;
    // _hireDate = widget.initialHireDate;
  }

  @override
  void dispose() {
    _positionController.dispose();
    _positionTypeController.dispose();
    _orgPositionController.dispose();
    _workPhoneController.dispose();
    // _workExperienceController.dispose();
    // _accountabilityController.dispose();
    // _personnelNumberController.dispose();
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
    if (_positionController.text.isNotEmpty) {
      data['position'] = _positionController.text.trim();
    }
    if (_positionTypeController.text.isNotEmpty) {
      data['positionType'] = _positionTypeController.text.trim();
    }
    if (_orgPositionController.text.isNotEmpty) {
      data['orgPosition'] = _orgPositionController.text.trim();
    }
    if (_workPhoneController.text.isNotEmpty) {
      data['workPhone'] = _workPhoneController.text.trim();
    }
    // if (_workExperienceController.text.isNotEmpty) {
    //   final experience = int.tryParse(_workExperienceController.text);
    //   if (experience != null) {
    //     data['workExperience'] = experience;
    //   }
    // }
    // if (_accountabilityController.text.isNotEmpty) {
    //   data['accountability'] = _accountabilityController.text.trim();
    // }
    // if (_personnelNumberController.text.isNotEmpty) {
    //   data['personnelNumber'] = _personnelNumberController.text.trim();
    // }
    // if (_hireDate != null) {
    //   data['hireDate'] = _hireDate!.toIso8601String();
    // }
    if (_selectedRoleCode != null && _selectedRoleCode!.isNotEmpty) {
      data['roleCode'] = _selectedRoleCode;
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

  // Future<void> _selectHireDate() async {
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: _hireDate ?? DateTime.now(),
  //     firstDate: DateTime(1900),
  //     lastDate: DateTime.now(),
  //   );
  //   if (picked != null) {
  //     setState(() {
  //       _hireDate = picked;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final isFamily = widget.inviteType == InviteType.family;
    final isBusiness = widget.inviteType == InviteType.business;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Поле position (должность или роль)
            TextFormField(
              controller: _positionController,
              decoration: InputDecoration(
                labelText: isFamily ? 'Роль' : 'Должность',
                hintText: isFamily ? 'Например: дочь, отец' : 'Например: Менеджер',
                prefixIcon: const Icon(Icons.work_outline),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            // Поле roleCode (обязательно для business)
            if (isBusiness) ...[
              DropdownButtonFormField<String>(
                value: _selectedRoleCode,
                decoration: const InputDecoration(
                  labelText: 'Код роли *',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Обязательное поле для бизнеса',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ACCOUNTANT',
                    child: Text('Бухгалтер'),
                  ),
                  DropdownMenuItem(
                    value: 'LAWYER',
                    child: Text('Юрист'),
                  ),
                  DropdownMenuItem(
                    value: 'SALES_MANAGER',
                    child: Text('Менеджер продаж'),
                  ),
                  DropdownMenuItem(
                    value: 'PURCHASE_MANAGER',
                    child: Text('Менеджер закупа'),
                  ),
                  DropdownMenuItem(
                    value: 'SECRETARY',
                    child: Text('Секретарь'),
                  ),
                  DropdownMenuItem(
                    value: 'MARKETER',
                    child: Text('Маркетолог'),
                  ),
                  DropdownMenuItem(
                    value: 'FINANCE_MANAGER',
                    child: Text('Менеджер по финансам'),
                  ),
                  DropdownMenuItem(
                    value: 'LOGISTICIAN',
                    child: Text('Логист'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRoleCode = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите роль';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Поле positionType
            TextFormField(
              controller: _positionTypeController,
              decoration: const InputDecoration(
                labelText: 'Тип должности',
                hintText: 'Например: Штатный',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            // Поле orgPosition
            TextFormField(
              controller: _orgPositionController,
              decoration: const InputDecoration(
                labelText: 'Организационная должность',
                hintText: 'Например: Должность работника',
                prefixIcon: Icon(Icons.business_center_outlined),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
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
            // // Поле workExperience
            // TextFormField(
            //   controller: _workExperienceController,
            //   decoration: const InputDecoration(
            //     labelText: 'Опыт работы (лет)',
            //     hintText: 'Например: 5',
            //     prefixIcon: Icon(Icons.calendar_today_outlined),
            //     border: OutlineInputBorder(),
            //   ),
            //   keyboardType: TextInputType.number,
            //   textInputAction: TextInputAction.next,
            //   validator: (value) {
            //     if (value != null && value.isNotEmpty) {
            //       final experience = int.tryParse(value);
            //       if (experience == null || experience < 0) {
            //         return 'Введите корректное число';
            //       }
            //     }
            //     return null;
            //   },
            // ),
            // const SizedBox(height: 16),
            // 
            // // Поле accountability
            // TextFormField(
            //   controller: _accountabilityController,
            //   decoration: const InputDecoration(
            //     labelText: 'Зона ответственности',
            //     hintText: 'Опишите зону ответственности',
            //     prefixIcon: Icon(Icons.assignment_outlined),
            //     border: OutlineInputBorder(),
            //   ),
            //   maxLines: 3,
            //   textInputAction: TextInputAction.next,
            // ),
            // const SizedBox(height: 16),
            // 
            // // Поле personnelNumber
            // TextFormField(
            //   controller: _personnelNumberController,
            //   decoration: const InputDecoration(
            //     labelText: 'Табельный номер',
            //     hintText: 'Например: 12345',
            //     prefixIcon: Icon(Icons.numbers_outlined),
            //     border: OutlineInputBorder(),
            //   ),
            //   textInputAction: TextInputAction.done,
            // ),
            // const SizedBox(height: 16),
            // 
            // // Поле hireDate
            // InkWell(
            //   onTap: _selectHireDate,
            //   child: InputDecorator(
            //     decoration: const InputDecoration(
            //       labelText: 'Дата приема на работу',
            //       prefixIcon: Icon(Icons.event_outlined),
            //       border: OutlineInputBorder(),
            //     ),
            //     child: Text(
            //       _hireDate != null
            //           ? '${_hireDate!.day}.${_hireDate!.month}.${_hireDate!.year}'
            //           : 'Выберите дату',
            //       style: TextStyle(
            //         color: _hireDate != null ? null : Colors.grey,
            //       ),
            //     ),
            //   ),
            // ),
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

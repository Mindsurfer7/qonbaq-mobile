import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/department.dart';
import '../providers/department_provider.dart';

/// Диалог для создания подразделения
class CreateDepartmentDialog extends StatefulWidget {
  final String businessId;
  final String? parentId; // ID родительского подразделения (для дочерних)
  final VoidCallback onDepartmentCreated;

  const CreateDepartmentDialog({
    super.key,
    required this.businessId,
    this.parentId,
    required this.onDepartmentCreated,
  });

  @override
  State<CreateDepartmentDialog> createState() => _CreateDepartmentDialogState();
}

class _CreateDepartmentDialogState extends State<CreateDepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedManagerId;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.parentId != null
            ? 'Создать дочернее подразделение'
            : 'Создать подразделение',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Название подразделения
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название подразделения *',
                  hintText: 'Введите название',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Название обязательно';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Введите описание (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              // Информация о родительском подразделении
              if (widget.parentId != null)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Будет создано дочернее подразделение',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Примечание о менеджере
              Text(
                'Назначение руководителя будет доступно после создания подразделения',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Отмена'),
        ),
        Consumer<DepartmentProvider>(
          builder: (context, provider, child) {
            return ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () => _createDepartment(provider),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Создать'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _createDepartment(DepartmentProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final department = Department(
      id: '', // Будет присвоен сервером
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      businessId: widget.businessId,
      parentId: widget.parentId, // ID родительского подразделения
      managerId: _selectedManagerId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await provider.createNewDepartment(department);

    if (!mounted) return;

    if (success) {
      context.pop();
      widget.onDepartmentCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Подразделение успешно создано'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'Ошибка при создании подразделения',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}


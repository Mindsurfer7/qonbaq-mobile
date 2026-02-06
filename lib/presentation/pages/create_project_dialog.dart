import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/project.dart';
import '../providers/project_provider.dart';

/// Диалог для создания проекта
class CreateProjectDialog extends StatefulWidget {
  final String businessId;
  final VoidCallback onProjectCreated;

  const CreateProjectDialog({
    super.key,
    required this.businessId,
    required this.onProjectCreated,
  });

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _workingHoursController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Создать проект'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Название проекта
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название проекта *',
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
              // Город
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Город',
                  hintText: 'Введите город (необязательно)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              // Страна
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Страна',
                  hintText: 'Введите страну (необязательно)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              // Адрес
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Адрес',
                  hintText: 'Введите адрес (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              // Телефон
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: 'Введите номер телефона (необязательно)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // Часы работы
              TextFormField(
                controller: _workingHoursController,
                decoration: const InputDecoration(
                  labelText: 'Часы работы',
                  hintText: 'Например: Пн-Пт 9:00-18:00 (необязательно)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
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
        Consumer<ProjectProvider>(
          builder: (context, provider, child) {
            return ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () => _createProject(provider),
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

  Future<void> _createProject(ProjectProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final project = Project(
      id: '', // Будет присвоен сервером
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      businessId: widget.businessId,
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      country: _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      workingHours: _workingHoursController.text.trim().isEmpty
          ? null
          : _workingHoursController.text.trim(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await provider.createNewProject(project);

    if (!mounted) return;

    if (success) {
      context.pop();
      widget.onProjectCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Проект успешно создан'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'Ошибка при создании проекта',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}




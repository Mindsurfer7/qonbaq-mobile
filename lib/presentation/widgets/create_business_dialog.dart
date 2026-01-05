import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/business.dart';
import '../providers/profile_provider.dart';
import '../../core/error/failures.dart';
import '../../data/models/validation_error.dart';

/// Диалог для создания бизнеса
class CreateBusinessDialog extends StatefulWidget {
  final BusinessType type;

  const CreateBusinessDialog({
    super.key,
    required this.type,
  });

  @override
  State<CreateBusinessDialog> createState() => _CreateBusinessDialogState();
}

class _CreateBusinessDialogState extends State<CreateBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<ValidationError>? _validationErrors;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _validationErrors = null;
    });

    final provider = Provider.of<ProfileProvider>(context, listen: false);

    // Создаем временный бизнес для отправки
    final business = Business(
      id: '', // Будет присвоен на сервере
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: widget.type,
    );

    final result = await provider.createBusinessCall(business);

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
          if (failure is ValidationFailure) {
            _validationErrors = failure.errors;
          }
        });
      },
      (createdBusiness) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          Navigator.of(context).pop(createdBusiness);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == BusinessType.family
        ? 'Создать семью'
        : 'Создать бизнес';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Название
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название *',
                  hintText: widget.type == BusinessType.family
                      ? 'Например: Моя семья'
                      : 'Например: Моя компания',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Название обязательно';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  hintText: widget.type == BusinessType.family
                      ? 'Семейный workspace'
                      : 'Описание бизнеса (необязательно)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                enabled: !_isLoading,
              ),
              // Ошибки валидации
              if (_validationErrors != null && _validationErrors!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _validationErrors!.map((error) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          error.message,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              // Общая ошибка
              if (_error != null) ...[
                const SizedBox(height: 16),
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
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Создать'),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/business.dart';
import '../providers/profile_provider.dart';
import '../../core/error/failures.dart';

/// Диалог для редактирования slug бизнеса
class EditBusinessSlugDialog extends StatefulWidget {
  final Business business;

  const EditBusinessSlugDialog({
    super.key,
    required this.business,
  });

  @override
  State<EditBusinessSlugDialog> createState() => _EditBusinessSlugDialogState();
}

class _EditBusinessSlugDialogState extends State<EditBusinessSlugDialog> {
  final _formKey = GlobalKey<FormState>();
  final _slugController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _slugController.text = widget.business.slug ?? '';
  }

  @override
  void dispose() {
    _slugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Внешняя ссылка для клиентов'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Персональная ссылка',
                  hintText: 'my-awesome-business',
                  border: OutlineInputBorder(),
                  helperText: 'Только буквы, цифры, дефисы и подчеркивания',
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final slug = value.trim();
                    // Проверяем формат: только буквы, цифры, дефисы и подчеркивания
                    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(slug)) {
                      return 'Используйте только буквы, цифры, дефисы и подчеркивания';
                    }
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveSlug(),
              ),
              const SizedBox(height: 8),
              Text(
                'Оставьте поле пустым, чтобы удалить ссылку',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => context.pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSlug,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _saveSlug() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final slugValue = _slugController.text.trim();
    final slug = slugValue.isEmpty ? null : slugValue;

    final updatedBusiness = Business(
      id: widget.business.id,
      name: widget.business.name,
      description: widget.business.description,
      position: widget.business.position,
      orgPosition: widget.business.orgPosition,
      department: widget.business.department,
      hireDate: widget.business.hireDate,
      createdAt: widget.business.createdAt,
      type: widget.business.type,
      autoAssignDepartments: widget.business.autoAssignDepartments,
      slug: slug,
    );

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final result = await profileProvider.updateBusinessCall(
      widget.business.id,
      updatedBusiness,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    result.fold(
      (failure) {
        String errorMessage;
        if (failure is ServerFailure) {
          errorMessage = failure.message;
        } else if (failure is ValidationFailure) {
          errorMessage = failure.message;
        } else {
          errorMessage = 'Ошибка при обновлении ссылки';
        }
        setState(() {
          _error = errorMessage;
        });
      },
      (updated) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              slug == null
                  ? 'Ссылка удалена'
                  : 'Ссылка успешно обновлена',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

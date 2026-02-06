import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/resource.dart';
import '../../domain/usecases/create_resource.dart';
import '../../domain/repositories/resource_repository.dart';
import '../../core/error/failures.dart';

/// Диалог для создания ресурса
class CreateResourceDialog extends StatefulWidget {
  final String businessId;

  const CreateResourceDialog({
    super.key,
    required this.businessId,
  });

  @override
  State<CreateResourceDialog> createState() => _CreateResourceDialogState();
}

class _CreateResourceDialogState extends State<CreateResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final resource = Resource(
      id: '', // Будет присвоен на сервере
      businessId: widget.businessId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final resourceRepository = Provider.of<ResourceRepository>(context, listen: false);
    final createResource = CreateResource(resourceRepository);
    final result = await createResource.call(
      CreateResourceParams(
        businessId: widget.businessId,
        resource: resource,
      ),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
      },
      (createdResource) {
        Navigator.of(context).pop(createdResource);
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.serverMessage ?? failure.message;
    } else if (failure is ServerFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  @override
  Widget build(BuildContext context) {
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
                    'Создать ресурс',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            // Форма
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название ресурса *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Название обязательно';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Кнопки
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => context.pop(),
                            child: const Text('Отмена'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Создать'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


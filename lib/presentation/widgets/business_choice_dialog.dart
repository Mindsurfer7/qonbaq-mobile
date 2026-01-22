import 'package:flutter/material.dart';
import '../../domain/entities/business.dart';
import 'create_business_dialog.dart';

/// Диалог выбора бизнеса: войти в существующий или создать новый
class BusinessChoiceDialog extends StatelessWidget {
  final List<Business> businesses;

  const BusinessChoiceDialog({
    super.key,
    required this.businesses,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите бизнес'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Список существующих бизнесов
            if (businesses.isNotEmpty) ...[
              const Text(
                'Войти в существующий бизнес:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: businesses.length,
                  itemBuilder: (context, index) {
                    final business = businesses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          business.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: business.description != null
                            ? Text(
                                business.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.of(context).pop(business);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            // Кнопка создания нового бизнеса
            OutlinedButton.icon(
              onPressed: () async {
                // Закрываем текущий диалог
                Navigator.of(context).pop();
                
                // Показываем диалог создания бизнеса
                final result = await showDialog<Business>(
                  context: context,
                  builder: (context) => const CreateBusinessDialog(
                    type: BusinessType.business,
                  ),
                );
                
                // Возвращаем созданный бизнес
                if (result != null && context.mounted) {
                  Navigator.of(context).pop(result);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Создать новый бизнес'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}

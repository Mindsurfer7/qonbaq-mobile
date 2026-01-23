import 'package:flutter/material.dart';
import '../../domain/entities/customer.dart';

/// Мини-карточка клиента для отображения в воронке продаж
class CustomerMiniCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;

  const CustomerMiniCard({
    super.key,
    required this.customer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Определяем название клиента
    final displayName = customer.displayName ?? 
                       customer.name ?? 
                       (customer.customerType == CustomerType.individual
                           ? _getIndividualName()
                           : 'Без названия');
    
    // Иконка в зависимости от типа клиента
    final icon = customer.customerType == CustomerType.individual
        ? Icons.person
        : Icons.business;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Иконка типа клиента
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Название клиента
              Expanded(
                child: Text(
                  displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Стрелка для навигации
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Получить имя физического лица
  String _getIndividualName() {
    final parts = <String>[];
    if (customer.lastName != null && customer.lastName!.isNotEmpty) {
      parts.add(customer.lastName!);
    }
    if (customer.firstName != null && customer.firstName!.isNotEmpty) {
      parts.add(customer.firstName!);
    }
    if (customer.patronymic != null && customer.patronymic!.isNotEmpty) {
      parts.add(customer.patronymic!);
    }
    return parts.isEmpty ? 'Без названия' : parts.join(' ');
  }
}

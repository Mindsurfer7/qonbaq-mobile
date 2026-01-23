import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/order.dart';

/// Мини-карточка заказа для отображения в воронке заказов
class OrderMiniCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderMiniCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Определяем название заказа
    final displayName = order.orderNumber ?? 
                       order.description ?? 
                       'Заказ #${order.id.substring(0, 8)}';
    
    // Информация о клиенте
    final customerName = order.customer?.displayName ?? 
                        order.customer?.name ?? 
                        'Клиент не указан';
    
    // Информация об оплате
    final paymentInfo = _getPaymentInfo();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Иконка заказа
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Название заказа
                  Expanded(
                    child: Text(
                      displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
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
              const SizedBox(height: 8),
              // Клиент
              Text(
                customerName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Информация об оплате
              Row(
                children: [
                  Text(
                    paymentInfo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getPaymentColor(theme),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Иконка статуса оплаты
                  if (order.isPaid)
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    )
                  else if (order.isPartiallyPaid)
                    Icon(
                      Icons.pending,
                      size: 16,
                      color: Colors.orange,
                    )
                  else if (order.isOverdue)
                    Icon(
                      Icons.error,
                      size: 16,
                      color: Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Получить информацию об оплате
  String _getPaymentInfo() {
    final formatter = NumberFormat('#,##0', 'ru_RU');
    final totalFormatted = formatter.format(order.totalAmount);
    final paidFormatted = formatter.format(order.paidAmount);
    
    if (order.isPaid) {
      return 'Оплачено: $totalFormatted ₸';
    } else if (order.isPartiallyPaid) {
      return 'Частично: $paidFormatted / $totalFormatted ₸';
    } else if (order.isOverdue) {
      return 'Просрочено: $totalFormatted ₸';
    } else {
      return 'К оплате: $totalFormatted ₸';
    }
  }

  /// Получить цвет для статуса оплаты
  Color _getPaymentColor(ThemeData theme) {
    if (order.isPaid) {
      return Colors.green;
    } else if (order.isPartiallyPaid) {
      return Colors.orange;
    } else if (order.isOverdue) {
      return Colors.red;
    } else {
      return theme.colorScheme.onSurface.withOpacity(0.7);
    }
  }
}

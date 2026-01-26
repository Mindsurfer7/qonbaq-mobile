import 'package:flutter/material.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/order.dart';
import 'customer_mini_card.dart';
import 'order_mini_card.dart';

/// Тип карточки в аккордеоне
enum FunnelCardType {
  customer,
  order,
}

/// Универсальный аккордеон для отображения элементов по статусу воронки
class FunnelAccordion extends StatefulWidget {
  final FunnelCardType cardType;
  final String title;
  final int? currentCount;
  final int? totalCount;
  final bool isExpanded;
  
  // Для клиентов
  final SalesFunnelStage? salesFunnelStage;
  final List<Customer>? customers;
  final bool? isLoadingCustomers;
  final String? customerError;
  final VoidCallback? onLoadCustomers;
  final VoidCallback? onRetryCustomers;
  
  // Для заказов
  final OrderFunnelStage? orderFunnelStage;
  final List<Order>? orders;
  final bool? isLoadingOrders;
  final String? orderError;
  final VoidCallback? onLoadOrders;
  final VoidCallback? onRetryOrders;
  
  // Callback для нажатия на карточку
  final Function(String id)? onCardTap;

  const FunnelAccordion({
    super.key,
    required this.cardType,
    required this.title,
    this.currentCount,
    this.totalCount,
    this.isExpanded = false,
    this.salesFunnelStage,
    this.customers,
    this.isLoadingCustomers,
    this.customerError,
    this.onLoadCustomers,
    this.onRetryCustomers,
    this.orderFunnelStage,
    this.orders,
    this.isLoadingOrders,
    this.orderError,
    this.onLoadOrders,
    this.onRetryOrders,
    this.onCardTap,
  });

  @override
  State<FunnelAccordion> createState() => _FunnelAccordionState();
}

class _FunnelAccordionState extends State<FunnelAccordion> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Определяем счетчик в зависимости от типа карточки
    final displayCount = widget.currentCount ?? 
        (widget.cardType == FunnelCardType.customer 
            ? (widget.customers?.length ?? 0)
            : (widget.orders?.length ?? 0));
    final displayTotal = widget.totalCount;
    
    final isLoading = widget.cardType == FunnelCardType.customer
        ? (widget.isLoadingCustomers ?? false)
        : (widget.isLoadingOrders ?? false);
    
    final error = widget.cardType == FunnelCardType.customer
        ? widget.customerError
        : widget.orderError;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Заголовок аккордеона
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              // Данные уже загружены на рут-странице CRM, не делаем запросы при открытии
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Номер и название
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (displayTotal != null)
                          Text(
                            '$displayCount/$displayTotal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          )
                        else if (displayCount > 0)
                          Text(
                            '$displayCount',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Иконка раскрытия
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          // Контент аккордеона
          if (_isExpanded)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 400, // Максимальная высота для скролла
                ),
                child: _buildContent(isLoading, error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isLoading, String? error) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      // Улучшаем отображение ошибки: убираем длинные JSON и технические детали
      String displayError = error;
      
      // Если ошибка содержит FormatException с большим JSON, упрощаем сообщение
      if (displayError.contains('FormatException') && displayError.contains('data=')) {
        // Извлекаем только основное сообщение об ошибке
        final match = RegExp(r'FormatException: ([^;]+)').firstMatch(displayError);
        if (match != null) {
          displayError = 'Ошибка парсинга данных: ${match.group(1)}';
        } else {
          displayError = 'Ошибка при обработке данных';
        }
      } else if (displayError.contains('TypeError')) {
        // Упрощаем сообщения TypeError
        displayError = 'Ошибка типа данных при обработке ответа сервера';
      } else if (displayError.length > 200) {
        // Обрезаем слишком длинные сообщения
        displayError = '${displayError.substring(0, 200)}...';
      }
      
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ошибка при получении заказов:',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayError,
              style: const TextStyle(color: Colors.red),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                if (widget.cardType == FunnelCardType.customer) {
                  widget.onRetryCustomers?.call();
                } else {
                  widget.onRetryOrders?.call();
                }
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (widget.cardType == FunnelCardType.customer) {
      final customers = widget.customers ?? [];
      if (customers.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('Нет клиентов'),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return CustomerMiniCard(
            customer: customer,
            onTap: () => widget.onCardTap?.call(customer.id),
          );
        },
      );
    } else {
      final orders = widget.orders ?? [];
      if (orders.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('Нет заказов'),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderMiniCard(
            order: order,
            onTap: () => widget.onCardTap?.call(order.id),
          );
        },
      );
    }
  }
}

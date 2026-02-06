import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/order.dart';
import '../providers/crm_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/funnel_accordion.dart';
import '../widgets/create_order_dialog.dart';

/// Страница воронки заказов
class OrdersFunnelPage extends StatefulWidget {
  const OrdersFunnelPage({super.key});

  @override
  State<OrdersFunnelPage> createState() => _OrdersFunnelPageState();
}

class _OrdersFunnelPageState extends State<OrdersFunnelPage> {
  // Данные уже загружены на рут-странице CRM (crm_page.dart)
  // Не делаем запросы при открытии страницы

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Воронка заказов'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CreateOrderDialog(
                  initialStage: OrderFunnelStage.orderAccepted,
                ),
              );
            },
            tooltip: 'Добавить заказ',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (businessId != null) {
                final crmProvider = Provider.of<CrmProvider>(context, listen: false);
                crmProvider.refreshAllOrders(businessId);
              }
            },
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go('/business');
            },
          ),
        ],
      ),
      body: businessId == null
          ? const Center(
              child: Text('Выберите бизнес для просмотра воронки заказов'),
            )
          : RefreshIndicator(
              onRefresh: () async {
                final crmProvider = Provider.of<CrmProvider>(context, listen: false);
                await crmProvider.refreshAllOrders(businessId);
              },
              child: Consumer<CrmProvider>(
                builder: (context, crmProvider, child) {
                  if (crmProvider.isLoadingOrdersStage(OrderFunnelStage.orderAccepted) && 
                      crmProvider.getOrdersByStage(OrderFunnelStage.orderAccepted).isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Заказ принят
                      FunnelAccordion(
                        cardType: FunnelCardType.order,
                        orderFunnelStage: OrderFunnelStage.orderAccepted,
                        title: 'Заказ принят',
                        isExpanded: true, // Первая открыта по умолчанию
                        orders: List<Order>.from(crmProvider.getOrdersByStage(OrderFunnelStage.orderAccepted)),
                        isLoadingOrders: crmProvider.isLoadingOrdersStage(OrderFunnelStage.orderAccepted),
                        orderError: crmProvider.getErrorForOrdersStage(OrderFunnelStage.orderAccepted),
                        onRetryOrders: () {
                          crmProvider.refreshOrdersStage(businessId, OrderFunnelStage.orderAccepted);
                        },
                        onCardTap: (id) {
                          // TODO: Навигация на карточку заказа
                          // context.go(
                          //   '/business/operational/crm/orders/$id',
                          // );
                        },
                      ),
                      // Заказ начат
                      FunnelAccordion(
                        cardType: FunnelCardType.order,
                        orderFunnelStage: OrderFunnelStage.orderStarted,
                        title: 'Заказ начат',
                        orders: List<Order>.from(crmProvider.getOrdersByStage(OrderFunnelStage.orderStarted)),
                        isLoadingOrders: crmProvider.isLoadingOrdersStage(OrderFunnelStage.orderStarted),
                        orderError: crmProvider.getErrorForOrdersStage(OrderFunnelStage.orderStarted),
                        onRetryOrders: () {
                          crmProvider.refreshOrdersStage(businessId, OrderFunnelStage.orderStarted);
                        },
                        onCardTap: (id) {
                          // TODO: Навигация на карточку заказа
                        },
                      ),
                      // Заказ в работе
                      FunnelAccordion(
                        cardType: FunnelCardType.order,
                        orderFunnelStage: OrderFunnelStage.orderInProgress,
                        title: 'Заказ в работе',
                        orders: List<Order>.from(crmProvider.getOrdersByStage(OrderFunnelStage.orderInProgress)),
                        isLoadingOrders: crmProvider.isLoadingOrdersStage(OrderFunnelStage.orderInProgress),
                        orderError: crmProvider.getErrorForOrdersStage(OrderFunnelStage.orderInProgress),
                        onRetryOrders: () {
                          crmProvider.refreshOrdersStage(businessId, OrderFunnelStage.orderInProgress);
                        },
                        onCardTap: (id) {
                          // TODO: Навигация на карточку заказа
                        },
                      ),
                      // Заказ готов
                      FunnelAccordion(
                        cardType: FunnelCardType.order,
                        orderFunnelStage: OrderFunnelStage.orderReady,
                        title: 'Заказ готов',
                        orders: List<Order>.from(crmProvider.getOrdersByStage(OrderFunnelStage.orderReady)),
                        isLoadingOrders: crmProvider.isLoadingOrdersStage(OrderFunnelStage.orderReady),
                        orderError: crmProvider.getErrorForOrdersStage(OrderFunnelStage.orderReady),
                        onRetryOrders: () {
                          crmProvider.refreshOrdersStage(businessId, OrderFunnelStage.orderReady);
                        },
                        onCardTap: (id) {
                          // TODO: Навигация на карточку заказа
                        },
                      ),
                      // Заказ передан клиенту
                      FunnelAccordion(
                        cardType: FunnelCardType.order,
                        orderFunnelStage: OrderFunnelStage.orderDelivered,
                        title: 'Заказ передан клиенту',
                        orders: List<Order>.from(crmProvider.getOrdersByStage(OrderFunnelStage.orderDelivered)),
                        isLoadingOrders: crmProvider.isLoadingOrdersStage(OrderFunnelStage.orderDelivered),
                        orderError: crmProvider.getErrorForOrdersStage(OrderFunnelStage.orderDelivered),
                        onRetryOrders: () {
                          crmProvider.refreshOrdersStage(businessId, OrderFunnelStage.orderDelivered);
                        },
                        onCardTap: (id) {
                          // TODO: Навигация на карточку заказа
                        },
                      ),
                      // Возврат по причине
                      FunnelAccordion(
                        cardType: FunnelCardType.order,
                        orderFunnelStage: OrderFunnelStage.orderReturned,
                        title: 'Возврат по причине',
                        orders: List<Order>.from(crmProvider.getOrdersByStage(OrderFunnelStage.orderReturned)),
                        isLoadingOrders: crmProvider.isLoadingOrdersStage(OrderFunnelStage.orderReturned),
                        orderError: crmProvider.getErrorForOrdersStage(OrderFunnelStage.orderReturned),
                        onRetryOrders: () {
                          crmProvider.refreshOrdersStage(businessId, OrderFunnelStage.orderReturned);
                        },
                        onCardTap: (id) {
                          // TODO: Навигация на карточку заказа
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

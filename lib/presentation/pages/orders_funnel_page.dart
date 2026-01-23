import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    
    final businessId = profileProvider.selectedBusiness?.id;
    if (businessId != null) {
      ordersProvider.loadAllOrders(businessId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Воронка заказов'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
                final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
                ordersProvider.refreshAll(businessId);
              }
            },
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/business');
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
                final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
                await ordersProvider.refreshAll(businessId);
              },
              child: Consumer<OrdersProvider>(
                builder: (context, ordersProvider, child) {
                  if (ordersProvider.isLoading && 
                      ordersProvider.getOrdersByStage(OrderFunnelStage.orderAccepted).isEmpty) {
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
                        orders: ordersProvider.getOrdersByStage(OrderFunnelStage.orderAccepted),
                        isLoadingOrders: ordersProvider.isLoadingStage(OrderFunnelStage.orderAccepted),
                        orderError: ordersProvider.getErrorForStage(OrderFunnelStage.orderAccepted),
                        onLoadOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderAccepted);
                        },
                        onRetryOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderAccepted);
                        },
                        onCardTap: (id) {
                          // TODO: Навигация на карточку заказа
                          // Navigator.of(context).pushNamed(
                          //   '/business/operational/crm/orders/$id',
                          // );
                        },
                      ),
                      // Заказ начат
                      FunnelAccordion(
                        cardType: FunnelCardType.order,
                        orderFunnelStage: OrderFunnelStage.orderStarted,
                        title: 'Заказ начат',
                        orders: ordersProvider.getOrdersByStage(OrderFunnelStage.orderStarted),
                        isLoadingOrders: ordersProvider.isLoadingStage(OrderFunnelStage.orderStarted),
                        orderError: ordersProvider.getErrorForStage(OrderFunnelStage.orderStarted),
                        onLoadOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderStarted);
                        },
                        onRetryOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderStarted);
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
                        orders: ordersProvider.getOrdersByStage(OrderFunnelStage.orderInProgress),
                        isLoadingOrders: ordersProvider.isLoadingStage(OrderFunnelStage.orderInProgress),
                        orderError: ordersProvider.getErrorForStage(OrderFunnelStage.orderInProgress),
                        onLoadOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderInProgress);
                        },
                        onRetryOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderInProgress);
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
                        orders: ordersProvider.getOrdersByStage(OrderFunnelStage.orderReady),
                        isLoadingOrders: ordersProvider.isLoadingStage(OrderFunnelStage.orderReady),
                        orderError: ordersProvider.getErrorForStage(OrderFunnelStage.orderReady),
                        onLoadOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderReady);
                        },
                        onRetryOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderReady);
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
                        orders: ordersProvider.getOrdersByStage(OrderFunnelStage.orderDelivered),
                        isLoadingOrders: ordersProvider.isLoadingStage(OrderFunnelStage.orderDelivered),
                        orderError: ordersProvider.getErrorForStage(OrderFunnelStage.orderDelivered),
                        onLoadOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderDelivered);
                        },
                        onRetryOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderDelivered);
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
                        orders: ordersProvider.getOrdersByStage(OrderFunnelStage.orderReturned),
                        isLoadingOrders: ordersProvider.isLoadingStage(OrderFunnelStage.orderReturned),
                        orderError: ordersProvider.getErrorForStage(OrderFunnelStage.orderReturned),
                        onLoadOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderReturned);
                        },
                        onRetryOrders: () {
                          ordersProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderReturned);
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

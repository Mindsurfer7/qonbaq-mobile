import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final crmProvider = Provider.of<CrmProvider>(context, listen: false);
    
    final businessId = profileProvider.selectedBusiness?.id;
    if (businessId != null) {
      crmProvider.loadAllOrders(businessId);
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
                final crmProvider = Provider.of<CrmProvider>(context, listen: false);
                crmProvider.refreshAllOrders(businessId);
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
                        onLoadOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderAccepted);
                        },
                        onRetryOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderAccepted);
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
                        orders: List<Order>.from(crmProvider.getOrdersByStage(OrderFunnelStage.orderStarted)),
                        isLoadingOrders: crmProvider.isLoadingOrdersStage(OrderFunnelStage.orderStarted),
                        orderError: crmProvider.getErrorForOrdersStage(OrderFunnelStage.orderStarted),
                        onLoadOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderStarted);
                        },
                        onRetryOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderStarted);
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
                        onLoadOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderInProgress);
                        },
                        onRetryOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderInProgress);
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
                        onLoadOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderReady);
                        },
                        onRetryOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderReady);
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
                        onLoadOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderDelivered);
                        },
                        onRetryOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderDelivered);
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
                        onLoadOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderReturned);
                        },
                        onRetryOrders: () {
                          crmProvider.loadOrdersForStage(businessId, OrderFunnelStage.orderReturned);
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

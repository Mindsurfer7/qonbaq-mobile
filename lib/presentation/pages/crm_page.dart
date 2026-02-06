import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/order.dart';
import '../providers/crm_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/responsive_utils.dart';

/// Страница CRM
class CrmPage extends StatefulWidget {
  const CrmPage({super.key});

  @override
  State<CrmPage> createState() => _CrmPageState();
}

class _CrmPageState extends State<CrmPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCrmData();
    });
  }

  void _loadCrmData() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final crmProvider = Provider.of<CrmProvider>(context, listen: false);
    
    final businessId = profileProvider.selectedBusiness?.id;
    if (businessId != null) {
      final shouldShowAll = _shouldShowAll(authProvider, businessId);
      crmProvider.loadAllCrmData(businessId, showAll: shouldShowAll);
    }
  }

  /// Определяет, нужно ли передавать showAll=true
  /// showAll=true для гендиректора или РОПа (руководителя отдела продаж)
  bool? _shouldShowAll(AuthProvider authProvider, String businessId) {
    final user = authProvider.user;
    if (user == null) return null;

    // Проверяем, является ли пользователь гендиректором
    final permission = user.getPermissionsForBusiness(businessId);
    if (permission?.isGeneralDirector ?? false) {
      return true;
    }

    // Проверяем, является ли пользователь РОПом (руководителем отдела продаж)
    if (user.isSalesDepartmentHead(businessId)) {
      return true;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;

    return Scaffold(
      appBar: context.isDesktop ? null : AppBar(
        title: const Text('CRM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (businessId != null) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final crmProvider = Provider.of<CrmProvider>(context, listen: false);
                final shouldShowAll = _shouldShowAll(authProvider, businessId);
                crmProvider.refreshAllCrmData(businessId, showAll: shouldShowAll);
              }
            },
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/business'),
          ),
        ],
      ),
      body: businessId == null
          ? const Center(
              child: Text('Выберите бизнес для просмотра CRM'),
            )
          : RefreshIndicator(
              onRefresh: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final crmProvider = Provider.of<CrmProvider>(context, listen: false);
                final shouldShowAll = _shouldShowAll(authProvider, businessId);
                await crmProvider.refreshAllCrmData(businessId, showAll: shouldShowAll);
              },
              child: Consumer<CrmProvider>(
                builder: (context, crmProvider, child) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildSalesFunnelBlock(context, crmProvider),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTasksAndClientsBlock(context, crmProvider),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildOrdersFunnelBlock(context, crmProvider),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildAnalyticsBlock(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  /// Левый верхний блок: Воронка продаж
  Widget _buildSalesFunnelBlock(BuildContext context, CrmProvider crmProvider) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          final currentRoute = GoRouterState.of(context).uri.path;
          const targetRoute = '/business/operational/crm/sales_funnel';
          debugPrint('🖱️ [CrmPage] Нажата кнопка: "Воронка продаж"');
          debugPrint('📍 [CrmPage] Текущий route: $currentRoute');
          debugPrint('🎯 [CrmPage] Целевой route: $targetRoute');
          context.go(targetRoute);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_down,
                    size: 24,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'Воронка продаж',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStageRow(
                    'Необработанные',
                    crmProvider.getCustomersCountByStage(SalesFunnelStage.unprocessed),
                    Colors.grey,
                  ),
                  _buildStageRow(
                    'В работе',
                    crmProvider.getCustomersCountByStage(SalesFunnelStage.inProgress),
                    Colors.blue,
                  ),
                  _buildStageRow(
                    'Заинтересованы',
                    crmProvider.getCustomersCountByStage(SalesFunnelStage.interested),
                    Colors.orange,
                  ),
                  _buildStageRow(
                    'Заключен договор',
                    crmProvider.getCustomersCountByStage(SalesFunnelStage.contractSigned),
                    Colors.purple,
                  ),
                  _buildStageRow(
                    'Продажи по договору',
                    crmProvider.getCustomersCountByStage(SalesFunnelStage.salesByContract),
                    Colors.green,
                  ),
                  _buildStageRow(
                    'Отказ по причине',
                    crmProvider.getCustomersCountByStage(SalesFunnelStage.refused),
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Левый нижний блок: Воронка заказов
  Widget _buildOrdersFunnelBlock(BuildContext context, CrmProvider crmProvider) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          final currentRoute = GoRouterState.of(context).uri.path;
          const targetRoute = '/business/operational/crm/orders_funnel';
          debugPrint('🖱️ [CrmPage] Нажата кнопка: "Воронка заказов"');
          debugPrint('📍 [CrmPage] Текущий route: $currentRoute');
          debugPrint('🎯 [CrmPage] Целевой route: $targetRoute');
          context.go(targetRoute);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 24,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'Воронка заказов',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStageRow(
                    'Заказ принят',
                    crmProvider.getOrdersCountByStage(OrderFunnelStage.orderAccepted),
                    Colors.grey,
                  ),
                  _buildStageRow(
                    'Заказ начат',
                    crmProvider.getOrdersCountByStage(OrderFunnelStage.orderStarted),
                    Colors.blue,
                  ),
                  _buildStageRow(
                    'Заказ в работе',
                    crmProvider.getOrdersCountByStage(OrderFunnelStage.orderInProgress),
                    Colors.orange,
                  ),
                  _buildStageRow(
                    'Заказ готов',
                    crmProvider.getOrdersCountByStage(OrderFunnelStage.orderReady),
                    Colors.purple,
                  ),
                  _buildStageRow(
                    'Заказ передан клиенту',
                    crmProvider.getOrdersCountByStage(OrderFunnelStage.orderDelivered),
                    Colors.green,
                  ),
                  _buildStageRow(
                    'Возврат по причине',
                    crmProvider.getOrdersCountByStage(OrderFunnelStage.orderReturned),
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Правый верхний блок: Задачи по клиентам и список клиентов
  Widget _buildTasksAndClientsBlock(BuildContext context, CrmProvider crmProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Задачи по клиентам
            Expanded(
              child: InkWell(
                onTap: () {
                  context.go('/business/operational/crm/customer_tasks');
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.task,
                        size: 20,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Задачи',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${crmProvider.customerTasksCount}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Список клиентов
            Expanded(
              child: InkWell(
                onTap: () {
                  final currentRoute = GoRouterState.of(context).uri.path;
                  const targetRoute = '/business/operational/crm/clients';
                  debugPrint('🖱️ [CrmPage] Нажата кнопка: "Клиенты"');
                  debugPrint('📍 [CrmPage] Текущий route: $currentRoute');
                  debugPrint('🎯 [CrmPage] Целевой route: $targetRoute');
                  debugPrint('🔗 [CrmPage] Вызываю context.go($targetRoute)...');
                  context.go(targetRoute);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final newRoute = GoRouterState.of(context).uri.path;
                    debugPrint('✅ [CrmPage] После навигации route: $newRoute');
                    if (newRoute == currentRoute) {
                      debugPrint('⚠️ [CrmPage] ВНИМАНИЕ: Route не изменился!');
                    } else {
                      debugPrint('✔️ [CrmPage] Успешно: route изменился');
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Клиенты',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${crmProvider.allCustomers.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
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

  /// Правый нижний блок: Аналитика
  Widget _buildAnalyticsBlock(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Аналитика',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Скоро',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Строка со статусом и количеством
  Widget _buildStageRow(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

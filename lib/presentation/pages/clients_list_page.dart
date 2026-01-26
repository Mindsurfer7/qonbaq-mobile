import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/customer.dart';
import 'customer_detail_page.dart';

/// Страница списка клиентов
class ClientsListPage extends StatefulWidget {
  const ClientsListPage({super.key});

  @override
  State<ClientsListPage> createState() => _ClientsListPageState();
}

class _ClientsListPageState extends State<ClientsListPage> {
  bool? _showAllFilter; // Состояние фильтра "Показать всех"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFilter();
      _loadCustomers();
    });
  }

  /// Инициализирует фильтр на основе прав пользователя
  void _initializeFilter() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;
    
    if (businessId != null) {
      // Если пользователь может видеть всех, по умолчанию показываем всех
      _showAllFilter = _shouldShowAll(authProvider, businessId) == true ? true : null;
    }
  }

  Future<void> _loadCustomers({bool? forceShowAll}) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final crmProvider = Provider.of<CrmProvider>(context, listen: false);
    
    final businessId = profileProvider.selectedBusiness?.id;
    if (businessId != null) {
      // Используем переданное значение или состояние фильтра
      // Если forceShowAll не передан, используем состояние фильтра или определяем автоматически
      final showAll = forceShowAll ?? 
          _showAllFilter ?? 
          _shouldShowAll(authProvider, businessId);
      await crmProvider.loadAllCustomersList(businessId, showAll: showAll);
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;
    final canShowAllFilter = businessId != null && _shouldShowAll(authProvider, businessId) == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Список клиентов'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (businessId != null) {
                _loadCustomers();
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
              child: Text('Выберите бизнес для просмотра списка клиентов'),
            )
          : Column(
              children: [
                // Фильтр "Показать всех" для гендира/РОПа
                if (canShowAllFilter)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Показать всех клиентов',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        Switch(
                          value: _showAllFilter ?? true,
                          onChanged: (value) {
                            setState(() {
                              _showAllFilter = value;
                            });
                            _loadCustomers(forceShowAll: value);
                          },
                        ),
                      ],
                    ),
                  ),
                // Список клиентов
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadCustomers();
                    },
                    child: Consumer<CrmProvider>(
                builder: (context, crmProvider, child) {
                  if (crmProvider.isLoadingAllCustomers && crmProvider.allCustomers.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (crmProvider.errorAllCustomers != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            crmProvider.errorAllCustomers!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _loadCustomers();
                            },
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (crmProvider.allCustomers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'Нет клиентов',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Клиенты будут отображаться здесь',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: crmProvider.allCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = crmProvider.allCustomers[index];
                        return _buildCustomerCard(context, customer);
                      },
                    );
                  },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            customer.customerType == CustomerType.individual
                ? Icons.person
                : Icons.business,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          customer.displayName ?? customer.name ?? 'Клиент',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.salesFunnelStage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: Text(
                    _getStageName(customer.salesFunnelStage!),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: _getStageColor(customer.salesFunnelStage!).withOpacity(0.2),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomerDetailPage(customerId: customer.id),
            ),
          );
        },
      ),
    );
  }

  String _getStageName(SalesFunnelStage stage) {
    switch (stage) {
      case SalesFunnelStage.unprocessed:
        return 'Необработанные';
      case SalesFunnelStage.inProgress:
        return 'В работе';
      case SalesFunnelStage.interested:
        return 'Заинтересованы';
      case SalesFunnelStage.contractSigned:
        return 'Заключен договор';
      case SalesFunnelStage.salesByContract:
        return 'Продажи по договору';
      case SalesFunnelStage.refused:
        return 'Отказ по причине';
    }
  }

  Color _getStageColor(SalesFunnelStage stage) {
    switch (stage) {
      case SalesFunnelStage.unprocessed:
        return Colors.grey;
      case SalesFunnelStage.inProgress:
        return Colors.blue;
      case SalesFunnelStage.interested:
        return Colors.orange;
      case SalesFunnelStage.contractSigned:
        return Colors.purple;
      case SalesFunnelStage.salesByContract:
        return Colors.green;
      case SalesFunnelStage.refused:
        return Colors.red;
    }
  }
}

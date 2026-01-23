import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/customer.dart';
import '../providers/crm_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/sales_funnel_accordion.dart';
import '../widgets/create_customer_dialog.dart';

/// Страница воронки продаж
class SalesFunnelPage extends StatefulWidget {
  const SalesFunnelPage({super.key});

  @override
  State<SalesFunnelPage> createState() => _SalesFunnelPageState();
}

class _SalesFunnelPageState extends State<SalesFunnelPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
    });
  }

  void _loadCustomers() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final crmProvider = Provider.of<CrmProvider>(context, listen: false);
    
    final businessId = profileProvider.selectedBusiness?.id;
    if (businessId != null) {
      crmProvider.loadAllCustomers(businessId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Воронка продаж'),
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
                builder: (context) => const CreateCustomerDialog(
                  initialStage: SalesFunnelStage.unprocessed,
                ),
              );
            },
            tooltip: 'Добавить клиента',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (businessId != null) {
                final crmProvider = Provider.of<CrmProvider>(context, listen: false);
                crmProvider.refreshAll(businessId);
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
              child: Text('Выберите бизнес для просмотра воронки продаж'),
            )
          : RefreshIndicator(
              onRefresh: () async {
                final crmProvider = Provider.of<CrmProvider>(context, listen: false);
                await crmProvider.refreshAll(businessId);
              },
              child: Consumer<CrmProvider>(
                builder: (context, crmProvider, child) {
                  if (crmProvider.isLoading && 
                      crmProvider.getCustomersByStage(SalesFunnelStage.unprocessed).isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Необработанные
                      SalesFunnelAccordion(
                        stage: SalesFunnelStage.unprocessed,
                        title: 'Необработанные',
                        isExpanded: true, // Первая открыта по умолчанию
                      ),
                      // В работе
                      SalesFunnelAccordion(
                        stage: SalesFunnelStage.inProgress,
                        title: 'В работе',
                      ),
                      // Заинтересованы
                      SalesFunnelAccordion(
                        stage: SalesFunnelStage.interested,
                        title: 'Заинтересованы',
                      ),
                      // Заключен договор
                      SalesFunnelAccordion(
                        stage: SalesFunnelStage.contractSigned,
                        title: 'Заключен договор',
                      ),
                      // Продажи по договору
                      SalesFunnelAccordion(
                        stage: SalesFunnelStage.salesByContract,
                        title: 'Продажи по договору',
                      ),
                      // Отказ по причине
                      SalesFunnelAccordion(
                        stage: SalesFunnelStage.refused,
                        title: 'Отказ по причине',
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}










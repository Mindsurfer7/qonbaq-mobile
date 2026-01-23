import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/customer.dart';
import '../providers/crm_provider.dart';
import '../providers/profile_provider.dart';
import 'customer_mini_card.dart';

/// Аккордеон для отображения клиентов по статусу воронки продаж
class SalesFunnelAccordion extends StatefulWidget {
  final SalesFunnelStage stage;
  final String title;
  final int? currentCount;
  final int? totalCount;
  final bool isExpanded;

  const SalesFunnelAccordion({
    super.key,
    required this.stage,
    required this.title,
    this.currentCount,
    this.totalCount,
    this.isExpanded = false,
  });

  @override
  State<SalesFunnelAccordion> createState() => _SalesFunnelAccordionState();
}

class _SalesFunnelAccordionState extends State<SalesFunnelAccordion> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crmProvider = Provider.of<CrmProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    final businessId = profileProvider.selectedBusiness?.id;
    if (businessId == null) {
      return const SizedBox.shrink();
    }

    final customers = crmProvider.getCustomersByStage(widget.stage);
    final isLoading = crmProvider.isLoadingStage(widget.stage);
    final error = crmProvider.getErrorForStage(widget.stage);

    // Определяем счетчик
    final displayCount = widget.currentCount ?? customers.length;
    final displayTotal = widget.totalCount;

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
              
              // Загружаем клиентов при первом открытии
              if (_isExpanded && customers.isEmpty && !isLoading) {
                crmProvider.loadCustomersForStage(businessId, widget.stage);
              }
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
                child: _buildContent(customers, isLoading, error, businessId, crmProvider),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<Customer> customers,
    bool isLoading,
    String? error,
    String businessId,
    CrmProvider crmProvider,
  ) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              error,
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                crmProvider.loadCustomersForStage(businessId, widget.stage);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

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
          onTap: () {
            Navigator.of(context).pushNamed(
              '/business/operational/crm/customer_detail',
              arguments: customer.id,
            );
          },
        );
      },
    );
  }
}

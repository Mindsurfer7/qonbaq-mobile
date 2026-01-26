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

class _SalesFunnelAccordionState extends State<SalesFunnelAccordion> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(_expandAnimation);
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    final isLoading = crmProvider.isLoadingCustomersStage(widget.stage);
    final error = crmProvider.getErrorForCustomersStage(widget.stage);

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
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
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
                  // Иконка раскрытия с анимацией
                  RotationTransition(
                    turns: _iconRotationAnimation,
                    child: Icon(
                      Icons.expand_less,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Контент аккордеона
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
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
                crmProvider.refreshCustomersStage(businessId, widget.stage);
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

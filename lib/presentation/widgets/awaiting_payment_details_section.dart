import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';
import 'payment_details_dialog.dart';

/// Секция "Требует заполнения платежных реквизитов".
///
/// Отображает плашки для согласований, для которых требуется заполнение платежных реквизитов.
/// Принимает список ID согласований из awaitingPaymentDetails.
/// При клике на плашку открывается диалог, который сам загружает схему формы.
class AwaitingPaymentDetailsSection extends StatelessWidget {
  final List<String> approvalIds; // Список ID согласований для отображения
  final String headerText;
  final EdgeInsets headerPadding;
  final EdgeInsets cardMargin;
  final EdgeInsets listTilePadding;
  final bool showDivider;
  final VoidCallback? onPaymentDetailsFilled;

  const AwaitingPaymentDetailsSection({
    super.key,
    required this.approvalIds,
    this.headerText = 'Требует заполнения платежных реквизитов',
    this.headerPadding = const EdgeInsets.fromLTRB(16, 20, 16, 12),
    this.cardMargin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.listTilePadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.showDivider = true,
    this.onPaymentDetailsFilled,
  });

  @override
  Widget build(BuildContext context) {
    if (approvalIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: headerPadding,
          child: Row(
            children: [
              Icon(
                Icons.payment,
                color: theme.statusWarning,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headerText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...approvalIds.map((approvalId) {
          return Card(
            margin: cardMargin,
            color: theme.statusWarning.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme.borderRadius),
              side: BorderSide(
                color: theme.statusWarning.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: ListTile(
              contentPadding: listTilePadding,
              leading: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.statusWarning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    theme.borderRadius * 0.75,
                  ),
                ),
                child: Icon(
                  Icons.payment,
                  color: theme.statusWarning,
                  size: 24,
                ),
              ),
              title: Text(
                'Заполнить платежные реквизиты',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                  fontSize: 15,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.textSecondary,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => PaymentDetailsDialog(
                    approvalId: approvalId,
                    onSuccess: onPaymentDetailsFilled,
                  ),
                );
              },
            ),
          );
        }),
        if (showDivider) ...[
          const SizedBox(height: 20),
          const Divider(height: 32),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

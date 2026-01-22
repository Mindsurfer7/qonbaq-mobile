import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/approval.dart';
import '../../core/theme/theme_extensions.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'payment_details_dialog.dart';

/// Секция "Требует заполнения платежных реквизитов".
///
/// Отображает согласования со статусом AWAITING_PAYMENT_DETAILS,
/// которые требуют заполнения платежных реквизитов бухгалтером.
class AwaitingPaymentDetailsSection extends StatelessWidget {
  final List<Approval> approvals;
  final String headerText;
  final EdgeInsets headerPadding;
  final EdgeInsets cardMargin;
  final EdgeInsets listTilePadding;
  final bool showDivider;
  final VoidCallback? onPaymentDetailsFilled;

  const AwaitingPaymentDetailsSection({
    super.key,
    required this.approvals,
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

  /// Проверка, является ли пользователь бухгалтером или генеральным директором
  bool _isAccountantOrGeneralDirector(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final selectedBusiness = profileProvider.selectedBusiness;

    if (currentUser == null || selectedBusiness == null) return false;

    // Админы могут видеть
    if (currentUser.isAdmin) return true;

    // Проверяем, является ли пользователь генеральным директором
    final permission = currentUser.getPermissionsForBusiness(selectedBusiness.id);
    if (permission != null && permission.isGeneralDirector) {
      return true;
    }

    // Проверяем роль бухгалтера через employment
    if (profileProvider.isAccountant) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем права доступа
    if (!_isAccountantOrGeneralDirector(context)) {
      return const SizedBox.shrink();
    }

    // Фильтруем только согласования со статусом awaitingPaymentDetails
    final filteredApprovals = approvals
        .where((approval) =>
            approval.status == ApprovalStatus.awaitingPaymentDetails)
        .toList();

    if (filteredApprovals.isEmpty) {
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
        ...filteredApprovals.map((approval) {
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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    approval.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (approval.description != null &&
                      approval.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      approval.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (approval.amount != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.statusSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Сумма: ${approval.amount!.toStringAsFixed(2)} ${approval.currency ?? '₽'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.statusSuccess,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
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
                    approval: approval,
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

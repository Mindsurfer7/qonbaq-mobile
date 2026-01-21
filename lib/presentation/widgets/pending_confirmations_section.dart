import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/approval.dart';
import '../../domain/entities/pending_confirmation.dart';
import '../providers/pending_confirmations_provider.dart';
import '../../core/theme/theme_extensions.dart';
import 'confirmation_dialog.dart';

/// Переиспользуемая секция "Требует подтверждения".
///
/// - Поддерживает фильтрацию списка (например, только ОС).
/// - Маппит тип согласования (templateCode) в корректные тексты и UI детали.
/// - Использует единый стиль (янтарный/оранжевый), чтобы не выглядеть тревожно.
class PendingConfirmationsSection extends StatelessWidget {
  final String headerText;
  final EdgeInsets headerPadding;
  final EdgeInsets cardMargin;
  final EdgeInsets listTilePadding;
  final bool showDivider;
  final VoidCallback? onConfirmed;
  final bool Function(PendingConfirmation pendingConfirmation)? filter;

  const PendingConfirmationsSection({
    super.key,
    this.headerText = 'Требует подтверждения',
    this.headerPadding = const EdgeInsets.fromLTRB(16, 20, 16, 12),
    this.cardMargin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.listTilePadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.showDivider = true,
    this.onConfirmed,
    this.filter,
  });

  String? _getApprovalTemplateCode(Approval approval) {
    return approval.template?.code ?? approval.templateCode;
  }

  String _normalizeTemplateCode(String code) {
    return code.toUpperCase().replaceAll('-', '_');
  }

  _ConfirmationUiConfig _getUiConfig(PendingConfirmation pendingConfirmation) {
    final code = _getApprovalTemplateCode(pendingConfirmation.approval);
    if (code == null || code.trim().isEmpty) {
      return const _ConfirmationUiConfig(
        listTitle: 'Подтвердить согласование',
        dialogTitle: 'Подтверждение согласования',
        showAmountField: true,
      );
    }

    final normalizedCode = _normalizeTemplateCode(code);
    switch (normalizedCode) {
      case 'FIXED_ASSET_TRANSFER':
        return const _ConfirmationUiConfig(
          listTitle: 'Подтвердить перемещение основных средств',
          dialogTitle: 'Подтверждение перемещения основных средств',
          showAmountField: false,
        );
      case 'CASHLESS_PAYMENT_REQUEST':
      case 'CASH_PAYMENT_REQUEST':
        return const _ConfirmationUiConfig(
          listTitle: 'Подтвердить получение средств',
          dialogTitle: 'Подтверждение получения средств',
          showAmountField: true,
        );
      default:
        return const _ConfirmationUiConfig(
          listTitle: 'Подтвердить согласование',
          dialogTitle: 'Подтверждение согласования',
          showAmountField: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PendingConfirmationsProvider>(
      builder: (context, provider, child) {
        final items =
            filter == null
                ? provider.pendingConfirmations
                : provider.pendingConfirmations.where(filter!).toList();

        if (items.isEmpty) {
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
                    Icons.pending_actions,
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
            ...items.map((pendingConfirmation) {
              final ui = _getUiConfig(pendingConfirmation);
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
                      Icons.pending_actions,
                      color: theme.statusWarning,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    ui.listTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pendingConfirmation.approval.description != null &&
                          pendingConfirmation.approval.description!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          pendingConfirmation.approval.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (ui.showAmountField &&
                          pendingConfirmation.approval.amount != null) ...[
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
                            'Сумма: ${pendingConfirmation.approval.amount!.toStringAsFixed(2)} ₽',
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
                      builder:
                          (context) => ConfirmationDialog(
                            pendingConfirmation: pendingConfirmation,
                            title: ui.dialogTitle,
                            showAmountField: ui.showAmountField,
                            onSuccess: onConfirmed,
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
      },
    );
  }
}

class _ConfirmationUiConfig {
  final String listTitle;
  final String dialogTitle;
  final bool showAmountField;

  const _ConfirmationUiConfig({
    required this.listTitle,
    required this.dialogTitle,
    required this.showAmountField,
  });
}


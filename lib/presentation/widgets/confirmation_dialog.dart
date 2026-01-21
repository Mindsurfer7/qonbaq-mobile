import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/pending_confirmation.dart';
import '../providers/pending_confirmations_provider.dart';
import '../../core/theme/theme_extensions.dart';

/// Диалог для подтверждения согласования
class ConfirmationDialog extends StatefulWidget {
  final PendingConfirmation pendingConfirmation;
  final bool showAmountField;
  final String title;
  final VoidCallback? onSuccess;

  const ConfirmationDialog({
    super.key,
    required this.pendingConfirmation,
    this.showAmountField = true,
    this.title = 'Подтверждение получения средств',
    this.onSuccess,
  });

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Устанавливаем сумму по умолчанию, если она есть
    if (widget.showAmountField &&
        widget.pendingConfirmation.approval.amount != null) {
      _amountController.text =
          widget.pendingConfirmation.approval.amount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm(bool isConfirmed) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    double? amount;
    if (widget.showAmountField && _amountController.text.trim().isNotEmpty) {
      try {
        amount = double.parse(_amountController.text.trim());
      } catch (_) {
        setState(() {
          _error = 'Неверный формат суммы';
          _isLoading = false;
        });
        return;
      }
    }

    final provider = Provider.of<PendingConfirmationsProvider>(context, listen: false);
    final success = await provider.confirmApprovalAction(
      approvalId: widget.pendingConfirmation.approval.id,
      isConfirmed: isConfirmed,
      amount: amount,
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConfirmed ? 'Согласование подтверждено' : 'Подтверждение отклонено',
          ),
          backgroundColor: isConfirmed ? Colors.green : Colors.orange,
        ),
      );
      // Вызываем callback для обновления списка
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
    } else {
      setState(() {
        _error = provider.error ?? 'Произошла ошибка';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final approval = widget.pendingConfirmation.approval;
    final theme = context.appTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.statusWarning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(theme.borderRadius),
                    ),
                    child: Icon(
                      Icons.pending_actions,
                      color: theme.statusWarning,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Информация о согласовании
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approval.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (approval.description != null && approval.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          approval.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      if (widget.showAmountField && approval.amount != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Сумма: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${approval.amount!.toStringAsFixed(2)} ₽',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.showAmountField) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Срок выплаты: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDate(approval.paymentDueDate),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Поле для суммы (если нужно указать другую)
              if (widget.showAmountField) ...[
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Сумма получения (опционально)',
                    hintText: 'Оставьте пустым, если сумма совпадает',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
              ],
              // Поле для комментария
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Комментарий (опционально)',
                  hintText: 'Введите комментарий, если необходимо',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              // Кнопки действий
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _handleConfirm(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text('Отклонить'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _handleConfirm(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Подтвердить'),
                    ),
                  ),
                ],
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

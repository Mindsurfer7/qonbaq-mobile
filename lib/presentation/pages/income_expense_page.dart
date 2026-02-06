import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:dartz/dartz.dart' hide State;
import '../providers/project_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/financial_provider.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/income.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/transit.dart';
import '../../domain/entities/financial_report.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/entities/financial_enums.dart';
import '../../domain/usecases/get_financial_form.dart';
import '../../domain/usecases/create_income.dart';
import '../../domain/usecases/create_expense.dart';
import '../../domain/usecases/create_transit.dart';
import '../../domain/usecases/get_financial_report.dart';
import '../../core/error/failures.dart';
import '../widgets/dynamic_block_form.dart';

/// Страница доходов и расходов
class IncomeExpensePage extends StatefulWidget {
  const IncomeExpensePage({super.key});

  @override
  State<IncomeExpensePage> createState() => _IncomeExpensePageState();
}

class _IncomeExpensePageState extends State<IncomeExpensePage> {
  FinancialReport? _financialReport;
  bool _isLoading = false;
  String? _error;

  // Состояние видимости списков транзакций
  bool _showIncomeTransactions = false;
  bool _showExpenseTransactions = false;
  bool _showTransitTransactions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final projectProvider = Provider.of<ProjectProvider>(
      context,
      listen: false,
    );

    final businessId = profileProvider.selectedBusiness?.id;
    if (businessId != null) {
      projectProvider.loadProjects(businessId);
    }
  }

  Future<void> _loadFinancialReport() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final financialProvider = Provider.of<FinancialProvider>(
      context,
      listen: false,
    );

    final businessId = profileProvider.selectedBusiness?.id;
    final projectId = financialProvider.selectedProject?.id;

    if (businessId == null) {
      setState(() {
        _error = 'Не выбран бизнес';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getFinancialReportUseCase = Provider.of<GetFinancialReport>(
      context,
      listen: false,
    );

    // Загружаем отчет за текущий месяц
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final result = await getFinancialReportUseCase.call(
      GetFinancialReportParams(
        businessId: businessId,
        startDate: startDate,
        endDate: endDate,
        projectId: projectId,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
      },
      (report) {
        setState(() {
          _isLoading = false;
          _financialReport = report;
        });
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.serverMessage ?? failure.message;
    } else if (failure is ServerFailure) {
      // Убираем префикс "Exception: " если он есть
      final message = failure.message;
      if (message.startsWith('Exception: ')) {
        return message.substring(11);
      }
      return message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доходы - Расходы'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go('/business');
            },
          ),
        ],
      ),
      body: Consumer3<ProjectProvider, ProfileProvider, FinancialProvider>(
        builder: (
          context,
          projectProvider,
          profileProvider,
          financialProvider,
          child,
        ) {
          final projects = projectProvider.projects ?? [];
          final businessId = profileProvider.selectedBusiness?.id ?? '';

          // Загружаем отчет при выборе проекта или изменении бизнеса
          if (financialProvider.selectedProject != null &&
              _financialReport == null &&
              !_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadFinancialReport();
            });
          }

          return Column(
            children: [
              // Выбор проекта и счета (50/50)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Селектор проекта
                    Expanded(
                      child: DropdownButtonFormField<Project>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Проект',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: financialProvider.selectedProject,
                        items:
                            projects.map((project) {
                              return DropdownMenuItem(
                                value: project,
                                child: Text(
                                  project.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          financialProvider.setSelectedProject(
                            value,
                            businessId,
                          );
                          setState(() {
                            _financialReport =
                                null; // Сбрасываем отчет при смене проекта
                          });
                          if (value != null) {
                            _loadFinancialReport();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Селектор счета
                    Expanded(
                      child: DropdownButtonFormField<Account>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Счет',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: financialProvider.selectedAccount,
                        items:
                            financialProvider.accounts.map((account) {
                              return DropdownMenuItem(
                                value: account,
                                child: Text(
                                  account.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        onChanged:
                            financialProvider.selectedProject == null
                                ? null
                                : (value) {
                                  financialProvider.setSelectedAccount(value);
                                },
                      ),
                    ),
                  ],
                ),
              ),

              if (financialProvider.selectedProject != null)
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red.shade700),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadFinancialReport,
                                  child: const Text('Повторить'),
                                ),
                              ],
                            ),
                          )
                          : _buildFinancialReportContent(financialProvider),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text(
                      'Пожалуйста, выберите проект для просмотра данных',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMovementDialog(context),
        backgroundColor: const Color(0xFFF0D400), // Желтый фон
        child: const Icon(
          Icons.add,
          color: Colors.black, // Черная иконка
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}М';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}К';
    }
    return amount.toStringAsFixed(0);
  }

  /// Построить контент финансового отчета с карточками и списком транзакций
  Widget _buildFinancialReportContent(FinancialProvider financialProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Карточки в сетке 2x2
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildEisenhowerQuadrant(
                'Приход',
                '${_formatAmount(_financialReport?.summary.totalIncome ?? 0.0)} ₽',
                Icons.trending_up,
                Colors.green,
                _showIncomeTransactions,
                () {
                  setState(() {
                    _showIncomeTransactions = !_showIncomeTransactions;
                  });
                },
              ),
              _buildEisenhowerQuadrant(
                'Расход',
                '${_formatAmount(_financialReport?.summary.totalExpense ?? 0.0)} ₽',
                Icons.trending_down,
                Colors.red,
                _showExpenseTransactions,
                () {
                  setState(() {
                    _showExpenseTransactions = !_showExpenseTransactions;
                  });
                },
              ),
              _buildEisenhowerQuadrant(
                'Транзит',
                '${_formatAmount((_financialReport?.summary.totalOutgoingTransits ?? 0.0) + (_financialReport?.summary.totalIncomingTransits ?? 0.0))} ₽',
                Icons.swap_horiz,
                Colors.orange,
                _showTransitTransactions,
                () {
                  setState(() {
                    _showTransitTransactions = !_showTransitTransactions;
                  });
                },
              ),
              _buildAnalyticsQuadrant(),
            ],
          ),
          // Список транзакций
          _buildTransactionsList(financialProvider),
        ],
      ),
    );
  }

  /// Квадрант в стиле матрицы Эйзенхауэра с иконкой глаза
  Widget _buildEisenhowerQuadrant(
    String title,
    String amount,
    IconData icon,
    Color color,
    bool isExpanded,
    VoidCallback onToggle,
  ) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        color: color.withOpacity(0.05),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                isExpanded ? Icons.visibility : Icons.visibility_off,
                color: color.withOpacity(0.6),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Квадрант аналитики
  Widget _buildAnalyticsQuadrant() {
    final report = _financialReport;
    if (report == null) {
      return _buildEmptyAnalyticsQuadrant();
    }

    final balance = report.summary.balance;
    final balanceColor = balance >= 0 ? Colors.green : Colors.red;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      color: Colors.blue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, color: Colors.blue, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Баланс',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatAmount(balance)} ₽',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAnalyticsQuadrant() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      color: Colors.blue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, color: Colors.blue, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Аналитика',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '0 ₽',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Получить транзакции для выбранного счета
  AccountReportData? _getSelectedAccountData(
    FinancialProvider financialProvider,
  ) {
    if (_financialReport == null || financialProvider.selectedAccount == null) {
      return null;
    }

    final selectedAccountId = financialProvider.selectedAccount!.id;
    final report = _financialReport!;

    // Если отчет по проекту, ищем счет в projectAccounts
    if (report.projectAccounts != null) {
      for (final accountData in report.projectAccounts!) {
        if (accountData.account.id == selectedAccountId) {
          return accountData;
        }
      }
    }

    return null;
  }

  /// Построить список транзакций
  Widget _buildTransactionsList(FinancialProvider financialProvider) {
    final accountData = _getSelectedAccountData(financialProvider);

    if (financialProvider.selectedAccount == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'Выберите счет для просмотра транзакций',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (accountData == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'Нет данных для выбранного счета',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Собираем все транзакции в один список в зависимости от видимости
    final transactions = <Widget>[];

    if (_showIncomeTransactions && accountData.incomes.isNotEmpty) {
      transactions.add(_buildTransactionSectionTitle('Приходы', Colors.green));
      transactions.addAll(
        accountData.incomes.map((income) => _buildIncomeItem(income)),
      );
    }

    if (_showExpenseTransactions && accountData.expenses.isNotEmpty) {
      transactions.add(_buildTransactionSectionTitle('Расходы', Colors.red));
      transactions.addAll(
        accountData.expenses.map((expense) => _buildExpenseItem(expense)),
      );
    }

    if (_showTransitTransactions) {
      if (accountData.outgoingTransits.isNotEmpty) {
        transactions.add(
          _buildTransactionSectionTitle('Исходящие транзиты', Colors.orange),
        );
        transactions.addAll(
          accountData.outgoingTransits.map(
            (transit) => _buildTransitItem(transit, true),
          ),
        );
      }
      if (accountData.incomingTransits.isNotEmpty) {
        transactions.add(
          _buildTransactionSectionTitle('Входящие транзиты', Colors.orange),
        );
        transactions.addAll(
          accountData.incomingTransits.map(
            (transit) => _buildTransitItem(transit, false),
          ),
        );
      }
    }

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'Нажмите на карточку для просмотра транзакций',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: transactions,
    );
  }

  /// Заголовок секции транзакций
  Widget _buildTransactionSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Элемент списка прихода
  Widget _buildIncomeItem(Income income) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.trending_up, color: Colors.green),
        title: Text('${_formatAmount(income.amount)} ${income.currency}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(income.transactionDate)),
            if (income.comment.isNotEmpty) Text(income.comment),
          ],
        ),
        trailing: Text(
          income.article.name,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  /// Элемент списка расхода
  Widget _buildExpenseItem(Expense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.trending_down, color: Colors.red),
        title: Text('${_formatAmount(expense.amount)} ${expense.currency}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(expense.transactionDate)),
            if (expense.comment.isNotEmpty) Text(expense.comment),
          ],
        ),
        trailing: Text(
          expense.article?.name ?? expense.category.name,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  /// Элемент списка транзита
  Widget _buildTransitItem(Transit transit, bool isOutgoing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isOutgoing ? Icons.arrow_forward : Icons.arrow_back,
          color: Colors.orange,
        ),
        title: Text(_formatAmount(transit.amount)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(transit.transactionDate)),
            Text(_formatTransitArticle(transit.article)),
            if (transit.comment.isNotEmpty) Text(transit.comment),
          ],
        ),
        trailing: Text(
          isOutgoing ? 'Исходящий' : 'Входящий',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  /// Форматирование статьи транзита
  String _formatTransitArticle(TransitArticle article) {
    switch (article) {
      case TransitArticle.BETWEEN_BANKS:
        return 'Между банками';
      case TransitArticle.BETWEEN_CASH:
        return 'Между кассами';
    }
  }

  /// Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Показать диалог выбора типа движения средств
  void _showCreateMovementDialog(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;
    if (selectedBusiness == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не выбран бизнес'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Создать движение средств'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.trending_up, color: Colors.green),
                  title: const Text('Приход'),
                  onTap: () {
                    context.pop();
                    _showCreateFinancialMovementDialog(
                      context,
                      FinancialFormType.income,
                      selectedBusiness.id,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.trending_down, color: Colors.red),
                  title: const Text('Расход'),
                  onTap: () {
                    context.pop();
                    _showCreateFinancialMovementDialog(
                      context,
                      FinancialFormType.expense,
                      selectedBusiness.id,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: Colors.orange),
                  title: const Text('Транзит'),
                  onTap: () {
                    context.pop();
                    _showCreateFinancialMovementDialog(
                      context,
                      FinancialFormType.transit,
                      selectedBusiness.id,
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Отмена'),
              ),
            ],
          ),
    );
  }

  /// Показать диалог создания движения средств с динамической формой
  void _showCreateFinancialMovementDialog(
    BuildContext context,
    FinancialFormType formType,
    String businessId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => _CreateFinancialMovementDialog(
            formType: formType,
            businessId: businessId,
            onCreated: () {
              // Перезагружаем отчет после создания
              _loadFinancialReport();
            },
          ),
    );
  }
}

/// Диалог создания движения средств
class _CreateFinancialMovementDialog extends StatefulWidget {
  final FinancialFormType formType;
  final String businessId;
  final VoidCallback onCreated;

  const _CreateFinancialMovementDialog({
    required this.formType,
    required this.businessId,
    required this.onCreated,
  });

  @override
  State<_CreateFinancialMovementDialog> createState() =>
      _CreateFinancialMovementDialogState();
}

class _CreateFinancialMovementDialogState
    extends State<_CreateFinancialMovementDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  ApprovalTemplate? _template;
  bool _isLoadingForm = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    setState(() {
      _isLoadingForm = true;
      _error = null;
    });

    final getFinancialFormUseCase = Provider.of<GetFinancialForm>(
      context,
      listen: false,
    );

    final result = await getFinancialFormUseCase.call(
      GetFinancialFormParams(
        type: widget.formType,
        businessId: widget.businessId,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoadingForm = false;
          _error = _getErrorMessage(failure);
        });
      },
      (template) {
        setState(() {
          _isLoadingForm = false;
          _template = template;
        });
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.serverMessage ?? failure.message;
    } else if (failure is ServerFailure) {
      // Убираем префикс "Exception: " если он есть
      final message = failure.message;
      if (message.startsWith('Exception: ')) {
        return message.substring(11);
      }
      return message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  Future<void> _submit() async {
    if (_template == null || _formKey.currentState == null) return;

    _formKey.currentState!.save();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final formValues = _formKey.currentState!.value;
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final financialProvider = Provider.of<FinancialProvider>(
      context,
      listen: false,
    );
    final businessId = profileProvider.selectedBusiness?.id;
    final projectId = financialProvider.selectedProject?.id;

    if (businessId == null) {
      setState(() {
        _isSubmitting = false;
        _error = 'Не выбран бизнес';
      });
      return;
    }

    // Преобразуем данные формы в entity
    final result = await _createEntity(formValues, businessId, projectId);

    result.fold(
      (failure) {
        setState(() {
          _isSubmitting = false;
          _error = _getErrorMessage(failure);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(failure)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          context.pop();
          widget.onCreated();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.formType == FinancialFormType.income
                    ? 'Приход успешно создан'
                    : widget.formType == FinancialFormType.expense
                    ? 'Расход успешно создан'
                    : 'Транзит успешно создан',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  /// Безопасное преобразование amount в double
  /// Обрабатывает как строку, так и число
  double _parseAmount(dynamic value) {
    if (value == null) {
      return 0.0;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Future<Either<Failure, void>> _createEntity(
    Map<String, dynamic> formValues,
    String businessId,
    String? projectId,
  ) async {
    // Преобразуем formValues в нужный формат, убирая префиксы блоков
    // formValues содержит данные вида {'main.accountId': '...', 'transaction.transactionDate': '...'}
    // Нужно убрать префиксы блоков и оставить только имена полей
    final formData = <String, dynamic>{};
    formValues.forEach((key, value) {
      if (value != null) {
        // Убираем префикс блока (main., transaction. и т.д.)
        final fieldName = key.contains('.') ? key.split('.').last : key;
        if (value is DateTime) {
          formData[fieldName] = value.toIso8601String();
        } else {
          formData[fieldName] = value;
        }
      }
    });

    // Если transactionDate не заполнено, используем текущее время
    if (!formData.containsKey('transactionDate')) {
      formData['transactionDate'] = DateTime.now().toIso8601String();
    }

    // Добавляем обязательные поля
    formData['businessId'] = businessId;
    if (projectId != null) {
      formData['projectId'] = projectId;
    }

    switch (widget.formType) {
      case FinancialFormType.income:
        // Проверяем обязательные поля для Income
        final accountId = formData['accountId'] as String?;
        final categoryValue = formData['category'] as String?;

        if (accountId == null || accountId.isEmpty) {
          return Left(ValidationFailure('Не выбран счет', []));
        }
        if (categoryValue == null || categoryValue.isEmpty) {
          return Left(ValidationFailure('Не выбрана категория', []));
        }

        final createIncomeUseCase = Provider.of<CreateIncome>(
          context,
          listen: false,
        );
        // Преобразуем formData в Income entity
        final income = Income(
          businessId: businessId,
          projectId: projectId,
          accountId: accountId,
          amount: _parseAmount(formData['amount']),
          currency: formData['currency'] as String? ?? 'KZT',
          article: IncomeArticle.values.firstWhere(
            (e) => e.name == formData['article'],
            orElse: () => IncomeArticle.OTHER_INCOME,
          ),
          periodicity: Periodicity.values.firstWhere(
            (e) => e.name == formData['periodicity'],
            orElse: () => Periodicity.CONSTANT,
          ),
          category: IncomeCategory.values.firstWhere(
            (e) => e.name == categoryValue,
            orElse: () => IncomeCategory.OTHER,
          ),
          serviceId: formData['serviceId'] as String?,
          paymentMethod: PaymentMethod.values.firstWhere(
            (e) => e.name == formData['paymentMethod'],
            orElse: () => PaymentMethod.CASH,
          ),
          comment: formData['comment'] as String? ?? '',
          transactionDate:
              formData['transactionDate'] is String
                  ? DateTime.parse(formData['transactionDate'] as String)
                  : formData['transactionDate'] as DateTime,
        );
        return await createIncomeUseCase.call(income);

      case FinancialFormType.expense:
        // Проверяем обязательные поля для Expense
        final accountId = formData['accountId'] as String?;

        if (accountId == null || accountId.isEmpty) {
          return Left(ValidationFailure('Не выбран счет', []));
        }

        final createExpenseUseCase = Provider.of<CreateExpense>(
          context,
          listen: false,
        );
        final expense = Expense(
          businessId: businessId,
          projectId: projectId,
          accountId: accountId,
          amount: _parseAmount(formData['amount']),
          currency: formData['currency'] as String? ?? 'KZT',
          category: ExpenseCategory.values.firstWhere(
            (e) => e.name == formData['category'],
            orElse: () => ExpenseCategory.COMMON,
          ),
          article:
              formData['article'] != null
                  ? ExpenseArticle.values.firstWhere(
                    (e) => e.name == formData['article'],
                    orElse: () => ExpenseArticle.OTHER,
                  )
                  : null,
          periodicity: Periodicity.values.firstWhere(
            (e) => e.name == formData['periodicity'],
            orElse: () => Periodicity.CONSTANT,
          ),
          serviceId: formData['serviceId'] as String?,
          paymentMethod: PaymentMethod.values.firstWhere(
            (e) => e.name == formData['paymentMethod'],
            orElse: () => PaymentMethod.CASH,
          ),
          comment: formData['comment'] as String? ?? '',
          transactionDate:
              formData['transactionDate'] is String
                  ? DateTime.parse(formData['transactionDate'] as String)
                  : formData['transactionDate'] as DateTime,
        );
        return await createExpenseUseCase.call(expense);

      case FinancialFormType.transit:
        // Проверяем обязательные поля для Transit
        final fromAccountId = formData['fromAccountId'] as String?;
        final toAccountId = formData['toAccountId'] as String?;

        if (fromAccountId == null || fromAccountId.isEmpty) {
          return Left(ValidationFailure('Не выбран счет отправителя', []));
        }
        if (toAccountId == null || toAccountId.isEmpty) {
          return Left(ValidationFailure('Не выбран счет получателя', []));
        }

        final createTransitUseCase = Provider.of<CreateTransit>(
          context,
          listen: false,
        );
        final transit = Transit(
          businessId: businessId,
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amount: _parseAmount(formData['amount']),
          article: TransitArticle.values.firstWhere(
            (e) => e.name == formData['article'],
            orElse: () => TransitArticle.BETWEEN_BANKS,
          ),
          method: TransitMethod.values.firstWhere(
            (e) => e.name == formData['method'],
            orElse: () => TransitMethod.CASH,
          ),
          comment: formData['comment'] as String? ?? '',
          transactionDate:
              formData['transactionDate'] is String
                  ? DateTime.parse(formData['transactionDate'] as String)
                  : formData['transactionDate'] as DateTime,
        );
        return await createTransitUseCase.call(transit);

      default:
        return Left(ServerFailure('Неподдерживаемый тип движения средств'));
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    switch (widget.formType) {
      case FinancialFormType.income:
        title = 'Создать приход';
        break;
      case FinancialFormType.expense:
        title = 'Создать расход';
        break;
      case FinancialFormType.transit:
        title = 'Создать транзит';
        break;
      default:
        title = 'Создать движение средств';
    }

    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child:
              _isLoadingForm
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : _error != null
                  ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadForm,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  )
                  : _template == null
                  ? const Text('Шаблон не найден')
                  : FormBuilder(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_template!.formSchema != null)
                          DynamicBlockForm(
                            formSchema: _template!.formSchema,
                            formKey: _formKey,
                          ),
                      ],
                    ),
                  ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => context.pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed:
              (_isSubmitting || _isLoadingForm || _template == null)
                  ? null
                  : _submit,
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Создать'),
        ),
      ],
    );
  }
}

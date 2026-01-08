import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/financial_enums.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/get_financial_form.dart';
import '../../domain/usecases/create_approval.dart';
import '../../domain/usecases/create_account.dart';
import '../../core/error/failures.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/project_provider.dart';
import '../providers/financial_provider.dart';
import '../widgets/dynamic_block_form.dart';

/// Страница финансового блока
class FinancialBlockPage extends StatefulWidget {
  const FinancialBlockPage({super.key});

  @override
  State<FinancialBlockPage> createState() => _FinancialBlockPageState();
}

class _FinancialBlockPageState extends State<FinancialBlockPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccounts();
    });
  }

  void _loadAccounts() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    if (selectedBusiness != null) {
      final financialProvider = Provider.of<FinancialProvider>(context, listen: false);
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      
      // Загружаем проекты, если еще не загружены
      if (projectProvider.projects == null || projectProvider.projects!.isEmpty) {
        projectProvider.loadProjects(selectedBusiness.id).then((_) {
          if (mounted) {
            // После загрузки проектов выбираем первый
            if (projectProvider.projects != null && projectProvider.projects!.isNotEmpty) {
              final firstProject = projectProvider.projects![0];
              financialProvider.setSelectedProject(firstProject, selectedBusiness.id);
              // Загружаем счета для выбранного проекта
              financialProvider.loadAccounts(selectedBusiness.id, projectId: firstProject.id).then((_) {
                // Если счетов нет для проекта, пробуем загрузить все счета бизнеса
                if (mounted && financialProvider.accounts.isEmpty) {
                  financialProvider.loadAccounts(selectedBusiness.id);
                }
              });
            } else {
              // Если проектов нет, загружаем счета без проекта
              financialProvider.loadAccounts(selectedBusiness.id);
            }
          }
        });
      } else {
        // Проекты уже загружены
        if (financialProvider.selectedProject == null && projectProvider.projects!.isNotEmpty) {
          // Выбираем первый проект если не выбран
          final firstProject = projectProvider.projects![0];
          financialProvider.setSelectedProject(firstProject, selectedBusiness.id);
          financialProvider.loadAccounts(selectedBusiness.id, projectId: firstProject.id).then((_) {
            // Если счетов нет для проекта, пробуем загрузить все счета бизнеса
            if (mounted && financialProvider.accounts.isEmpty) {
              financialProvider.loadAccounts(selectedBusiness.id);
            }
          });
        } else if (financialProvider.selectedProject != null) {
          // Загружаем счета для выбранного проекта
          final projectId = financialProvider.selectedProject!.id;
          financialProvider.loadAccounts(selectedBusiness.id, projectId: projectId).then((_) {
            // Если счетов нет для проекта, пробуем загрузить все счета бизнеса
            if (mounted && financialProvider.accounts.isEmpty) {
              financialProvider.loadAccounts(selectedBusiness.id);
            }
          });
        } else {
          // Проектов нет, загружаем счета без проекта
          financialProvider.loadAccounts(selectedBusiness.id);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreateAccount = _canCreateAccount(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансовый блок'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/business');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Блок с проектами и счетами (только для админов и гендиректоров)
          if (canCreateAccount) ...[
            _buildProjectsControls(context),
            _buildAccountsControls(context),
          ],
          // Основной контент
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                // Левый верхний: Заявки на оплату
                _buildPaymentRequestsBlock(context),
                // Правый верхний: Расход/Приход
                _buildIncomeExpenseBlock(context),
                // Левый нижний: Начисления ЗП
                _buildSalaryBlock(context),
                // Правый нижний: Аналитический блок
                _buildAnalyticsBlock(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Проверяет, может ли пользователь создавать счета
  bool _canCreateAccount(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final currentUser = authProvider.user;
    final selectedBusiness = profileProvider.selectedBusiness;

    if (currentUser == null || selectedBusiness == null) return false;

    // Админы могут создавать счета
    if (currentUser.isAdmin) return true;

    // Проверяем, является ли пользователь гендиректором в выбранном бизнесе
    final permission = currentUser.getPermissionsForBusiness(
      selectedBusiness.id,
    );
    if (permission != null && permission.isGeneralDirector) {
      return true;
    }

    return false;
  }

  /// Получить иконку для типа счета
  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.CASH:
        return Icons.money;
      case AccountType.BANK_ACCOUNT:
        return Icons.account_balance;
      case AccountType.TERMINAL:
        return Icons.point_of_sale;
      case AccountType.OTHER:
        return Icons.account_balance_wallet;
    }
  }

  /// Получить цвет для типа счета
  Color _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.CASH:
        return Colors.green;
      case AccountType.BANK_ACCOUNT:
        return Colors.blue;
      case AccountType.TERMINAL:
        return Colors.orange;
      case AccountType.OTHER:
        return Colors.purple;
    }
  }

  /// Форматировать баланс с валютой
  String _formatBalance(double balance, String currency) {
    return '${balance.toStringAsFixed(2)} $currency';
  }

  /// Блок с проектами (controls)
  Widget _buildProjectsControls(BuildContext context) {
    return Consumer2<ProjectProvider, FinancialProvider>(
      builder: (context, projectProvider, financialProvider, _) {
        final projects = projectProvider.projects ?? [];
        final selectedProject = financialProvider.selectedProject;

        if (projects.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final isSelected = selectedProject?.id == project.id;
              
              return Padding(
                padding: EdgeInsets.only(
                  right: index < projects.length - 1 ? 8 : 0,
                ),
                child: _buildProjectCard(project, isSelected),
              );
            },
          ),
        );
      },
    );
  }

  /// Карточка проекта
  Widget _buildProjectCard(Project project, bool isSelected) {
    return InkWell(
      onTap: () {
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        final selectedBusiness = profileProvider.selectedBusiness;
        if (selectedBusiness != null) {
          final financialProvider = Provider.of<FinancialProvider>(context, listen: false);
          financialProvider.setSelectedProject(project, selectedBusiness.id);
          // Загружаем счета для проекта, если их нет - загружаем без фильтра
          financialProvider.loadAccounts(selectedBusiness.id, projectId: project.id).then((_) {
            // Если счетов нет для проекта, пробуем загрузить все счета бизнеса
            if (mounted && financialProvider.accounts.isEmpty) {
              financialProvider.loadAccounts(selectedBusiness.id);
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder,
              color: isSelected ? Colors.blue : Colors.grey.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              project.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Блок со счетами (controls)
  Widget _buildAccountsControls(BuildContext context) {
    return Consumer<FinancialProvider>(
      builder: (context, financialProvider, _) {
        final accounts = financialProvider.accounts;
        final isLoading = financialProvider.isLoading;
        final selectedProject = financialProvider.selectedProject;
        final error = financialProvider.error;

        // Если проект не выбран, не показываем счета
        if (selectedProject == null) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: isLoading && accounts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : error != null && accounts.isEmpty
                  ? Center(
                      child: Text(
                        error,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Счета слева
                        Expanded(
                          child: accounts.isEmpty
                              ? Center(
                                  child: Text(
                                    'Нет счетов',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: accounts.length,
                                  itemBuilder: (context, index) {
                                    final account = accounts[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: index < accounts.length - 1 ? 8 : 0,
                                      ),
                                      child: _buildAccountCard(account),
                                    );
                                  },
                                ),
                        ),
                        // Плюсик справа
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildAddAccountButton(context),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  /// Карточка счета
  Widget _buildAccountCard(Account account) {
    final icon = _getAccountTypeIcon(account.type);
    final color = _getAccountTypeColor(account.type);
    final balance = _formatBalance(account.balance, account.currency);

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    balance,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Кнопка добавления счета (желтый фон, черная иконка)
  Widget _buildAddAccountButton(BuildContext context) {
    return Material(
      color: const Color(0xFFF0D400), // Желтый фон
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showCreateAccountDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.add,
            color: Colors.black, // Черная иконка
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Левый верхний блок: Заявки на оплату
  Widget _buildPaymentRequestsBlock(BuildContext context) {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Заявки на оплату',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSmallPaymentButton(
                    context,
                    'Безналичная',
                    Icons.account_balance,
                    Colors.blue,
                    FinancialFormType.cashless,
                  ),
                  const SizedBox(height: 8),
                  _buildSmallPaymentButton(
                    context,
                    'Наличная',
                    Icons.money,
                    Colors.green,
                    FinancialFormType.cash,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Маленькая кнопка для заявки на оплату
  Widget _buildSmallPaymentButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    FinancialFormType formType,
  ) {
    return InkWell(
      onTap: () => _showCreateFinancialRequestDialog(context, formType),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Правый верхний блок: Расход/Приход
  Widget _buildIncomeExpenseBlock(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/business/financial/income_expense');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Расход / Приход',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIncomeExpenseItem(
                      Icons.trending_up,
                      'Приход',
                      '0 ₽',
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildIncomeExpenseItem(
                      Icons.trending_down,
                      'Расход',
                      '0 ₽',
                      Colors.red,
                    ),
                    const SizedBox(height: 12),
                    _buildIncomeExpenseItem(
                      Icons.swap_horiz,
                      'Транзит',
                      '0 ₽',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Элемент прихода/расхода
  Widget _buildIncomeExpenseItem(
    IconData icon,
    String label,
    String amount,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Левый нижний блок: Начисления ЗП
  Widget _buildSalaryBlock(BuildContext context) {
    return Card(
      color: Colors.purple.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 32,
              color: Colors.purple,
            ),
            const SizedBox(height: 8),
            const Text(
              'Начисления ЗП',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Оклад',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '0 ₽',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Правый нижний блок: Аналитический блок
  Widget _buildAnalyticsBlock(BuildContext context) {
    return Card(
      color: Colors.amber.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 32,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 8),
            const Text(
              'Аналитика',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Показать диалог создания финансовой заявки
  void _showCreateFinancialRequestDialog(
    BuildContext context,
    FinancialFormType type,
  ) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
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
      builder: (context) => _CreateFinancialRequestDialog(
        formType: type,
        businessId: selectedBusiness.id,
      ),
    );
  }

  /// Показать диалог создания счета
  void _showCreateAccountDialog(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
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
      builder: (context) => CreateAccountDialog(
        businessId: selectedBusiness.id,
      ),
    );
  }
}

/// Диалог создания финансовой заявки
class _CreateFinancialRequestDialog extends StatefulWidget {
  final FinancialFormType formType;
  final String businessId;

  const _CreateFinancialRequestDialog({
    required this.formType,
    required this.businessId,
  });

  @override
  State<_CreateFinancialRequestDialog> createState() =>
      _CreateFinancialRequestDialogState();
}

class _CreateFinancialRequestDialogState
    extends State<_CreateFinancialRequestDialog> {
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
    if (failure is ServerFailure) {
      return failure.message;
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

    // Извлекаем paymentDueDate из formData (обязательное поле)
    // Поддерживаем оба варианта: paymentDueDate и requestDate (на случай, если маппинг не сработал)
    DateTime? paymentDueDate;
    if (formValues.containsKey('paymentDueDate')) {
      final paymentDueDateValue = formValues['paymentDueDate'];
      if (paymentDueDateValue is DateTime) {
        paymentDueDate = paymentDueDateValue;
      } else if (paymentDueDateValue is String) {
        paymentDueDate = DateTime.tryParse(paymentDueDateValue);
      }
    } else if (formValues.containsKey('requestDate')) {
      // Fallback на старое название (на случай, если маппинг не сработал)
      final requestDateValue = formValues['requestDate'];
      if (requestDateValue is DateTime) {
        paymentDueDate = requestDateValue;
      } else if (requestDateValue is String) {
        paymentDueDate = DateTime.tryParse(requestDateValue);
      }
    }

    // Проверяем наличие обязательного поля paymentDueDate
    if (paymentDueDate == null) {
      setState(() {
        _isSubmitting = false;
        _error = 'Поле "Дата оплаты" обязательно для заполнения';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Поле "Дата оплаты" обязательно для заполнения'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Получаем данные из динамической формы (исключаем системные поля и paymentDueDate/requestDate)
    final dynamicFormData = <String, dynamic>{};
    formValues.forEach((key, value) {
      // Исключаем системные поля формы и paymentDueDate/requestDate (отправляется отдельно)
      if (key != 'title' && key != 'description' && key != 'paymentDueDate' && key != 'requestDate' && value != null) {
        // Преобразуем DateTime в ISO строку для отправки на сервер
        if (value is DateTime) {
          dynamicFormData[key] = value.toIso8601String();
        } else {
          dynamicFormData[key] = value;
        }
      }
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    if (currentUserId == null) {
      setState(() {
        _isSubmitting = false;
        _error = 'Пользователь не авторизован';
      });
      return;
    }

    final createApprovalUseCase = Provider.of<CreateApproval>(
      context,
      listen: false,
    );

    final approval = Approval(
      id: '',
      businessId: widget.businessId,
      templateCode: _template!.code,
      title: _template!.name,
      status: ApprovalStatus.pending,
      createdBy: currentUserId,
      paymentDueDate: paymentDueDate,
      formData: dynamicFormData.isNotEmpty ? dynamicFormData : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await createApprovalUseCase.call(
      CreateApprovalParams(approval: approval),
    );

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
      (createdApproval) {
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Финансовая заявка успешно создана'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.formType == FinancialFormType.cashless
            ? 'Заявка на безналичную оплату'
            : 'Заявка на наличную оплату',
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: _isLoadingForm
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
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: (_isSubmitting || _isLoadingForm || _template == null)
              ? null
              : _submit,
          child: _isSubmitting
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

/// Диалог создания счета
class CreateAccountDialog extends StatefulWidget {
  final String businessId;

  const CreateAccountDialog({
    super.key,
    required this.businessId,
  });

  @override
  State<CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<CreateAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  AccountType? _selectedType;
  String _currency = 'KZT';
  String? _selectedProjectId;
  bool _isSubmitting = false;
  String? _error;
  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
    // Устанавливаем выбранный проект по умолчанию
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final financialProvider = Provider.of<FinancialProvider>(context, listen: false);
      final selectedProject = financialProvider.selectedProject;
      if (selectedProject != null) {
        setState(() {
          _selectedProjectId = selectedProject.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    final projectProvider = Provider.of<ProjectProvider>(
      context,
      listen: false,
    );
    await projectProvider.loadProjects(widget.businessId);
    if (mounted) {
      setState(() {
        _projects = projectProvider.projects ?? [];
      });
    }
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      if (failure.errors.isNotEmpty) {
        return failure.errors
            .map((e) => '${e.field}: ${e.message}')
            .join('\n');
      }
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedType == null) {
      setState(() {
        _error = 'Выберите тип счета';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final createAccountUseCase = Provider.of<CreateAccount>(
      context,
      listen: false,
    );

    final account = Account(
      id: '', // Будет присвоен сервером
      name: _nameController.text.trim(),
      businessId: widget.businessId,
      projectId: _selectedProjectId,
      balance: 0,
      currency: _currency,
      type: _selectedType!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await createAccountUseCase.call(
      CreateAccountParams(account: account),
    );

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
      (createdAccount) {
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          // Обновляем список счетов
          final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
          final selectedBusiness = profileProvider.selectedBusiness;
          if (selectedBusiness != null) {
            final financialProvider = Provider.of<FinancialProvider>(context, listen: false);
            final projectId = financialProvider.selectedProject?.id;
            financialProvider.loadAccounts(selectedBusiness.id, projectId: projectId);
          }
          
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Счет успешно создан'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Создать счет'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Название
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Название обязательно';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Тип счета
                DropdownButtonFormField<AccountType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Тип счета *',
                    border: OutlineInputBorder(),
                  ),
                  items: AccountType.values.map((type) {
                    String label;
                    switch (type) {
                      case AccountType.CASH:
                        label = 'Касса';
                        break;
                      case AccountType.BANK_ACCOUNT:
                        label = 'Банковский счет';
                        break;
                      case AccountType.TERMINAL:
                        label = 'Терминал';
                        break;
                      case AccountType.OTHER:
                        label = 'Другое';
                        break;
                    }
                    return DropdownMenuItem(
                      value: type,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Выберите тип счета';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Валюта
                TextFormField(
                  initialValue: _currency,
                  decoration: const InputDecoration(
                    labelText: 'Валюта',
                    border: OutlineInputBorder(),
                    helperText: 'По умолчанию: KZT',
                  ),
                  onChanged: (value) {
                    _currency = value.trim().isEmpty ? 'KZT' : value.trim();
                  },
                ),
                const SizedBox(height: 16),
                // Проект (опционально)
                DropdownButtonFormField<String>(
                  value: _selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: 'Проект',
                    border: OutlineInputBorder(),
                    helperText: 'Опционально',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Не выбран'),
                    ),
                    ..._projects.map((project) {
                      return DropdownMenuItem<String>(
                        value: project.id,
                        child: Text(project.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedProjectId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Описание
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                    helperText: 'Опционально',
                  ),
                  maxLines: 3,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
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










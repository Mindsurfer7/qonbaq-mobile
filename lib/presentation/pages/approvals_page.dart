import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../core/utils/dropdown_helpers.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/services/voice_context.dart';
import '../../core/utils/form_cache_storage.dart';
import '../../core/utils/responsive_utils.dart';
// import '../../core/utils/unassigned_roles_popup_storage.dart'; // Закомментировано, так как старый попап не используется
import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/usecases/get_approvals.dart';
import '../../domain/usecases/create_approval.dart';
import '../../domain/usecases/get_approval_templates.dart';
import '../../domain/entities/approvals_result.dart';
import '../../domain/entities/missing_role_info.dart';
import '../../core/error/failures.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pending_confirmations_provider.dart';
import '../widgets/dynamic_block_form.dart';
import '../widgets/voice_record_block.dart';
import '../widgets/pending_confirmations_section.dart';
import '../widgets/awaiting_payment_details_section.dart';
import '../widgets/role_assignment_stepper_dialog.dart';
import 'approval_detail_page.dart';

/// Страница согласований
class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  List<Approval> _pendingApprovals = []; // Ожидают (status = PENDING)
  List<Approval> _canApproveApprovals =
      []; // Требуют решения (canApprove = true)
  List<Approval> _myApprovals =
      []; // Мои согласования (createdBy = currentUser)
  List<Approval> _allCanApproveApprovals =
      []; // Все согласования в бизнесе (showAll=true)
  List<Approval> _completedApprovals = []; // Завершенные (COMPLETED)
  List<Approval> _approvedApprovals = []; // Утвержденные (APPROVED)
  List<Approval> _rejectedApprovals = []; // Отклоненные (REJECTED)
  late TabController _tabController;
  bool _canApproveInCurrentBusiness = false;
  bool _isLoadingAllApprovals = false; // Флаг загрузки расширенного списка

  @override
  void initState() {
    super.initState();
    // Количество вкладок зависит от прав пользователя
    _checkPermissions();
    _tabController = TabController(
      length: _canApproveInCurrentBusiness ? 3 : 2,
      vsync: this,
    );
    // Слушаем изменения вкладки
    _tabController.addListener(_onTabChanged);
    // Загружаем данные для первой вкладки после инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApprovalsForTab(0);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      _loadApprovalsForTab(_tabController.index);
    }
  }

  void _checkPermissions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;
    final currentUser = authProvider.user;

    if (currentUser != null && selectedBusiness != null) {
      _canApproveInCurrentBusiness = currentUser.canApproveInBusiness(
        selectedBusiness.id,
      );
    }
  }

  /// Проверка привилегированных прав (isAuthorizedApprover или isGeneralDirector)
  bool _hasPrivilegedPermissions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final currentUser = authProvider.user;
    final selectedBusiness = profileProvider.selectedBusiness;

    if (currentUser == null || selectedBusiness == null) return false;

    final permission = currentUser.getPermissionsForBusiness(
      selectedBusiness.id,
    );
    if (permission == null) return false;

    return permission.isAuthorizedApprover || permission.isGeneralDirector;
  }

  /// Загрузка всех согласований в бизнесе (showAll=true)
  Future<void> _loadAllApprovals() async {
    if (_isLoadingAllApprovals) return;

    setState(() {
      _isLoadingAllApprovals = true;
    });

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      setState(() {
        _isLoadingAllApprovals = false;
      });
      return;
    }

    final getApprovalsUseCase = Provider.of<GetApprovals>(
      context,
      listen: false,
    );
    final result = await getApprovalsUseCase.call(
      GetApprovalsParams(businessId: selectedBusiness.id, showAll: true),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoadingAllApprovals = false;
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
      (result) {
        setState(() {
          _isLoadingAllApprovals = false;
          _allCanApproveApprovals = result.approvals;
        });

        // Показываем поп-ап о неназначенных ролях, если они есть
        if (result.unassignedRoles != null &&
            result.unassignedRoles!.isNotEmpty) {
          _showRoleAssignmentStepper(
            result.unassignedRoles!,
            result.message ?? '',
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Загрузка согласований для конкретной вкладки
  Future<void> _loadApprovalsForTab(int tabIndex) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    final currentUser = authProvider.user;

    if (selectedBusiness == null || currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'Компания не выбрана или пользователь не авторизован';
      });
      return;
    }

    final getApprovalsUseCase = Provider.of<GetApprovals>(
      context,
      listen: false,
    );

    // Определяем, какая вкладка активна
    // Если есть права: 0 = Требуют решения, 1 = Ожидают, 2 = Завершенные
    // Если нет прав: 0 = Ожидают, 1 = Завершенные
    int actualTabIndex;
    if (_canApproveInCurrentBusiness) {
      // Есть права: tabIndex соответствует actualTabIndex
      actualTabIndex = tabIndex;
    } else {
      // Нет прав: tabIndex 0 = Ожидают (actualTabIndex 1), tabIndex 1 = Завершенные (actualTabIndex 2)
      actualTabIndex = tabIndex + 1;
    }

    try {
      if (actualTabIndex == 0) {
        // Вкладка "Требуют решения" - используем canApprove=true
        // Бэкенд должен вернуть согласования со статусами PENDING и IN_EXECUTION
        final result = await getApprovalsUseCase.call(
          GetApprovalsParams(businessId: selectedBusiness.id, canApprove: true),
        );

        // Загружаем "Мои согласования" отдельно
        final myApprovalsResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            createdBy: currentUser.id,
          ),
        );

        // awaitingPaymentDetails теперь загружаются через PendingConfirmationsProvider

        result.fold(
          (failure) {
            setState(() {
              _isLoading = false;
              _error = _getErrorMessage(failure);
            });
          },
          (result) {
            setState(() {
              _isLoading = false;
              _canApproveApprovals = result.approvals;
            });

            // Показываем поп-ап о неназначенных ролях, если они есть
            if (result.unassignedRoles != null &&
                result.unassignedRoles!.isNotEmpty) {
              _showRoleAssignmentStepper(
                result.unassignedRoles!,
                result.message ?? '',
              );
            }
          },
        );

        // Обрабатываем результат загрузки "Мои согласования"
        myApprovalsResult.fold(
          (failure) {
            // Игнорируем ошибки загрузки "Мои согласования", чтобы не блокировать основной список
          },
          (result) {
            setState(() {
              _myApprovals = result.approvals;
            });
          },
        );

        // awaitingPaymentDetails теперь загружаются через PendingConfirmationsProvider
      } else if (actualTabIndex == 1) {
        // Вкладка "Ожидают" - загружаем DRAFT, PENDING и IN_EXECUTION
        final draftResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            status: ApprovalStatus.draft,
          ),
        );
        final pendingResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            status: ApprovalStatus.pending,
          ),
        );
        final inExecutionResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            status: ApprovalStatus.inExecution,
          ),
        );

        List<Approval> allPending = [];
        draftResult.fold((failure) => _error = _getErrorMessage(failure), (
          result,
        ) {
          allPending.addAll(result.approvals);
          if (result.unassignedRoles != null &&
              result.unassignedRoles!.isNotEmpty) {
            _showRoleAssignmentStepper(
              result.unassignedRoles!,
              result.message ?? '',
            );
          }
        });
        pendingResult.fold((failure) => _error = _getErrorMessage(failure), (
          result,
        ) {
          allPending.addAll(result.approvals);
          if (result.unassignedRoles != null &&
              result.unassignedRoles!.isNotEmpty) {
            _showRoleAssignmentStepper(
              result.unassignedRoles!,
              result.message ?? '',
            );
          }
        });
        inExecutionResult.fold(
          (failure) => _error = _getErrorMessage(failure),
          (result) {
            allPending.addAll(result.approvals);
            if (result.unassignedRoles != null &&
                result.unassignedRoles!.isNotEmpty) {
              _showRoleAssignmentStepper(
                result.unassignedRoles!,
                result.message ?? '',
              );
            }
          },
        );

        setState(() {
          _isLoading = false;
          _pendingApprovals = allPending;
          _myApprovals = []; // Очищаем при загрузке других вкладок
        });
      } else if (actualTabIndex == 2) {
        // Вкладка "Завершенные" - загружаем COMPLETED, APPROVED, REJECTED
        final completedResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            status: ApprovalStatus.completed,
          ),
        );
        final approvedResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            status: ApprovalStatus.approved,
          ),
        );
        final rejectedResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            status: ApprovalStatus.rejected,
          ),
        );

        List<Approval> completed = [];
        List<Approval> approved = [];
        List<Approval> rejected = [];

        completedResult.fold((failure) => _error = _getErrorMessage(failure), (
          result,
        ) {
          completed = result.approvals;
          if (result.unassignedRoles != null &&
              result.unassignedRoles!.isNotEmpty) {
            _showRoleAssignmentStepper(
              result.unassignedRoles!,
              result.message ?? '',
            );
          }
        });
        approvedResult.fold((failure) => _error = _getErrorMessage(failure), (
          result,
        ) {
          approved = result.approvals;
          if (result.unassignedRoles != null &&
              result.unassignedRoles!.isNotEmpty) {
            _showRoleAssignmentStepper(
              result.unassignedRoles!,
              result.message ?? '',
            );
          }
        });
        rejectedResult.fold((failure) => _error = _getErrorMessage(failure), (
          result,
        ) {
          rejected = result.approvals;
          if (result.unassignedRoles != null &&
              result.unassignedRoles!.isNotEmpty) {
            _showRoleAssignmentStepper(
              result.unassignedRoles!,
              result.message ?? '',
            );
          }
        });

        setState(() {
          _isLoading = false;
          _completedApprovals = completed;
          _approvedApprovals = approved;
          _rejectedApprovals = rejected;
          _myApprovals = []; // Очищаем при загрузке других вкладок
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ошибка при загрузке: $e';
      });
    }
  }

  /// Старый метод для обратной совместимости (используется при обновлении после создания)
  Future<void> _loadApprovals() async {
    // Загружаем данные для текущей активной вкладки
    _loadApprovalsForTab(_tabController.index);
  }

  // awaitingPaymentDetails теперь загружаются через PendingConfirmationsProvider

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  // Старый метод попапа - закомментирован, но сохранен на случай необходимости
  // void _showUnassignedRolesPopup(
  //   List<UnassignedRoleInfo> roles,
  //   String message,
  // ) async {
  //   // Используем флаг, чтобы не показывать несколько диалогов одновременно
  //   if (!mounted) return;

  //   // Проверяем, нужно ли скрывать поп-ап
  //   final shouldHide = await UnassignedRolesPopupStorage.shouldHidePopup();
  //   if (shouldHide) {
  //     return;
  //   }

  //   // Увеличиваем счетчик и проверяем, нужно ли показывать поп-ап
  //   final shouldShow = await UnassignedRolesPopupStorage.incrementShowCount();
  //   if (!shouldShow) {
  //     return;
  //   }

  //   showDialog(
  //     context: context,
  //     builder:
  //         (dialogContext) => AlertDialog(
  //           title: const Row(
  //             children: [
  //               Icon(Icons.warning, color: Colors.orange),
  //               SizedBox(width: 8),
  //               Expanded(child: Text('Неназначенные роли')),
  //             ],
  //           ),
  //           content: SingleChildScrollView(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(message, style: const TextStyle(fontSize: 14)),
  //                 const SizedBox(height: 16),
  //                 ...roles.map(
  //                   (role) => Padding(
  //                     padding: const EdgeInsets.only(bottom: 8),
  //                     child: Row(
  //                       children: [
  //                         const Icon(
  //                           Icons.person_off,
  //                           size: 20,
  //                           color: Colors.orange,
  //                         ),
  //                         const SizedBox(width: 8),
  //                         Expanded(
  //                           child: Text(
  //                             role.name,
  //                             style: const TextStyle(
  //                               fontSize: 14,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(dialogContext).pop(),
  //               child: const Text('Закрыть'),
  //             ),
  //             ElevatedButton(
  //               onPressed: () {
  //                 Navigator.of(dialogContext).pop();
  //                 context.go('/roles-assignment');
  //               },
  //               child: const Text('Назначить роли'),
  //             ),
  //           ],
  //         ),
  //   );
  // }

  /// Показать многошаговый попап для назначения основных ролей
  void _showRoleAssignmentStepper(
    List<UnassignedRoleInfo> roles,
    String message,
  ) async {
    if (!mounted) return;

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      return;
    }

    // Показываем многошаговый попап
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) =>
              RoleAssignmentStepperDialog(businessId: selectedBusiness.id),
    );
  }

  void _showCreateApprovalDialog() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (selectedBusiness == null || currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Компания не выбрана или пользователь не авторизован'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Предотвращаем закрытие при клике вне диалога
      builder:
          (dialogContext) => _CreateApprovalDialog(
            businessId: selectedBusiness.id,
            currentUserId: currentUser.id,
            onSuccess: () {
              // Переключаемся на таб "Ожидают" после успешного создания
              // Если есть права: таб "Ожидают" имеет индекс 1
              // Если нет прав: таб "Ожидают" имеет индекс 0
              final pendingTabIndex = _canApproveInCurrentBusiness ? 1 : 0;
              if (_tabController.index != pendingTabIndex) {
                _tabController.animateTo(pendingTabIndex);
              }
              // Загружаем данные для таба "Ожидают" после успешного создания
              _loadApprovalsForTab(pendingTabIndex);
            },
            onApprovalCreated: (approval) {
              // Оптимистично добавляем созданное согласование в список
              // Если статус DRAFT или PENDING, добавляем во вкладку "Ожидают"
              if (approval.status == ApprovalStatus.draft ||
                  approval.status == ApprovalStatus.pending) {
                setState(() {
                  // Добавляем в начало списка pending
                  _pendingApprovals.insert(0, approval);
                });
              }
            },
          ),
    );
  }

  String _getStatusText(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.draft:
        return 'Черновик';
      case ApprovalStatus.pending:
        return 'На согласовании';
      case ApprovalStatus.approved:
        return 'Утверждено';
      case ApprovalStatus.rejected:
        return 'Отклонено';
      case ApprovalStatus.inExecution:
        return 'В исполнении';
      case ApprovalStatus.awaitingConfirmation:
        return 'Ожидает подтверждения';
      case ApprovalStatus.awaitingPaymentDetails:
        return 'Ожидает платежных реквизитов';
      case ApprovalStatus.completed:
        return 'Завершено';
      case ApprovalStatus.cancelled:
        return 'Отменено';
    }
  }

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.draft:
        return Colors.grey;
      case ApprovalStatus.pending:
        return Colors.orange;
      case ApprovalStatus.approved:
        return Colors.green;
      case ApprovalStatus.rejected:
        return Colors.red;
      case ApprovalStatus.inExecution:
        return Colors.blue;
      case ApprovalStatus.awaitingConfirmation:
        return Colors.red;
      case ApprovalStatus.awaitingPaymentDetails:
        return Colors.purple;
      case ApprovalStatus.completed:
        return Colors.teal;
      case ApprovalStatus.cancelled:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final approvalDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (approvalDate == today) {
      return 'Сегодня ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (approvalDate == today.add(const Duration(days: 1))) {
      return 'Завтра ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (approvalDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildApprovalCard(Approval approval) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          approval.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (approval.description != null &&
                approval.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  approval.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(approval.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(approval.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(approval.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApprovalDetailPage(approvalId: approval.id),
            ),
          ).then((_) => _loadApprovals()); // Обновляем список после возврата
        },
      ),
    );
  }

  /// Виджет секции pending confirmations (переиспользуемый)
  Widget _buildPendingConfirmationsSection() {
    return PendingConfirmationsSection(
      onConfirmed: () => _loadApprovalsForTab(_tabController.index),
    );
  }

  /// Виджет секции awaiting payment details (переиспользуемый)
  Widget _buildAwaitingPaymentDetailsSection() {
    return Consumer<PendingConfirmationsProvider>(
      builder: (context, provider, child) {
        return AwaitingPaymentDetailsSection(
          approvalIds: provider.awaitingPaymentDetailsIds,
          onPaymentDetailsFilled: () {
            // Обновляем awaiting payment details через провайдер
            final profileProvider = Provider.of<ProfileProvider>(
              context,
              listen: false,
            );
            final selectedBusiness = profileProvider.selectedBusiness;
            if (selectedBusiness != null) {
              // Перезагружаем awaiting payment details
              provider.loadAwaitingPaymentDetails(
                businessId: selectedBusiness.id,
              );
            }
            // Перезагружаем согласования
            _loadApprovalsForTab(_tabController.index);
          },
        );
      },
    );
  }

  Widget _buildApprovalsList(List<Approval> approvals) {
    return RefreshIndicator(
      onRefresh: _loadApprovals,
      child: ListView(
        padding: const EdgeInsets.only(top: 20),
        children: [
          // Секция pending confirmations
          _buildPendingConfirmationsSection(),
          // Секция awaiting payment details
          _buildAwaitingPaymentDetailsSection(),
          // Основной список
          if (approvals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Нет согласований',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...approvals.map((approval) => _buildApprovalCard(approval)),
        ],
      ),
    );
  }

  /// Виджет для вкладки "Требуют решения" с аккордеоном для привилегированных
  Widget _buildCanApproveTab() {
    final hasPrivileges = _hasPrivilegedPermissions();

    if (!hasPrivileges) {
      // Обычный пользователь - список с pending confirmations
      return RefreshIndicator(
        onRefresh: () => _loadApprovalsForTab(0),
        child: ListView(
          padding: const EdgeInsets.only(top: 20),
          children: [
            // Секция pending confirmations
            _buildPendingConfirmationsSection(),
            // Секция awaiting payment details
            _buildAwaitingPaymentDetailsSection(),
            // Основной список согласований
            if (_canApproveApprovals.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Нет согласований',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._canApproveApprovals.map(
                (approval) => _buildApprovalCard(approval),
              ),
          ],
        ),
      );
    }

    // Привилегированный пользователь - аккордеон
    return RefreshIndicator(
      onRefresh: () => _loadApprovalsForTab(0),
      child: ListView(
        padding: const EdgeInsets.only(top: 20),
        children: [
          // Секция pending confirmations
          _buildPendingConfirmationsSection(),
          // Секция awaiting payment details
          _buildAwaitingPaymentDetailsSection(),
          // Список согласований, требующих решения
          if (_canApproveApprovals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                '0 заявок требуют решения',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Требуют решения (${_canApproveApprovals.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ..._canApproveApprovals.map(
              (approval) => _buildApprovalCard(approval),
            ),
          ],
          // Аккордеон "Мои согласования"
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ExpansionTile(
              title: Text(
                'Мои согласования (${_myApprovals.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.person),
              initiallyExpanded: false,
              children: [
                if (_myApprovals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Нет согласований',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._myApprovals.map(
                    (approval) => _buildApprovalCard(approval),
                  ),
              ],
            ),
          ),
          // Аккордеон для всех согласований в бизнесе
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ExpansionTile(
              title: const Text(
                'Все согласования в бизнесе',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle:
                  _isLoadingAllApprovals
                      ? const Text('Загрузка...')
                      : Text('${_allCanApproveApprovals.length} согласований'),
              leading: const Icon(Icons.business),
              initiallyExpanded: false,
              onExpansionChanged: (expanded) {
                if (expanded &&
                    _allCanApproveApprovals.isEmpty &&
                    !_isLoadingAllApprovals) {
                  // Загружаем только при первом раскрытии
                  _loadAllApprovals();
                }
              },
              children: [
                if (_isLoadingAllApprovals)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_allCanApproveApprovals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Нет согласований',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._allCanApproveApprovals.map(
                    (approval) => _buildApprovalCard(approval),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Согласования'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApprovals,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go('/business');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            if (_canApproveInCurrentBusiness)
              const Tab(
                text: 'Требуют решения',
                icon: Icon(Icons.pending_actions),
              ),
            const Tab(text: 'Ожидают', icon: Icon(Icons.hourglass_empty)),
            const Tab(text: 'Завершенные', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadApprovals,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  if (_canApproveInCurrentBusiness) _buildCanApproveTab(),
                  _buildApprovalsList(_pendingApprovals),
                  _buildCompletedTab(),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateApprovalDialog,
        child: const Icon(Icons.add),
        tooltip: 'Создать согласование',
      ),
    );
  }

  /// Вкладка "Завершенные" с разделением по статусам
  Widget _buildCompletedTab() {
    final hasAny =
        _completedApprovals.isNotEmpty ||
        _approvedApprovals.isNotEmpty ||
        _rejectedApprovals.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _loadApprovals,
      child: ListView(
        children: [
          // Секция pending confirmations
          _buildPendingConfirmationsSection(),
          // Секция awaiting payment details
          _buildAwaitingPaymentDetailsSection(),
          if (!hasAny)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Нет завершенных согласований',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            )
          else if (_completedApprovals.isNotEmpty) ...[
            _buildSectionHeader('Завершено', _completedApprovals.length),
            ..._completedApprovals.map(_buildApprovalCard),
          ],
          if (_approvedApprovals.isNotEmpty) ...[
            _buildSectionHeader('Утверждено', _approvedApprovals.length),
            ..._approvedApprovals.map(_buildApprovalCard),
          ],
          if (_rejectedApprovals.isNotEmpty) ...[
            _buildSectionHeader('Отклонено', _rejectedApprovals.length),
            ..._rejectedApprovals.map(_buildApprovalCard),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

/// Диалог создания согласования
class _CreateApprovalDialog extends StatefulWidget {
  final String businessId;
  final String currentUserId;
  final VoidCallback onSuccess;
  final Function(Approval)?
  onApprovalCreated; // Callback для оптимистичного обновления

  const _CreateApprovalDialog({
    required this.businessId,
    required this.currentUserId,
    required this.onSuccess,
    this.onApprovalCreated,
  });

  @override
  State<_CreateApprovalDialog> createState() => _CreateApprovalDialogState();
}

class _CreateApprovalDialogState extends State<_CreateApprovalDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  List<ApprovalTemplate> _templates = [];
  ApprovalTemplate? _selectedTemplate;
  bool _isLoadingTemplates = true;
  bool _isLoading = false;
  String? _error;
  bool _isUpdatingTemplate =
      false; // Флаг для предотвращения циклических обновлений

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Применяет данные из voice-assist к форме
  void _applyVoiceAssistData(Map<String, dynamic> formData) {
    if (_formKey.currentState == null) return;

    // Применяем данные к полям динамической формы
    // Данные могут быть вложенными по блокам (например, {"block_name": {"field": "value"}})
    // или плоскими (например, {"field": "value"})
    final flattenedData = _flattenFormData(formData);

    for (var entry in flattenedData.entries) {
      final fieldName = entry.key;
      final value = entry.value;

      // Пропускаем title и description - они не используются в форме
      if (fieldName == 'title' || fieldName == 'description') continue;

      final field = _formKey.currentState?.fields[fieldName];
      if (field != null && value != null) {
        field.didChange(value);
      }
    }

    setState(() {});
  }

  /// Преобразует вложенную структуру formData в плоскую для заполнения формы
  Map<String, dynamic> _flattenFormData(
    Map<String, dynamic> data, {
    String prefix = '',
  }) {
    final result = <String, dynamic>{};

    for (var entry in data.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';

      if (entry.value is Map) {
        // Рекурсивно обрабатываем вложенные объекты
        result.addAll(
          _flattenFormData(entry.value as Map<String, dynamic>, prefix: key),
        );
      } else if (entry.value is List) {
        // Обрабатываем массивы (например, для deviceCheckPhoto.0.value)
        final list = entry.value as List;
        for (var i = 0; i < list.length; i++) {
          if (list[i] is Map) {
            result.addAll(
              _flattenFormData(
                list[i] as Map<String, dynamic>,
                prefix: '$key.$i',
              ),
            );
          } else {
            result['$key.$i'] = list[i];
          }
        }
      } else {
        result[key] = entry.value;
      }
    }

    return result;
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoadingTemplates = true;
      _error = null;
    });

    final getTemplatesUseCase = Provider.of<GetApprovalTemplates>(
      context,
      listen: false,
    );
    final result = await getTemplatesUseCase.call(
      GetApprovalTemplatesParams(businessId: widget.businessId),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoadingTemplates = false;
          _error = _getErrorMessage(failure);
        });
      },
      (result) {
        setState(() {
          _isLoadingTemplates = false;
          _templates = result.templates.where((t) => t.isActive).toList();
        });
        // Показываем предупреждение о недостающих ролях, если они есть
        if (result.totalMissing != null &&
            result.totalMissing! > 0 &&
            result.missingRoles != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMissingRolesDialog(result.missingRoles!);
          });
        }
      },
    );
  }

  /// Сохранить данные формы в кэш
  Future<void> _saveFormToCache(String templateCode) async {
    if (_formKey.currentState == null) return;

    _formKey.currentState!.save();
    final formValues = _formKey.currentState!.value;

    // Преобразуем значения формы для сохранения (исключаем объекты шаблонов)
    final cacheData = <String, dynamic>{};
    formValues.forEach((key, value) {
      if (value is ApprovalTemplate) {
        // Сохраняем только код шаблона
        cacheData[key] = value.code;
      } else if (value is DateTime) {
        // Сохраняем DateTime как строку
        cacheData[key] = value.toIso8601String();
      } else {
        cacheData[key] = value;
      }
    });

    await FormCacheStorage.instance.saveFormData(templateCode, cacheData);
  }

  /// Загрузить данные формы из кэша
  Future<void> _loadFormFromCache(String templateCode) async {
    if (_formKey.currentState == null) return;

    final cacheData = await FormCacheStorage.instance.loadFormData(
      templateCode,
    );
    if (cacheData == null) return;

    // Устанавливаем флаг, чтобы предотвратить вызов onChanged при программном изменении
    _isUpdatingTemplate = true;

    try {
      // Восстанавливаем значения в форму
      for (var entry in cacheData.entries) {
        final fieldName = entry.key;
        var value = entry.value;

        // Пропускаем поле template - оно уже установлено
        // Пропускаем title и description - они не используются в форме
        if (fieldName == 'template' ||
            fieldName == 'title' ||
            fieldName == 'description')
          continue;

        if (value is String && _isIso8601Date(value)) {
          // Восстанавливаем DateTime из строки
          value = DateTime.tryParse(value);
        }

        final field = _formKey.currentState?.fields[fieldName];
        if (field != null && value != null) {
          // Обновляем значение поля напрямую через FormBuilderState
          // Это не вызовет onChanged, так как мы устанавливаем флаг _isUpdatingTemplate
          field.didChange(value);
        }
      }

      // Снимаем флаг после загрузки в следующем кадре
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isUpdatingTemplate = false;
            });
          }
        });
      }
    } catch (e) {
      // В случае ошибки снимаем флаг
      if (mounted) {
        setState(() {
          _isUpdatingTemplate = false;
        });
      }
    }
  }

  /// Проверка, является ли строка датой в формате ISO8601
  bool _isIso8601Date(String value) {
    try {
      DateTime.parse(value);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState == null) {
      setState(() {
        _error = 'Ошибка формы';
      });
      return;
    }

    // Сохраняем значения формы перед валидацией
    _formKey.currentState!.save();

    // Сохраняем в кэш перед отправкой
    if (_selectedTemplate != null) {
      await _saveFormToCache(_selectedTemplate!.code);
    }

    // Валидируем форму
    if (!_formKey.currentState!.validate()) {
      // Если валидация не прошла, находим первое поле с ошибкой
      final fields = _formKey.currentState!.fields;
      String? firstError;
      for (var entry in fields.entries) {
        final field = entry.value;
        if (field.hasError) {
          firstError = field.errorText;
          break;
        }
      }
      setState(() {
        _error = firstError ?? 'Пожалуйста, заполните все обязательные поля';
      });
      return;
    }

    final formValues = _formKey.currentState!.value;

    // Получаем выбранный шаблон из формы
    final selectedTemplate = formValues['template'] as ApprovalTemplate?;
    if (selectedTemplate == null) {
      setState(() {
        _error = 'Выберите шаблон согласования';
      });
      return;
    }

    // Извлекаем paymentDueDate из formValues
    // Ищем поле с учетом префиксов блоков (main.paymentDueDate, transaction.paymentDueDate и т.д.)
    DateTime? paymentDueDate;
    for (final key in formValues.keys) {
      final fieldName = key.contains('.') ? key.split('.').last : key;
      if (fieldName == 'paymentDueDate' || fieldName == 'requestDate') {
        final value = formValues[key];
        if (value is DateTime) {
          paymentDueDate = value;
          break;
        } else if (value is String && value.isNotEmpty) {
          paymentDueDate = DateTime.tryParse(value);
          if (paymentDueDate != null) break;
        }
      }
    }

    // Если paymentDueDate не найден в форме, используем текущую дату
    // (для форм без этого поля)
    paymentDueDate ??= DateTime.now();

    // Получаем данные из динамической формы (исключаем системные поля и paymentDueDate/requestDate)
    final dynamicFormData = <String, dynamic>{};
    formValues.forEach((key, value) {
      // Получаем имя поля без префикса блока
      final fieldName = key.contains('.') ? key.split('.').last : key;
      // Исключаем системные поля формы и paymentDueDate/requestDate (отправляется отдельно)
      if (fieldName != 'template' &&
          fieldName != 'title' &&
          fieldName != 'description' &&
          fieldName != 'paymentDueDate' &&
          fieldName != 'requestDate' &&
          fieldName != 'processName' &&
          value != null) {
        // Преобразуем DateTime в ISO строку для отправки на сервер
        if (value is DateTime) {
          dynamicFormData[fieldName] = value.toIso8601String();
        } else if (value is ApprovalTemplate) {
          // Пропускаем объекты шаблонов
        } else {
          dynamicFormData[fieldName] = value;
        }
      }
    });

    // Проверяем, что есть данные формы
    if (dynamicFormData.isEmpty && selectedTemplate.formSchema != null) {
      final schema = selectedTemplate.formSchema!;
      final properties = schema['properties'] as Map<String, dynamic>?;
      if (properties != null && properties.isNotEmpty) {
        // Если есть поля в схеме, но они не заполнены, это может быть проблемой
        // Но не блокируем отправку, так как некоторые поля могут быть опциональными
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final createApprovalUseCase = Provider.of<CreateApproval>(
      context,
      listen: false,
    );

    final approval = Approval(
      id: '', // Будет создан на сервере
      businessId: widget.businessId,
      templateCode: selectedTemplate.code, // Используем код шаблона
      title: selectedTemplate.name, // Всегда используем название шаблона
      description: null, // Description не используется
      status: ApprovalStatus.pending,
      createdBy: widget.currentUserId,
      paymentDueDate: paymentDueDate,
      formData:
          dynamicFormData, // Все данные из динамической формы (без processName и paymentDueDate)
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await createApprovalUseCase.call(
      CreateApprovalParams(approval: approval),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });

        // Если это ошибка валидации, применяем ошибки к полям формы
        if (failure is ValidationFailure && _formKey.currentState != null) {
          for (var error in failure.errors) {
            final fieldName = error.field;
            final field = _formKey.currentState?.fields[fieldName];
            if (field != null) {
              field.invalidate(error.message);
              field.validate();
            }
          }
        }
      },
      (createdApproval) async {
        // Очищаем кэш при успешной отправке
        final templateCode = formValues['template'] as ApprovalTemplate?;
        if (templateCode != null) {
          await FormCacheStorage.instance.clearFormData(templateCode.code);
        }

        // Оптимистично добавляем созданное согласование в список
        if (widget.onApprovalCreated != null) {
          widget.onApprovalCreated!(createdApproval);
        }

        // Закрываем диалог СРАЗУ после успешного создания
        Navigator.of(context).pop(true);

        // Вызываем onSuccess для обновления списка (перезагрузка с сервера)
        widget.onSuccess();

        // Показываем уведомление об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Согласование успешно создано'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.serverMessage ?? failure.message;
    }
    return 'Произошла ошибка';
  }

  void _showMissingRolesDialog(List<MissingRoleInfo> missingRoles) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Отсутствуют назначенные роли')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Для работы согласований необходимо назначить сотрудников на следующие роли:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ...missingRoles.map(
                    (role) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.roleName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...role.affectedTemplates.map(
                            (template) => Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                bottom: 4,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      template.name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Закрыть'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.go('/roles-assignment');
                },
                child: const Text('Перейти к распределению ролей'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Создать согласование'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoadingTemplates)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_templates.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text(
                      'Нет доступных шаблонов согласований',
                      style: TextStyle(color: Colors.orange),
                    ),
                  )
                else ...[
                  FormBuilderDropdown<ApprovalTemplate>(
                    name: 'template',
                    initialValue: _selectedTemplate,
                    decoration: const InputDecoration(
                      labelText: 'Шаблон согласования *',
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor: context.appTheme.backgroundSurface,
                    borderRadius: BorderRadius.circular(
                      context.appTheme.borderRadius,
                    ),
                    // Для отображения выбранного значения используем только текст без стилизации
                    selectedItemBuilder: (BuildContext context) {
                      return _templates.map<Widget>((
                        ApprovalTemplate template,
                      ) {
                        return Text(
                          template.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );
                      }).toList();
                    },
                    items:
                        _templates.map((template) {
                          return createStyledDropdownItem<ApprovalTemplate>(
                            context: context,
                            value: template,
                            child: Text(
                              template.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                    onChanged: (value) async {
                      // Предотвращаем обработку, если значение не изменилось или идет обновление
                      if (value == _selectedTemplate || _isUpdatingTemplate) {
                        return;
                      }

                      // Устанавливаем флаг обновления шаблона
                      _isUpdatingTemplate = true;

                      try {
                        // Сохраняем данные старого шаблона перед сменой
                        if (_selectedTemplate != null &&
                            _formKey.currentState != null) {
                          await _saveFormToCache(_selectedTemplate!.code);
                        }

                        setState(() {
                          final oldTemplate = _selectedTemplate;
                          _selectedTemplate = value;
                          _error = null; // Очищаем ошибку при выборе

                          // Очищаем значения полей динамической формы при смене шаблона
                          if (oldTemplate != null &&
                              oldTemplate != value &&
                              _formKey.currentState != null) {
                            final oldSchema = oldTemplate.formSchema;
                            if (oldSchema != null) {
                              final oldProperties =
                                  oldSchema['properties']
                                      as Map<String, dynamic>?;
                              if (oldProperties != null) {
                                for (var fieldName in oldProperties.keys) {
                                  // Очищаем поля из старого шаблона
                                  _formKey.currentState?.fields[fieldName]
                                      ?.didChange(null);
                                }
                              }
                            }
                          }
                        });

                        // Загружаем данные из кэша для нового шаблона
                        if (value != null) {
                          WidgetsBinding.instance.addPostFrameCallback((
                            _,
                          ) async {
                            await _loadFormFromCache(value.code);
                            // Снимаем флаг после загрузки
                            if (mounted) {
                              setState(() {
                                _isUpdatingTemplate = false;
                              });
                            }
                          });
                        } else {
                          _isUpdatingTemplate = false;
                        }
                      } catch (e) {
                        // В случае ошибки снимаем флаг
                        _isUpdatingTemplate = false;
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Выберите шаблон согласования';
                      }
                      return null;
                    },
                  ),
                  // Блок голосовой записи (показываем только если выбран шаблон)
                  if (_selectedTemplate != null) ...[
                    const SizedBox(height: 16),
                    VoiceRecordBlock(
                      context: VoiceContext.approval,
                      templateCode: _selectedTemplate!.code,
                      onResultReceived: (result) {
                        // Результат - Map<String, dynamic> (formData) для контекста approval
                        final formData = result as Map<String, dynamic>;
                        _applyVoiceAssistData(formData);
                      },
                      onError: (error) {
                        setState(() {
                          _error = error;
                        });
                      },
                    ),
                  ],
                  // Динамическая форма на основе formSchema
                  if (_selectedTemplate?.formSchema != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    DynamicBlockForm(
                      key: ValueKey(
                        _selectedTemplate!.code,
                      ), // Уникальный key для пересоздания виджета при смене шаблона
                      formSchema: _selectedTemplate!.formSchema,
                      formKey: _formKey,
                    ),
                  ],
                  // Добавляем отступ снизу для корректного скролла
                  const SizedBox(height: 8),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
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
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => context.pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child:
              _isLoading
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

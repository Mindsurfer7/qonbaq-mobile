import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qonbaq/core/utils/api_client.dart';
import 'package:qonbaq/core/utils/constants.dart';
import 'package:qonbaq/core/utils/routes_config.dart';
import 'package:qonbaq/data/datasources/auth_remote_datasource.dart';
import 'package:qonbaq/data/repositories/auth_repository_impl.dart';
import 'package:qonbaq/domain/repositories/auth_repository.dart';
import 'package:qonbaq/domain/usecases/login_user.dart';
import 'package:qonbaq/domain/usecases/register_user.dart';
import 'package:qonbaq/domain/usecases/refresh_token.dart';
import 'package:qonbaq/presentation/pages/auth_page.dart';
import 'package:qonbaq/presentation/pages/home_page.dart';
import 'package:qonbaq/presentation/pages/start_page.dart';
import 'package:qonbaq/presentation/pages/workspace_selector_page.dart';
import 'package:qonbaq/presentation/pages/business_main_page.dart';
import 'package:qonbaq/presentation/pages/operational_block_page.dart';
import 'package:qonbaq/presentation/pages/financial_block_page.dart';
import 'package:qonbaq/presentation/pages/admin_block_page.dart';
import 'package:qonbaq/presentation/pages/analytics_block_page.dart';
import 'package:qonbaq/presentation/pages/crm_page.dart';
import 'package:qonbaq/presentation/pages/sales_funnel_page.dart';
import 'package:qonbaq/presentation/pages/clients_list_page.dart';
import 'package:qonbaq/presentation/pages/client_card_page.dart';
import 'package:qonbaq/presentation/pages/client_requisites_page.dart';
import 'package:qonbaq/presentation/pages/client_deal_page.dart';
import 'package:qonbaq/presentation/pages/tasks_crm_page.dart';
import 'package:qonbaq/presentation/pages/operational_tasks_page.dart';
import 'package:qonbaq/presentation/pages/task_card_page.dart';
import 'package:qonbaq/presentation/pages/control_points_page.dart';
import 'package:qonbaq/presentation/pages/business_processes_page.dart';
import 'package:qonbaq/presentation/pages/construction_page.dart';
import 'package:qonbaq/presentation/pages/production_page.dart';
import 'package:qonbaq/presentation/pages/material_resources_page.dart';
import 'package:qonbaq/presentation/pages/human_resources_page.dart';
import 'package:qonbaq/presentation/pages/monitor_panel_page.dart';
import 'package:qonbaq/presentation/pages/payment_requests_page.dart';
import 'package:qonbaq/presentation/pages/income_expense_page.dart';
import 'package:qonbaq/presentation/pages/document_management_page.dart';
import 'package:qonbaq/presentation/pages/employee_card_page.dart';
import 'package:qonbaq/presentation/pages/imprest_page.dart';
import 'package:qonbaq/presentation/pages/assets_card_page.dart';
import 'package:qonbaq/presentation/pages/fixed_assets_page.dart';
import 'package:qonbaq/presentation/pages/fixed_asset_detail_page.dart';
import 'package:qonbaq/presentation/pages/hr_documents_page.dart';
import 'package:qonbaq/presentation/pages/staff_schedule_page.dart';
import 'package:qonbaq/presentation/pages/timesheet_page.dart';
import 'package:qonbaq/presentation/pages/start_work_day_page.dart';
import 'package:qonbaq/presentation/pages/chats_email_page.dart';
import 'package:qonbaq/presentation/pages/calendar_page.dart';
import 'package:qonbaq/presentation/pages/profile_settings_page.dart';
import 'package:qonbaq/presentation/pages/tasks_page.dart';
import 'package:qonbaq/presentation/pages/task_detail_page.dart';
import 'package:qonbaq/presentation/pages/approvals_page.dart';
import 'package:qonbaq/presentation/pages/roles_assignment_page.dart';
import 'package:qonbaq/presentation/pages/inbox_items_page.dart';
import 'package:qonbaq/presentation/pages/remember_page.dart';
import 'package:qonbaq/presentation/pages/favorites_page.dart';
import 'package:qonbaq/presentation/pages/organizational_structure_page.dart';
import 'package:qonbaq/presentation/pages/department_detail_page.dart';
import 'package:qonbaq/presentation/providers/auth_provider.dart';
import 'package:qonbaq/presentation/providers/profile_provider.dart';
import 'package:qonbaq/presentation/providers/invite_provider.dart';
import 'package:qonbaq/presentation/providers/inbox_provider.dart';
import 'package:qonbaq/presentation/providers/theme_provider.dart';
import 'package:qonbaq/data/datasources/user_remote_datasource_impl.dart';
import 'package:qonbaq/data/datasources/user_local_datasource_impl.dart';
import 'package:qonbaq/data/repositories/user_repository_impl.dart';
import 'package:qonbaq/domain/repositories/user_repository.dart';
import 'package:qonbaq/domain/usecases/get_user_businesses.dart';
import 'package:qonbaq/domain/usecases/get_user_profile.dart';
import 'package:qonbaq/domain/usecases/create_business.dart';
import 'package:qonbaq/data/datasources/task_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/task_repository_impl.dart';
import 'package:qonbaq/domain/repositories/task_repository.dart';
import 'package:qonbaq/domain/usecases/create_task.dart';
import 'package:qonbaq/domain/usecases/get_tasks.dart';
import 'package:qonbaq/domain/usecases/get_task_by_id.dart';
import 'package:qonbaq/domain/usecases/update_task.dart';
import 'package:qonbaq/domain/usecases/create_task_comment.dart';
import 'package:qonbaq/domain/usecases/update_task_comment.dart';
import 'package:qonbaq/domain/usecases/delete_task_comment.dart';
import 'package:qonbaq/data/datasources/invite_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/invite_repository_impl.dart';
import 'package:qonbaq/domain/repositories/invite_repository.dart';
import 'package:qonbaq/domain/usecases/create_invite.dart';
import 'package:qonbaq/domain/usecases/get_current_invite.dart';
import 'package:qonbaq/core/utils/token_storage.dart';
import 'package:qonbaq/core/utils/auth_interceptor.dart';
import 'package:qonbaq/core/utils/deep_link_service.dart';
import 'package:qonbaq/data/datasources/workday_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/workday_repository_impl.dart';
import 'package:qonbaq/domain/repositories/workday_repository.dart';
import 'package:qonbaq/domain/usecases/start_workday.dart';
import 'package:qonbaq/domain/usecases/end_workday.dart';
import 'package:qonbaq/domain/usecases/mark_absent.dart';
import 'package:qonbaq/domain/usecases/get_workday_status.dart';
import 'package:qonbaq/domain/usecases/get_workday_statistics.dart';
import 'package:qonbaq/data/datasources/chat_remote_datasource_impl.dart';
import 'package:qonbaq/data/datasources/chat_websocket_datasource_impl.dart';
import 'package:qonbaq/data/repositories/chat_repository_impl.dart';
import 'package:qonbaq/domain/repositories/chat_repository.dart';
import 'package:qonbaq/data/datasources/department_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/department_repository_impl.dart';
import 'package:qonbaq/domain/repositories/department_repository.dart';
import 'package:qonbaq/domain/usecases/get_business_departments.dart';
import 'package:qonbaq/data/datasources/project_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/project_repository_impl.dart';
import 'package:qonbaq/domain/repositories/project_repository.dart';
import 'package:qonbaq/domain/usecases/get_business_projects.dart';
import 'package:qonbaq/domain/usecases/create_project.dart';
import 'package:qonbaq/domain/usecases/update_project.dart';
import 'package:qonbaq/domain/usecases/delete_project.dart';
import 'package:qonbaq/presentation/providers/project_provider.dart';
import 'package:qonbaq/domain/usecases/create_department.dart';
import 'package:qonbaq/domain/usecases/update_department.dart';
import 'package:qonbaq/domain/usecases/delete_department.dart';
import 'package:qonbaq/domain/usecases/set_department_manager.dart';
import 'package:qonbaq/domain/usecases/remove_department_manager.dart';
import 'package:qonbaq/domain/usecases/assign_employee_to_department.dart';
import 'package:qonbaq/domain/usecases/remove_employee_from_department.dart';
import 'package:qonbaq/domain/usecases/assign_employees_to_department.dart';
import 'package:qonbaq/presentation/providers/department_provider.dart';
import 'package:qonbaq/data/datasources/approval_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/approval_repository_impl.dart';
import 'package:qonbaq/domain/repositories/approval_repository.dart';
import 'package:qonbaq/domain/usecases/get_approvals.dart';
import 'package:qonbaq/domain/usecases/get_approval_by_id.dart';
import 'package:qonbaq/domain/usecases/create_approval.dart';
import 'package:qonbaq/domain/usecases/update_approval.dart';
import 'package:qonbaq/domain/usecases/decide_approval.dart';
import 'package:qonbaq/domain/usecases/create_approval_comment.dart';
import 'package:qonbaq/domain/usecases/get_approval_comments.dart';
import 'package:qonbaq/domain/usecases/update_approval_comment.dart';
import 'package:qonbaq/domain/usecases/delete_approval_comment.dart';
import 'package:qonbaq/domain/usecases/get_approval_templates.dart';
import 'package:qonbaq/domain/usecases/get_approval_template_by_code.dart';
import 'package:qonbaq/domain/usecases/get_pending_confirmations.dart';
import 'package:qonbaq/domain/usecases/confirm_approval.dart';
import 'package:qonbaq/presentation/pages/approval_detail_page.dart';
import 'package:qonbaq/presentation/providers/pending_confirmations_provider.dart';
import 'package:qonbaq/data/datasources/financial_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/financial_repository_impl.dart';
import 'package:qonbaq/domain/repositories/financial_repository.dart';
import 'package:qonbaq/domain/usecases/get_financial_form.dart';
import 'package:qonbaq/data/datasources/inbox_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/inbox_repository_impl.dart';
import 'package:qonbaq/domain/repositories/inbox_repository.dart';
import 'package:qonbaq/domain/usecases/get_inbox_items.dart';
import 'package:qonbaq/domain/usecases/create_inbox_item.dart';
import 'package:qonbaq/domain/usecases/create_inbox_item_from_voice.dart';
import 'package:qonbaq/domain/usecases/update_inbox_item.dart';
import 'package:qonbaq/domain/usecases/delete_inbox_item.dart';
import 'package:qonbaq/data/datasources/transcription_remote_datasource_impl.dart';
import 'package:qonbaq/data/datasources/voice_assist_remote_datasource_impl.dart';
import 'package:qonbaq/core/services/audio_recording_service.dart';
import 'package:qonbaq/data/datasources/service_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/service_repository_impl.dart';
import 'package:qonbaq/domain/repositories/service_repository.dart';
import 'package:qonbaq/data/datasources/resource_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/resource_repository_impl.dart';
import 'package:qonbaq/domain/repositories/resource_repository.dart';
import 'package:qonbaq/data/datasources/time_slot_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/time_slot_repository_impl.dart';
import 'package:qonbaq/domain/repositories/time_slot_repository.dart';
import 'package:qonbaq/domain/entities/service.dart';
import 'package:qonbaq/presentation/pages/services_admin_page.dart';
import 'package:qonbaq/presentation/pages/service_detail_page.dart';
import 'package:qonbaq/domain/usecases/get_income_categories.dart';
import 'package:qonbaq/domain/usecases/create_income.dart';
import 'package:qonbaq/domain/usecases/create_expense.dart';
import 'package:qonbaq/domain/usecases/create_transit.dart';
import 'package:qonbaq/domain/usecases/create_account.dart';
import 'package:qonbaq/domain/usecases/get_financial_report.dart';
import 'package:qonbaq/domain/usecases/get_accounts.dart';
import 'package:qonbaq/presentation/providers/financial_provider.dart';
import 'package:qonbaq/data/datasources/employment_remote_datasource.dart';
import 'package:qonbaq/data/datasources/employment_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/employment_repository_impl.dart';
import 'package:qonbaq/domain/repositories/employment_repository.dart';
import 'package:qonbaq/domain/usecases/get_business_employments_with_roles.dart';
import 'package:qonbaq/domain/usecases/update_employments_roles.dart';
import 'package:qonbaq/presentation/providers/roles_provider.dart';
import 'package:qonbaq/data/datasources/fixed_asset_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/fixed_asset_repository_impl.dart';
import 'package:qonbaq/domain/repositories/fixed_asset_repository.dart';
import 'package:qonbaq/domain/usecases/get_fixed_assets.dart';
import 'package:qonbaq/domain/usecases/get_fixed_asset_by_id.dart';
import 'package:qonbaq/domain/usecases/create_fixed_asset.dart';
import 'package:qonbaq/domain/usecases/update_fixed_asset.dart';
import 'package:qonbaq/domain/usecases/transfer_fixed_asset.dart';
import 'package:qonbaq/domain/usecases/add_repair.dart';
import 'package:qonbaq/domain/usecases/add_inventory.dart';
import 'package:qonbaq/domain/usecases/add_photo.dart';
import 'package:qonbaq/domain/usecases/write_off_fixed_asset.dart';
import 'package:qonbaq/domain/usecases/archive_fixed_asset.dart';
import 'package:intl/date_symbol_data_local.dart';

// Глобальный ключ для навигации (для интерсептора)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Инициализируем данные локали для форматирования дат
  await initializeDateFormatting('ru', null);
  // Загружаем .env файл перед запуском приложения
  await dotenv.load(fileName: '.env');
  // Загружаем конфигурацию маршрутов
  await RoutesConfig.instance.loadRoutes();
  // Инициализируем хранилище токенов
  await TokenStorage.instance.initialize();
  // Инициализируем обработку deep links
  await DeepLinkService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Инициализация зависимостей
    // Сначала создаем базовый ApiClient для auth (без интерсептора, чтобы избежать рекурсии)
    final baseApiClient = ApiClient(baseUrl: AppConstants.apiBaseUrl);
    final authRemoteDataSource = AuthRemoteDataSource(apiClient: baseApiClient);

    // Создаем интерсептор (использует baseApiClient для обновления токена)
    final authInterceptor = AuthInterceptor(
      authDataSource: authRemoteDataSource,
      navigatorKey: navigatorKey,
    );

    // Создаем ApiClient с интерсептором для всех остальных запросов
    final apiClient = ApiClient(
      baseUrl: AppConstants.apiBaseUrl,
      authInterceptor: authInterceptor,
    );

    final AuthRepository authRepository = AuthRepositoryImpl(
      remoteDataSource:
          authRemoteDataSource, // Используем baseApiClient для auth
    );
    final registerUser = RegisterUser(authRepository);
    final loginUser = LoginUser(authRepository);
    final refreshTokenUseCase = RefreshToken(authRepository);
    final authProvider = AuthProvider(
      registerUser: registerUser,
      loginUser: loginUser,
      refreshToken: refreshTokenUseCase,
    );

    // Инициализация зависимостей для профиля
    final userRemoteDataSource = UserRemoteDataSourceImpl(apiClient: apiClient);
    final userLocalDataSource = UserLocalDataSourceImpl();
    final UserRepository userRepository = UserRepositoryImpl(
      remoteDataSource: userRemoteDataSource,
      localDataSource: userLocalDataSource,
    );
    final getUserBusinesses = GetUserBusinesses(userRepository);
    final getUserProfile = GetUserProfile(userRepository);
    final createBusiness = CreateBusiness(userRepository);
    final profileProvider = ProfileProvider(
      getUserBusinesses: getUserBusinesses,
      getUserProfile: getUserProfile,
      createBusiness: createBusiness,
      userRepository: userRepository,
    );

    // Инициализация зависимостей для задач
    final taskRemoteDataSource = TaskRemoteDataSourceImpl(apiClient: apiClient);
    final TaskRepository taskRepository = TaskRepositoryImpl(
      remoteDataSource: taskRemoteDataSource,
    );
    final createTask = CreateTask(taskRepository);
    final getTasks = GetTasks(taskRepository);
    final getTaskById = GetTaskById(taskRepository);
    final updateTask = UpdateTask(taskRepository);
    final createTaskComment = CreateTaskComment(taskRepository);
    final updateTaskComment = UpdateTaskComment(taskRepository);
    final deleteTaskComment = DeleteTaskComment(taskRepository);

    // Инициализация зависимостей для приглашений
    final inviteRemoteDataSource = InviteRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final InviteRepository inviteRepository = InviteRepositoryImpl(
      remoteDataSource: inviteRemoteDataSource,
    );
    final createInvite = CreateInvite(inviteRepository);
    final getCurrentInvite = GetCurrentInvite(inviteRepository);
    final inviteProvider = InviteProvider(
      createInvite: createInvite,
      getCurrentInvite: getCurrentInvite,
    );

    // Инициализация зависимостей для рабочего дня
    final workDayRemoteDataSource = WorkDayRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final WorkDayRepository workDayRepository = WorkDayRepositoryImpl(
      remoteDataSource: workDayRemoteDataSource,
    );
    final startWorkDay = StartWorkDay(workDayRepository);
    final endWorkDay = EndWorkDay(workDayRepository);
    final markAbsent = MarkAbsent(workDayRepository);
    final getWorkDayStatus = GetWorkDayStatus(workDayRepository);
    final getWorkDayStatistics = GetWorkDayStatistics(workDayRepository);

    // Инициализация зависимостей для чатов
    final chatRemoteDataSource = ChatRemoteDataSourceImpl(apiClient: apiClient);
    final chatWebSocketDataSource = ChatWebSocketDataSourceImpl();
    final ChatRepository chatRepository = ChatRepositoryImpl(
      remoteDataSource: chatRemoteDataSource,
      webSocketDataSource: chatWebSocketDataSource,
    );

    // Инициализация зависимостей для подразделений
    final departmentRemoteDataSource = DepartmentRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final DepartmentRepository departmentRepository = DepartmentRepositoryImpl(
      remoteDataSource: departmentRemoteDataSource,
    );
    final getBusinessDepartments = GetBusinessDepartments(departmentRepository);
    final createDepartment = CreateDepartment(departmentRepository);
    final updateDepartment = UpdateDepartment(departmentRepository);
    final deleteDepartment = DeleteDepartment(departmentRepository);
    final setDepartmentManager = SetDepartmentManager(departmentRepository);
    final removeDepartmentManager = RemoveDepartmentManager(
      departmentRepository,
    );
    final assignEmployeeToDepartment = AssignEmployeeToDepartment(
      departmentRepository,
    );
    final removeEmployeeFromDepartment = RemoveEmployeeFromDepartment(
      departmentRepository,
    );
    final assignEmployeesToDepartment = AssignEmployeesToDepartment(
      departmentRepository,
    );
    final departmentProvider = DepartmentProvider(
      getBusinessDepartments: getBusinessDepartments,
      createDepartment: createDepartment,
      updateDepartment: updateDepartment,
      deleteDepartment: deleteDepartment,
      setDepartmentManager: setDepartmentManager,
      removeDepartmentManager: removeDepartmentManager,
      assignEmployeeToDepartment: assignEmployeeToDepartment,
      removeEmployeeFromDepartment: removeEmployeeFromDepartment,
      assignEmployeesToDepartment: assignEmployeesToDepartment,
      departmentRepository: departmentRepository,
    );

    // Инициализация зависимостей для проектов
    final projectRemoteDataSource = ProjectRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final ProjectRepository projectRepository = ProjectRepositoryImpl(
      remoteDataSource: projectRemoteDataSource,
    );
    final getBusinessProjects = GetBusinessProjects(projectRepository);
    final createProject = CreateProject(projectRepository);
    final updateProject = UpdateProject(projectRepository);
    final deleteProject = DeleteProject(projectRepository);
    final projectProvider = ProjectProvider(
      getBusinessProjects: getBusinessProjects,
      createProject: createProject,
      updateProject: updateProject,
      deleteProject: deleteProject,
      projectRepository: projectRepository,
    );

    // Инициализация зависимостей для согласований
    final approvalRemoteDataSource = ApprovalRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final ApprovalRepository approvalRepository = ApprovalRepositoryImpl(
      remoteDataSource: approvalRemoteDataSource,
    );
    final getApprovals = GetApprovals(approvalRepository);
    final getApprovalById = GetApprovalById(approvalRepository);
    final createApproval = CreateApproval(approvalRepository);
    final updateApproval = UpdateApproval(approvalRepository);
    final decideApproval = DecideApproval(approvalRepository);
    final createApprovalComment = CreateApprovalComment(approvalRepository);
    final getApprovalComments = GetApprovalComments(approvalRepository);
    final updateApprovalComment = UpdateApprovalComment(approvalRepository);
    final deleteApprovalComment = DeleteApprovalComment(approvalRepository);
    final getApprovalTemplates = GetApprovalTemplates(approvalRepository);
    final getApprovalTemplateByCode = GetApprovalTemplateByCode(
      approvalRepository,
    );
    final getPendingConfirmations = GetPendingConfirmations(approvalRepository);
    final confirmApproval = ConfirmApproval(approvalRepository);
    final pendingConfirmationsProvider = PendingConfirmationsProvider(
      getPendingConfirmations: getPendingConfirmations,
      confirmApproval: confirmApproval,
    );

    // Инициализация зависимостей для финансовых форм
    final financialRemoteDataSource = FinancialRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final FinancialRepository financialRepository = FinancialRepositoryImpl(
      remoteDataSource: financialRemoteDataSource,
    );
    final getFinancialForm = GetFinancialForm(financialRepository);
    final getIncomeCategories = GetIncomeCategories(financialRepository);
    final createIncome = CreateIncome(financialRepository);
    final createExpense = CreateExpense(financialRepository);
    final createTransit = CreateTransit(financialRepository);
    final createAccount = CreateAccount(financialRepository);
    final getFinancialReport = GetFinancialReport(financialRepository);
    final getAccounts = GetAccounts(financialRepository);
    final financialProvider = FinancialProvider(
      getIncomeCategoriesUseCase: getIncomeCategories,
      createIncomeUseCase: createIncome,
      createExpenseUseCase: createExpense,
      createTransitUseCase: createTransit,
      getFinancialReportUseCase: getFinancialReport,
      getAccountsUseCase: getAccounts,
    );

    // Инициализация зависимостей для Inbox Items
    final inboxRemoteDataSource = InboxRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final InboxRepository inboxRepository = InboxRepositoryImpl(
      remoteDataSource: inboxRemoteDataSource,
    );
    final getInboxItems = GetInboxItems(inboxRepository);
    final createInboxItem = CreateInboxItem(inboxRepository);
    final createInboxItemFromVoice = CreateInboxItemFromVoice(inboxRepository);
    final updateInboxItem = UpdateInboxItem(inboxRepository);
    final deleteInboxItem = DeleteInboxItem(inboxRepository);
    final inboxProvider = InboxProvider(
      getInboxItems: getInboxItems,
      createInboxItem: createInboxItem,
      createInboxItemFromVoice: createInboxItemFromVoice,
      updateInboxItem: updateInboxItem,
      deleteInboxItem: deleteInboxItem,
    );

    // Инициализация зависимостей для записи голоса
    final transcriptionDataSource = TranscriptionRemoteDataSourceImpl();
    final voiceAssistDataSource = VoiceAssistRemoteDataSourceImpl();
    final audioRecordingService = AudioRecordingService(
      transcriptionDataSource,
      voiceAssistDataSource,
    );

    // Инициализация зависимостей для услуг
    final serviceRemoteDataSource = ServiceRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final ServiceRepository serviceRepository = ServiceRepositoryImpl(
      remoteDataSource: serviceRemoteDataSource,
    );

    // Инициализация зависимостей для ресурсов
    final resourceRemoteDataSource = ResourceRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final ResourceRepository resourceRepository = ResourceRepositoryImpl(
      remoteDataSource: resourceRemoteDataSource,
    );

    // Инициализация зависимостей для тайм-слотов
    final timeSlotRemoteDataSource = TimeSlotRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final TimeSlotRepository timeSlotRepository = TimeSlotRepositoryImpl(
      remoteDataSource: timeSlotRemoteDataSource,
    );

    // Инициализация зависимостей для ролей
    final employmentRemoteDataSource = EmploymentRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final EmploymentRepository employmentRepository = EmploymentRepositoryImpl(
      remoteDataSource: employmentRemoteDataSource,
    );
    final getBusinessEmploymentsWithRoles = GetBusinessEmploymentsWithRoles(
      employmentRepository,
    );
    final updateEmploymentsRoles = UpdateEmploymentsRoles(employmentRepository);
    final rolesProvider = RolesProvider(
      getBusinessEmploymentsWithRoles: getBusinessEmploymentsWithRoles,
      updateEmploymentsRoles: updateEmploymentsRoles,
    );

    // Инициализация зависимостей для основных средств
    final fixedAssetRemoteDataSource = FixedAssetRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final FixedAssetRepository fixedAssetRepository = FixedAssetRepositoryImpl(
      remoteDataSource: fixedAssetRemoteDataSource,
    );
    final getFixedAssets = GetFixedAssets(fixedAssetRepository);
    final getFixedAssetById = GetFixedAssetById(fixedAssetRepository);
    final createFixedAsset = CreateFixedAsset(fixedAssetRepository);
    final updateFixedAsset = UpdateFixedAsset(fixedAssetRepository);
    final transferFixedAsset = TransferFixedAsset(fixedAssetRepository);
    final addRepair = AddRepair(fixedAssetRepository);
    final addInventory = AddInventory(fixedAssetRepository);
    final addPhoto = AddPhoto(fixedAssetRepository);
    final writeOffFixedAsset = WriteOffFixedAsset(fixedAssetRepository);
    final archiveFixedAsset = ArchiveFixedAsset(fixedAssetRepository);

    // Инициализация провайдера темы
    final themeProvider = ThemeProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => profileProvider),
        ChangeNotifierProvider(create: (_) => inviteProvider),
        ChangeNotifierProvider(create: (_) => departmentProvider),
        ChangeNotifierProvider(create: (_) => projectProvider),
        ChangeNotifierProvider(create: (_) => inboxProvider),
        ChangeNotifierProvider(create: (_) => financialProvider),
        ChangeNotifierProvider(create: (_) => rolesProvider),
        ChangeNotifierProvider(create: (_) => pendingConfirmationsProvider),
        Provider<CreateTask>(create: (_) => createTask),
        Provider<GetTasks>(create: (_) => getTasks),
        Provider<GetTaskById>(create: (_) => getTaskById),
        Provider<UpdateTask>(create: (_) => updateTask),
        Provider<CreateTaskComment>(create: (_) => createTaskComment),
        Provider<UpdateTaskComment>(create: (_) => updateTaskComment),
        Provider<DeleteTaskComment>(create: (_) => deleteTaskComment),
        Provider<UserRepository>(create: (_) => userRepository),
        Provider<ChatRepository>(create: (_) => chatRepository),
        Provider<StartWorkDay>(create: (_) => startWorkDay),
        Provider<EndWorkDay>(create: (_) => endWorkDay),
        Provider<MarkAbsent>(create: (_) => markAbsent),
        Provider<GetWorkDayStatus>(create: (_) => getWorkDayStatus),
        Provider<GetWorkDayStatistics>(create: (_) => getWorkDayStatistics),
        Provider<GetApprovals>(create: (_) => getApprovals),
        Provider<GetApprovalById>(create: (_) => getApprovalById),
        Provider<CreateApproval>(create: (_) => createApproval),
        Provider<UpdateApproval>(create: (_) => updateApproval),
        Provider<DecideApproval>(create: (_) => decideApproval),
        Provider<CreateApprovalComment>(create: (_) => createApprovalComment),
        Provider<GetApprovalComments>(create: (_) => getApprovalComments),
        Provider<UpdateApprovalComment>(create: (_) => updateApprovalComment),
        Provider<DeleteApprovalComment>(create: (_) => deleteApprovalComment),
        Provider<GetApprovalTemplates>(create: (_) => getApprovalTemplates),
        Provider<GetApprovalTemplateByCode>(
          create: (_) => getApprovalTemplateByCode,
        ),
        Provider<GetFinancialForm>(create: (_) => getFinancialForm),
        Provider<CreateIncome>(create: (_) => createIncome),
        Provider<CreateExpense>(create: (_) => createExpense),
        Provider<CreateTransit>(create: (_) => createTransit),
        Provider<GetFinancialReport>(create: (_) => getFinancialReport),
        Provider<CreateAccount>(create: (_) => createAccount),
        Provider<ServiceRepository>(create: (_) => serviceRepository),
        Provider<ResourceRepository>(create: (_) => resourceRepository),
        Provider<TimeSlotRepository>(create: (_) => timeSlotRepository),
        Provider<FixedAssetRepository>(create: (_) => fixedAssetRepository),
        Provider<GetFixedAssets>(create: (_) => getFixedAssets),
        Provider<GetFixedAssetById>(create: (_) => getFixedAssetById),
        Provider<CreateFixedAsset>(create: (_) => createFixedAsset),
        Provider<UpdateFixedAsset>(create: (_) => updateFixedAsset),
        Provider<TransferFixedAsset>(create: (_) => transferFixedAsset),
        Provider<AddRepair>(create: (_) => addRepair),
        Provider<AddInventory>(create: (_) => addInventory),
        Provider<AddPhoto>(create: (_) => addPhoto),
        Provider<WriteOffFixedAsset>(create: (_) => writeOffFixedAsset),
        Provider<ArchiveFixedAsset>(create: (_) => archiveFixedAsset),
        ChangeNotifierProvider<AudioRecordingService>(
          create: (_) => audioRecordingService,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme.themeData,
            initialRoute: '/',
            routes: {
              // Стартовая страница
              '/': (context) => const StartPage(),
              // Выбор workspace (семья или бизнес)
              '/workspace-selector': (context) => const WorkspaceSelectorPage(),
              // Регистрация с invite кодом (обрабатывает /register?invite=...)
              '/register': (context) => const RegisterPage(),
              // Авторизация
              '/auth': (context) {
                final inviteCode = DeepLinkService.instance.pendingInviteCode;
                return AuthPage(inviteCode: inviteCode);
              },
              '/home': (context) => const HomePage(),
              // Главная бизнес-страница
              '/business': (context) => const BusinessMainPage(),
              // Операционный блок
              '/business/operational':
                  (context) => const OperationalBlockPage(),
              '/business/operational/crm': (context) => const CrmPage(),
              '/business/operational/crm/sales_funnel':
                  (context) => const SalesFunnelPage(),
              '/business/operational/crm/clients_list':
                  (context) => const ClientsListPage(),
              '/business/operational/crm/clients_list/client_card':
                  (context) => const ClientCardPage(),
              '/business/operational/crm/clients_list/client_card/client_requisites':
                  (context) => const ClientRequisitesPage(),
              '/business/operational/crm/clients_list/client_card/client_deal':
                  (context) => const ClientDealPage(),
              '/business/operational/crm/tasks_crm':
                  (context) => const TasksCrmPage(),
              '/business/operational/tasks':
                  (context) => const OperationalTasksPage(),
              '/business/operational/tasks/task_card':
                  (context) => const TaskCardPage(),
              '/business/operational/tasks/task_card/control_points':
                  (context) => const ControlPointsPage(),
              '/business/operational/business_processes':
                  (context) => const BusinessProcessesPage(),
              '/business/operational/construction':
                  (context) => const ConstructionPage(),
              '/business/operational/construction/production':
                  (context) => const ProductionPage(),
              '/business/operational/construction/material_resources':
                  (context) => const MaterialResourcesPage(),
              '/business/operational/construction/human_resources':
                  (context) => const HumanResourcesPage(),
              '/business/operational/monitor_panel':
                  (context) => const MonitorPanelPage(),
              '/business/operational/services-admin':
                  (context) => const ServicesAdminPage(),
              '/business/operational/services-admin/service-detail': (context) {
                final service =
                    ModalRoute.of(context)!.settings.arguments as Service;
                return ServiceDetailPage(service: service);
              },
              // Финансовый блок
              '/business/financial': (context) => const FinancialBlockPage(),
              '/business/financial/payment_requests':
                  (context) => const PaymentRequestsPage(),
              '/business/financial/income_expense':
                  (context) => const IncomeExpensePage(),
              // Административно-хозяйственный блок
              '/business/admin': (context) => const AdminBlockPage(),
              '/business/admin/document_management':
                  (context) => const DocumentManagementPage(),
              '/business/admin/document_management/employee_card':
                  (context) => const EmployeeCardPage(),
              '/business/admin/imprest': (context) => const ImprestPage(),
              '/business/admin/imprest/assets_card':
                  (context) => const AssetsCardPage(),
              '/business/admin/fixed_assets':
                  (context) => const FixedAssetsPage(),
              '/business/admin/fixed_assets/detail': (context) {
                final assetId =
                    ModalRoute.of(context)!.settings.arguments as String?;
                if (assetId == null) {
                  return const Scaffold(
                    body: Center(
                      child: Text('ID основного средства не указан'),
                    ),
                  );
                }
                return FixedAssetDetailPage(assetId: assetId);
              },
              '/business/admin/hr_documents':
                  (context) => const HrDocumentsPage(),
              '/business/admin/staff_schedule':
                  (context) => const StaffSchedulePage(),
              '/business/admin/timesheet': (context) => const TimesheetPage(),
              // Аналитический блок
              '/business/analytics': (context) => const AnalyticsBlockPage(),
              // Общие разделы
              '/start_work_day': (context) => const StartWorkDayPage(),
              '/chats_email': (context) => const ChatsEmailPage(),
              '/calendar': (context) => const CalendarPage(),
              '/profile_settings': (context) => const ProfileSettingsPage(),
              '/organizational_structure':
                  (context) => const OrganizationalStructurePage(),
              '/department_detail': (context) {
                final departmentId =
                    ModalRoute.of(context)!.settings.arguments as String?;
                if (departmentId == null) {
                  return const Scaffold(
                    body: Center(child: Text('ID подразделения не указан')),
                  );
                }
                return DepartmentDetailPage(departmentId: departmentId);
              },
              '/tasks': (context) => const TasksPage(),
              '/tasks/detail': (context) {
                final taskId =
                    ModalRoute.of(context)!.settings.arguments as String?;
                if (taskId == null) {
                  return const Scaffold(
                    body: Center(child: Text('ID задачи не указан')),
                  );
                }
                return TaskDetailPage(taskId: taskId);
              },
              '/approvals': (context) => const ApprovalsPage(),
              '/roles-assignment': (context) => const RolesAssignmentPage(),
              '/approvals/detail': (context) {
                final approvalId =
                    ModalRoute.of(context)!.settings.arguments as String?;
                if (approvalId == null) {
                  return const Scaffold(
                    body: Center(child: Text('ID согласования не указан')),
                  );
                }
                return ApprovalDetailPage(approvalId: approvalId);
              },
              '/remember': (context) => const RememberPage(),
              '/favorites': (context) => const FavoritesPage(),
            },
          );
        },
      ),
    );
  }
}

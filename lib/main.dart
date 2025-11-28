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
import 'package:qonbaq/presentation/pages/auth_page.dart';
import 'package:qonbaq/presentation/pages/home_page.dart';
import 'package:qonbaq/presentation/pages/start_page.dart';
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
import 'package:qonbaq/presentation/pages/hr_documents_page.dart';
import 'package:qonbaq/presentation/pages/staff_schedule_page.dart';
import 'package:qonbaq/presentation/pages/start_work_day_page.dart';
import 'package:qonbaq/presentation/pages/chats_email_page.dart';
import 'package:qonbaq/presentation/pages/calendar_page.dart';
import 'package:qonbaq/presentation/pages/profile_settings_page.dart';
import 'package:qonbaq/presentation/pages/tasks_page.dart';
import 'package:qonbaq/presentation/pages/approvals_page.dart';
import 'package:qonbaq/presentation/pages/remember_page.dart';
import 'package:qonbaq/presentation/pages/favorites_page.dart';
import 'package:qonbaq/presentation/providers/auth_provider.dart';
import 'package:qonbaq/presentation/providers/profile_provider.dart';
import 'package:qonbaq/data/datasources/user_remote_datasource_impl.dart';
import 'package:qonbaq/data/datasources/user_local_datasource_impl.dart';
import 'package:qonbaq/data/repositories/user_repository_impl.dart';
import 'package:qonbaq/domain/repositories/user_repository.dart';
import 'package:qonbaq/domain/usecases/get_user_businesses.dart';
import 'package:qonbaq/domain/usecases/get_user_profile.dart';
import 'package:qonbaq/data/datasources/task_remote_datasource_impl.dart';
import 'package:qonbaq/data/repositories/task_repository_impl.dart';
import 'package:qonbaq/domain/repositories/task_repository.dart';
import 'package:qonbaq/domain/usecases/create_task.dart';
import 'package:qonbaq/domain/usecases/get_tasks.dart';
import 'package:qonbaq/core/utils/token_storage.dart';
import 'package:qonbaq/core/utils/auth_interceptor.dart';

// Глобальный ключ для навигации (для интерсептора)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Загружаем .env файл перед запуском приложения
  await dotenv.load(fileName: '.env');
  // Загружаем конфигурацию маршрутов
  await RoutesConfig.instance.loadRoutes();
  // Инициализируем хранилище токенов
  await TokenStorage.instance.initialize();
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
      remoteDataSource: authRemoteDataSource, // Используем baseApiClient для auth
    );
    final registerUser = RegisterUser(authRepository);
    final loginUser = LoginUser(authRepository);
    final authProvider = AuthProvider(
      registerUser: registerUser,
      loginUser: loginUser,
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
    final profileProvider = ProfileProvider(
      getUserBusinesses: getUserBusinesses,
      getUserProfile: getUserProfile,
      userRepository: userRepository,
    );

    // Инициализация зависимостей для задач
    final taskRemoteDataSource = TaskRemoteDataSourceImpl(apiClient: apiClient);
    final TaskRepository taskRepository = TaskRepositoryImpl(
      remoteDataSource: taskRemoteDataSource,
    );
    final createTask = CreateTask(taskRepository);
    final getTasks = GetTasks(taskRepository);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => profileProvider),
        Provider<CreateTask>(create: (_) => createTask),
        Provider<GetTasks>(create: (_) => getTasks),
        Provider<UserRepository>(create: (_) => userRepository),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          // Стартовая страница
          '/': (context) => const StartPage(),
          // Авторизация
          '/auth': (context) => const AuthPage(),
          '/home': (context) => const HomePage(),
          // Главная бизнес-страница
          '/business': (context) => const BusinessMainPage(),
          // Операционный блок
          '/business/operational': (context) => const OperationalBlockPage(),
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
          '/business/admin/hr_documents': (context) => const HrDocumentsPage(),
          '/business/admin/staff_schedule':
              (context) => const StaffSchedulePage(),
          // Аналитический блок
          '/business/analytics': (context) => const AnalyticsBlockPage(),
          // Общие разделы
          '/start_work_day': (context) => const StartWorkDayPage(),
          '/chats_email': (context) => const ChatsEmailPage(),
          '/calendar': (context) => const CalendarPage(),
          '/profile_settings': (context) => const ProfileSettingsPage(),
          '/tasks': (context) => const TasksPage(),
          '/approvals': (context) => const ApprovalsPage(),
          '/remember': (context) => const RememberPage(),
          '/favorites': (context) => const FavoritesPage(),
        },
      ),
    );
  }
}

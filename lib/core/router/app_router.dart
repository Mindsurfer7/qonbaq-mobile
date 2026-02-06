import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/layouts/adaptive_app_shell.dart';
import '../../presentation/pages/start_page.dart';
import '../../presentation/pages/welcome_page.dart';
import '../../presentation/pages/auth_page.dart';
import '../../presentation/pages/workspace_selector_page.dart';
import '../../presentation/pages/business_main_page.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/profile_settings_page.dart';
import '../../presentation/pages/operational_block_page.dart';
import '../../presentation/pages/crm_page.dart';
import '../../presentation/pages/sales_funnel_page.dart';
import '../../presentation/pages/orders_funnel_page.dart';
import '../../presentation/pages/clients_list_page.dart';
import '../../presentation/pages/client_card_page.dart';
import '../../presentation/pages/customer_detail_page.dart';
import '../../presentation/pages/tasks_crm_page.dart';
import '../../presentation/pages/operational_tasks_page.dart';
import '../../presentation/pages/task_detail_page.dart';
import '../../presentation/pages/task_card_page.dart';
import '../../presentation/pages/business_processes_page.dart';
import '../../presentation/pages/construction_page.dart';
import '../../presentation/pages/services_admin_page.dart';
import '../../presentation/pages/financial_block_page.dart';
import '../../presentation/pages/payment_requests_page.dart';
import '../../presentation/pages/income_expense_page.dart';
import '../../presentation/pages/admin_block_page.dart';
import '../../presentation/pages/document_management_page.dart';
import '../../presentation/pages/fixed_assets_page.dart';
import '../../presentation/pages/fixed_asset_detail_page.dart';
import '../../presentation/pages/hr_documents_page.dart';
import '../../presentation/pages/staff_schedule_page.dart';
import '../../presentation/pages/timesheet_page.dart';
import '../../presentation/pages/analytics_block_page.dart';
import '../../presentation/pages/approvals_page.dart';
import '../../presentation/pages/remember_page.dart';
import '../../presentation/pages/favorites_page.dart';
import '../../presentation/pages/chats_email_page.dart';
import '../../presentation/pages/calendar_page.dart';
import '../../presentation/pages/organizational_structure_page.dart';
import '../../presentation/pages/department_detail_page.dart';
import '../../presentation/pages/roles_assignment_page.dart';
import '../../presentation/pages/control_points_page.dart';
import '../../presentation/pages/control_point_detail_page.dart';
import '../../core/utils/responsive_utils.dart';

/// Конфигурация router для приложения
class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,

      // Redirect для аутентификации
      // ВАЖНО: StartPage сама делает проверку токенов и редиректы,
      // поэтому здесь только базовая защита для прямых переходов
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isLoggedIn = authProvider.isAuthenticated;
        final location = state.matchedLocation;
        final uriPath = state.uri.path;

        debugPrint('🔄 [Router] Глобальный redirect вызван');
        debugPrint('   matchedLocation: $location');
        debugPrint('   uri.path: $uriPath');
        debugPrint('   isLoggedIn: $isLoggedIn');

        // Публичные страницы - без редиректов
        final publicPages = ['/', '/auth', '/welcome', '/workspace-selector'];
        final isPublicPage = publicPages.contains(location);

        // Если залогинен и идет на welcome → на business
        if (isLoggedIn && location == '/welcome') {
          debugPrint('   → Редирект на /business (welcome → business)');
          return '/business';
        }

        // Если не залогинен и идет на защищенную страницу → на start page
        // StartPage сама разберется куда редиректить
        if (!isLoggedIn && !isPublicPage) {
          debugPrint('   → Редирект на / (не залогинен)');
          return '/';
        }

        debugPrint('   → Редирект не нужен, разрешаем переход');
        return null; // Разрешить переход
      },

      routes: [
        // Публичные routes (без shell)
        GoRoute(path: '/', builder: (context, state) => const StartPage()),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomePage(),
        ),
        GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
        GoRoute(
          path: '/workspace-selector',
          builder: (context, state) => const WorkspaceSelectorPage(),
        ),

        // ShellRoute для приложения со статичными панелями
        ShellRoute(
          builder: (context, state, child) {
            // Используем uri.path вместо matchedLocation для полного пути
            final fullPath = state.uri.path;
            debugPrint('🛤️ [ShellRoute] builder вызван');
            debugPrint('   matchedLocation: ${state.matchedLocation}');
            debugPrint('   uri.path: $fullPath');
            debugPrint('   uri.queryParameters: ${state.uri.queryParameters}');
            debugPrint('   child widget type: ${child.runtimeType}');
            // Key обеспечивает перестроение при смене route
            return AdaptiveAppShell(
              key: ValueKey(fullPath),
              currentRoute: fullPath,
              child: child,
            );
          },
          routes: [
            // Business Main
            GoRoute(
              path: '/business',
              redirect: (context, state) {
                // На desktop сразу в первую страницу операционного блока
                if (context.isDesktop) {
                  return '/business/operational/crm';
                }
                return null;
              },
              builder: (context, state) => const BusinessMainPage(),
            ),

            // Home
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),

            // Профиль
            GoRoute(
              path: '/profile_settings',
              builder: (context, state) => const ProfileSettingsPage(),
            ),

            // Операционный блок
            GoRoute(
              path: '/business/operational',
              redirect: (context, state) {
                // На desktop редирект на CRM, на mobile показываем 4 блока
                debugPrint('🔄 [Router] Redirect для /business/operational');
                debugPrint('   matchedLocation: ${state.matchedLocation}');
                debugPrint('   uri.path: ${state.uri.path}');
                debugPrint('   isDesktop: ${context.isDesktop}');
                // ВАЖНО: Проверяем uri.path, а не matchedLocation!
                // matchedLocation всегда /business/operational для всех вложенных маршрутов
                if (state.uri.path == '/business/operational' &&
                    context.isDesktop) {
                  debugPrint('   → Редирект на /business/operational/crm');
                  return '/business/operational/crm';
                }
                debugPrint('   → Редирект не нужен, возвращаем null');
                return null;
              },
              builder: (context, state) {
                debugPrint('🏗️ [Router] Builder для /business/operational');
                debugPrint('   matchedLocation: ${state.matchedLocation}');
                debugPrint('   uri.path: ${state.uri.path}');
                return const OperationalBlockPage();
              },
              routes: [
                // CRM
                GoRoute(
                  path: 'crm',
                  builder: (context, state) => const CrmPage(),
                  routes: [
                    GoRoute(
                      path: 'sales_funnel',
                      builder: (context, state) => const SalesFunnelPage(),
                    ),
                    GoRoute(
                      path: 'orders_funnel',
                      builder: (context, state) => const OrdersFunnelPage(),
                    ),
                    GoRoute(
                      path: 'clients',
                      builder: (context, state) => const ClientsListPage(),
                    ),
                    GoRoute(
                      path: 'customer_tasks',
                      builder: (context, state) => const TasksCrmPage(),
                    ),
                  ],
                ),

                // Client card (заглушка без параметров)
                GoRoute(
                  path: 'client_card',
                  builder: (context, state) => const ClientCardPage(),
                ),

                // Customer detail
                GoRoute(
                  path: 'customer/:customerId',
                  builder: (context, state) {
                    final customerId = state.pathParameters['customerId']!;
                    return CustomerDetailPage(customerId: customerId);
                  },
                ),

                // Tasks
                GoRoute(
                  path: 'tasks',
                  builder: (context, state) {
                    debugPrint(
                      '🏗️ [Router] Builder для /business/operational/tasks',
                    );
                    debugPrint('   matchedLocation: ${state.matchedLocation}');
                    debugPrint('   uri.path: ${state.uri.path}');
                    return const OperationalTasksPage();
                  },
                ),

                // Task detail
                GoRoute(
                  path: 'task/:taskId',
                  builder: (context, state) {
                    final taskId = state.pathParameters['taskId']!;
                    return TaskDetailPage(taskId: taskId);
                  },
                ),

                // Task card (заглушка без параметров)
                GoRoute(
                  path: 'task_card',
                  builder: (context, state) => const TaskCardPage(),
                ),

                // Business processes
                GoRoute(
                  path: 'business_processes',
                  builder: (context, state) {
                    debugPrint(
                      '🏗️ [Router] Builder для /business/operational/business_processes',
                    );
                    debugPrint('   matchedLocation: ${state.matchedLocation}');
                    debugPrint('   uri.path: ${state.uri.path}');
                    return const BusinessProcessesPage();
                  },
                ),

                // Construction
                GoRoute(
                  path: 'construction',
                  builder: (context, state) => const ConstructionPage(),
                ),

                // Trade (заглушка)
                GoRoute(
                  path: 'trade',
                  builder:
                      (context, state) => const Scaffold(
                        body: Center(child: Text('Торговля - в разработке')),
                      ),
                ),

                // Logistics (заглушка)
                GoRoute(
                  path: 'logistics',
                  builder:
                      (context, state) => const Scaffold(
                        body: Center(child: Text('Логистика - в разработке')),
                      ),
                ),

                // Services (заглушка)
                GoRoute(
                  path: 'services',
                  builder:
                      (context, state) => const Scaffold(
                        body: Center(child: Text('Сфера услуг - в разработке')),
                      ),
                ),

                // Services Admin
                GoRoute(
                  path: 'services-admin',
                  builder: (context, state) {
                    debugPrint(
                      '🏗️ [Router] Builder для /business/operational/services-admin',
                    );
                    debugPrint('   matchedLocation: ${state.matchedLocation}');
                    debugPrint('   uri.path: ${state.uri.path}');
                    return const ServicesAdminPage();
                  },
                ),

                // Control Points
                GoRoute(
                  path: 'control_points',
                  builder: (context, state) => const ControlPointsPage(),
                ),

                // Control Point Detail
                GoRoute(
                  path: 'control_point/:controlPointId',
                  builder: (context, state) {
                    final controlPointId =
                        state.pathParameters['controlPointId']!;
                    return ControlPointDetailPage(
                      controlPointId: controlPointId,
                    );
                  },
                ),
              ],
            ),

            // Финансовый блок
            GoRoute(
              path: '/business/financial',
              redirect: (context, state) {
                if (state.matchedLocation == '/business/financial') {
                  return '/business/financial/payment_requests';
                }
                return null;
              },
              builder: (context, state) => const FinancialBlockPage(),
              routes: [
                GoRoute(
                  path: 'payment_requests',
                  builder: (context, state) => const PaymentRequestsPage(),
                ),
                GoRoute(
                  path: 'income_expense',
                  builder: (context, state) => const IncomeExpensePage(),
                ),
              ],
            ),

            // Админ-хоз блок
            GoRoute(
              path: '/business/admin',
              redirect: (context, state) {
                if (state.matchedLocation == '/business/admin') {
                  return '/business/admin/document_management';
                }
                return null;
              },
              builder: (context, state) => const AdminBlockPage(),
              routes: [
                GoRoute(
                  path: 'document_management',
                  builder: (context, state) => const DocumentManagementPage(),
                ),
                GoRoute(
                  path: 'fixed_assets',
                  builder: (context, state) => const FixedAssetsPage(),
                ),
                GoRoute(
                  path: 'fixed_asset/:assetId',
                  builder: (context, state) {
                    final assetId = state.pathParameters['assetId']!;
                    return FixedAssetDetailPage(assetId: assetId);
                  },
                ),
                GoRoute(
                  path: 'hr_documents',
                  builder: (context, state) => const HrDocumentsPage(),
                ),
                GoRoute(
                  path: 'staff_schedule',
                  builder: (context, state) => const StaffSchedulePage(),
                ),
                GoRoute(
                  path: 'timesheet',
                  builder: (context, state) => const TimesheetPage(),
                ),
              ],
            ),

            // Аналитика
            GoRoute(
              path: '/business/analytics',
              builder: (context, state) => const AnalyticsBlockPage(),
            ),

            // Quick actions (доступны везде)
            GoRoute(
              path: '/approvals',
              builder: (context, state) => const ApprovalsPage(),
            ),
            GoRoute(
              path: '/remember',
              builder: (context, state) => const RememberPage(),
            ),
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const FavoritesPage(),
            ),
            GoRoute(
              path: '/chats_email',
              builder: (context, state) => const ChatsEmailPage(),
            ),
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarPage(),
            ),

            // Организационная структура
            GoRoute(
              path: '/organizational_structure',
              builder: (context, state) => const OrganizationalStructurePage(),
            ),
            GoRoute(
              path: '/department_detail/:departmentId',
              builder: (context, state) {
                final departmentId = state.pathParameters['departmentId']!;
                return DepartmentDetailPage(departmentId: departmentId);
              },
            ),

            // Roles assignment
            GoRoute(
              path: '/roles-assignment',
              builder: (context, state) => const RolesAssignmentPage(),
            ),
          ],
        ),
      ],

      // Обработка ошибок 404
      errorBuilder: (context, state) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Страница не найдена',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.matchedLocation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/business'),
                  child: const Text('На главную'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

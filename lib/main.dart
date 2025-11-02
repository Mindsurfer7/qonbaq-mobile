import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qonbaq/core/utils/api_client.dart';
import 'package:qonbaq/core/utils/constants.dart';
import 'package:qonbaq/data/datasources/auth_remote_datasource.dart';
import 'package:qonbaq/data/repositories/auth_repository_impl.dart';
import 'package:qonbaq/domain/repositories/auth_repository.dart';
import 'package:qonbaq/domain/usecases/login_user.dart';
import 'package:qonbaq/domain/usecases/register_user.dart';
import 'package:qonbaq/presentation/pages/auth_page.dart';
import 'package:qonbaq/presentation/pages/home_page.dart';
import 'package:qonbaq/presentation/providers/auth_provider.dart';

Future<void> main() async {
  // Загружаем .env файл перед запуском приложения
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Инициализация зависимостей
    final apiClient = ApiClient(baseUrl: AppConstants.apiBaseUrl);
    final authRemoteDataSource = AuthRemoteDataSource(apiClient: apiClient);
    final AuthRepository authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
    );
    final registerUser = RegisterUser(authRepository);
    final loginUser = LoginUser(authRepository);
    final authProvider = AuthProvider(
      registerUser: registerUser,
      loginUser: loginUser,
    );

    return ChangeNotifierProvider(
      create: (_) => authProvider,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/auth',
        routes: {
          '/auth': (context) => const AuthPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}

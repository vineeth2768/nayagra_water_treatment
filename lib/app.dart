import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'repositories/auth_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/service_repository.dart';
import 'repositories/dashboard_repository.dart';
import 'controllers/auth_controller.dart';
import 'controllers/customer_controller.dart';
import 'controllers/service_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'providers/auth_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/service_provider.dart';
import 'providers/dashboard_provider.dart';
import 'routes/app_router.dart';

class NayagraCrmApp extends StatefulWidget {
  final AuthRepository authRepository;
  final CustomerRepository customerRepository;
  final ServiceRepository serviceRepository;
  final DashboardRepository dashboardRepository;

  const NayagraCrmApp({
    super.key,
    required this.authRepository,
    required this.customerRepository,
    required this.serviceRepository,
    required this.dashboardRepository,
  });

  @override
  State<NayagraCrmApp> createState() => _NayagraCrmAppState();
}

class _NayagraCrmAppState extends State<NayagraCrmApp> {
  late final AuthController _authController;
  late final CustomerController _customerController;
  late final ServiceController _serviceController;
  late final DashboardController _dashboardController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(repository: widget.authRepository);
    _customerController = CustomerController(
      customerRepository: widget.customerRepository,
      serviceRepository: widget.serviceRepository,
    );
    _serviceController = ServiceController(serviceRepository: widget.serviceRepository);
    _dashboardController = DashboardController(repository: widget.dashboardRepository);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(controller: _authController),
        ),
        ChangeNotifierProvider<CustomerProvider>(
          create: (_) => CustomerProvider(controller: _customerController),
        ),
        ChangeNotifierProvider<ServiceProvider>(
          create: (_) => ServiceProvider(controller: _serviceController),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(controller: _dashboardController),
        ),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();
          final router = AppRouter.createRouter(authProvider);

          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}


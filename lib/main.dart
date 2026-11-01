import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'repositories/auth_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/service_repository.dart';
import 'repositories/dashboard_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase successfully initialized for Nayagra Water CRM.');
  } catch (e) {
    debugPrint('Firebase initializeApp caught: $e. Running in standalone resilient mode.');
  }

  // Initialize repositories
  final authRepository = AuthRepository();
  final customerRepository = CustomerRepository();
  final serviceRepository = ServiceRepository(customerRepository: customerRepository);
  final dashboardRepository = DashboardRepository(
    customerRepository: customerRepository,
    serviceRepository: serviceRepository,
  );

  runApp(
    NayagraCrmApp(
      authRepository: authRepository,
      customerRepository: customerRepository,
      serviceRepository: serviceRepository,
      dashboardRepository: dashboardRepository,
    ),
  );
}

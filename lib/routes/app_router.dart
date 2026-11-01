import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../views/auth/login_view.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/customers/customer_list_view.dart';
import '../views/customers/add_customer_view.dart';
import '../views/customers/edit_customer_view.dart';
import '../views/customers/customer_details_view.dart';
import '../views/services/upcoming_services_view.dart';
import '../views/services/completed_services_view.dart';
import '../views/services/service_history_view.dart';
import '../views/settings/settings_view.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: RouteNames.dashboard,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == RouteNames.login;

        if (!isAuthenticated && !isLoggingIn) {
          return RouteNames.login;
        }

        if (isAuthenticated && isLoggingIn) {
          return RouteNames.dashboard;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouteNames.login,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const LoginView(),
          ),
        ),
        GoRoute(
          path: RouteNames.dashboard,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const DashboardView(),
          ),
        ),
        GoRoute(
          path: RouteNames.customers,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const CustomerListView(),
          ),
          routes: [
            GoRoute(
              path: 'add',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: const AddCustomerView(),
              ),
            ),
            GoRoute(
              path: ':id/edit',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return NoTransitionPage<void>(
                  key: state.pageKey,
                  child: EditCustomerView(customerId: id),
                );
              },
            ),
            GoRoute(
              path: ':id',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return NoTransitionPage<void>(
                  key: state.pageKey,
                  child: CustomerDetailsView(customerId: id),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: RouteNames.upcomingServices,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const UpcomingServicesView(),
          ),
        ),
        GoRoute(
          path: RouteNames.completedServices,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const CompletedServicesView(),
          ),
        ),
        GoRoute(
          path: RouteNames.serviceHistory,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const ServiceHistoryView(),
          ),
        ),
        GoRoute(
          path: RouteNames.settings,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const SettingsView(),
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('404 - Page Not Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.dashboard),
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

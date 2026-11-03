import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../routes/route_names.dart';
import '../providers/auth_provider.dart';
import 'confirmation_dialog.dart';

class AppSidebar extends StatelessWidget {
  final String currentRoute;

  const AppSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Container(
      width: 250,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/logo_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NAYAGRA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'WATER TREATMENT PLANTS',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1B4063), height: 1),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                _buildNavItem(
                  context,
                  title: AppStrings.dashboard,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  route: RouteNames.dashboard,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  title: AppStrings.customers,
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  route: RouteNames.customers,
                  exactMatch: false,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  title: AppStrings.addCustomer,
                  icon: Icons.person_add_outlined,
                  activeIcon: Icons.person_add_rounded,
                  route: RouteNames.addCustomer,
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    'SERVICES MANAGEMENT',
                    style: TextStyle(
                      color: Color(0xFF6B8BAA),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  title: AppStrings.upcomingServices,
                  icon: Icons.pending_actions_outlined,
                  activeIcon: Icons.pending_actions_rounded,
                  route: RouteNames.upcomingServices,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  title: AppStrings.completedServices,
                  icon: Icons.task_alt_outlined,
                  activeIcon: Icons.task_alt_rounded,
                  route: RouteNames.completedServices,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  title: AppStrings.serviceHistory,
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history_rounded,
                  route: RouteNames.serviceHistory,
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    'SYSTEM',
                    style: TextStyle(
                      color: Color(0xFF6B8BAA),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  title: AppStrings.settings,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  route: RouteNames.settings,
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1B4063), height: 1),

          // User Profile & Logout section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.secondary,
                  child: Text(
                    (user?.displayName.isNotEmpty ?? false)
                        ? user!.displayName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.displayName ?? 'Administrator',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.email ?? 'admin@nayagra.com',
                        style: const TextStyle(
                          color: Color(0xFF8AA8C4),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF8AA8C4), size: 18),
                  onPressed: () async {
                    final confirm = await ConfirmationDialog.show(
                      context,
                      title: 'Logout',
                      message: 'Are you sure you want to log out of Nayagra Water CRM?',
                      confirmText: 'Logout',
                      isDestructive: true,
                    );
                    if (confirm == true && context.mounted) {
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go(RouteNames.login);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required IconData activeIcon,
    required String route,
    bool exactMatch = true,
  }) {
    final bool isActive = exactMatch
        ? currentRoute == route
        : currentRoute.startsWith(route);

    return InkWell(
      onTap: () {
        if (!isActive) {
          context.go(route);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E466F) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive ? AppColors.secondary : const Color(0xFF90ADC9),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFFD4E2F0),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isActive)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


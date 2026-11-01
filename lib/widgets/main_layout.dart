import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import 'app_sidebar.dart';
import 'app_header.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final String? subtitle;
  final List<Widget>? headerActions;

  const MainLayout({
    super.key,
    required this.child,
    required this.title,
    this.subtitle,
    this.headerActions,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 900;
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isSmallScreen
          ? Drawer(
              child: AppSidebar(currentRoute: currentRoute),
            )
          : null,
      body: Row(
        children: [
          if (!isSmallScreen) AppSidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  title: title,
                  subtitle: subtitle,
                  actions: headerActions,
                  onMenuPressed: isSmallScreen
                      ? () {
                          Scaffold.of(context).openDrawer();
                        }
                      : null,
                ),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


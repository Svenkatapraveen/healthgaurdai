import 'package:flutter/material.dart';
import 'app_sidebar.dart';
import 'app_topbar.dart';
import 'background_painter.dart';

class AppLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final UserRole role;
  final String currentRoute;
  final Widget body;
  final List<Widget>? topbarActions;
  final Widget? floatingActionButton;

  const AppLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.role,
    required this.currentRoute,
    required this.body,
    this.topbarActions,
    this.floatingActionButton,
  });

  static void safeNavigate(BuildContext context, String targetRoute, String currentRoute) {
    if (targetRoute == currentRoute) {
      return;
    }

    final cleanTarget = targetRoute.split('?')[0];

    final isTopLevel = cleanTarget == '/dashboard' ||
        cleanTarget == '/assessment' ||
        cleanTarget == '/my-appointments' ||
        cleanTarget == '/report' ||
        cleanTarget == '/notifications' ||
        cleanTarget == '/profile' ||
        cleanTarget == '/admin-dashboard' ||
        cleanTarget == '/doctor-dashboard' ||
        cleanTarget == '/welcome';

    if (isTopLevel) {
      Navigator.of(context).pushReplacementNamed(targetRoute);
    } else {
      Navigator.of(context).pushNamed(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return BackgroundPainter(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: !isDesktop
            ? Drawer(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: AppSidebar(
                  role: role,
                  currentRoute: currentRoute,
                  onNavigate: (route) {
                    Navigator.of(context).pop();
                    safeNavigate(context, route, currentRoute);
                  },
                ),
              )
            : null,
        body: Row(
          children: [
            if (isDesktop)
              AppSidebar(
                role: role,
                currentRoute: currentRoute,
                onNavigate: (route) {
                  safeNavigate(context, route, currentRoute);
                },
              ),
            Expanded(
              child: Column(
                children: [
                  AppTopbar(
                    title: title,
                    subtitle: subtitle,
                    actions: topbarActions,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1300),
                          child: body,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}


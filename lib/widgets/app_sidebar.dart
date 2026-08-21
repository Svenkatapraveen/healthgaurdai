import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../state/app_state.dart';
import 'app_layout.dart';

enum UserRole { patient, admin }

class SidebarNavItem {
  final String label;
  final IconData icon;
  final String route;
  final String id;

  SidebarNavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.id,
  });
}

class AppSidebar extends StatelessWidget {
  final UserRole role;
  final String currentRoute;
  final Function(String route)? onNavigate;

  const AppSidebar({
    super.key,
    required this.role,
    required this.currentRoute,
    this.onNavigate,
  });

  List<SidebarNavItem> _getNavItems() {
    switch (role) {
      case UserRole.admin:
        return [
          SidebarNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/admin-dashboard', id: 'dashboard'),
          SidebarNavItem(label: 'Appointments', icon: Icons.calendar_month_outlined, route: '/admin-dashboard?tab=appointments', id: 'appointments'),
          SidebarNavItem(label: 'Patients', icon: Icons.people_outline, route: '/admin-dashboard?tab=patients', id: 'patients'),
          SidebarNavItem(label: 'Doctors', icon: Icons.medical_services_outlined, route: '/admin-dashboard?tab=doctors', id: 'doctors'),
          SidebarNavItem(label: 'Reports', icon: Icons.description_outlined, route: '/admin-dashboard?tab=reports', id: 'reports'),
          SidebarNavItem(label: 'Notifications', icon: Icons.notifications_outlined, route: '/notifications', id: 'notifications'),
          SidebarNavItem(label: 'Profile', icon: Icons.person_outline, route: '/profile', id: 'profile'),
        ];
      case UserRole.patient:
        return [
          SidebarNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/dashboard', id: 'dashboard'),
          SidebarNavItem(label: 'Health Assessment', icon: Icons.assignment_outlined, route: '/assessment', id: 'assessment'),
          SidebarNavItem(label: 'Appointments', icon: Icons.calendar_month_outlined, route: '/my-appointments', id: 'appointments'),
          SidebarNavItem(label: 'Reports', icon: Icons.description_outlined, route: '/dashboard?tab=reports', id: 'reports'),
          SidebarNavItem(label: 'Notifications', icon: Icons.notifications_outlined, route: '/notifications', id: 'notifications'),
          SidebarNavItem(label: 'Profile', icon: Icons.person_outline, route: '/profile', id: 'profile'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final navItems = _getNavItems();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            color: isDark ? const Color(0x9E0F172A) : const Color(0x9EFFFFFF),
            border: Border(
              right: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xBFFFFFFF),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Branding Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'HealthGuard AI',
                            style: TextStyle(
                              color: AppColors.getTextPrimary(isDark),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            role == UserRole.admin
                                ? 'Admin Workspace'
                                : 'Patient Portal',
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDark),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
              const SizedBox(height: 12),

              // Nav Items List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: navItems.length,
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    final bool isActive = currentRoute == item.route ||
                        (item.route.contains('?')
                            ? currentRoute == item.route
                            : (currentRoute.split('?')[0] == item.route.split('?')[0]));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: isActive
                            ? (isDark ? AppColors.primaryTeal.withValues(alpha: 0.2) : AppColors.primaryBlue.withValues(alpha: 0.12))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            if (onNavigate != null) {
                              onNavigate!(item.route);
                            } else {
                              AppLayout.safeNavigate(context, item.route, currentRoute);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 18,
                                  color: isActive
                                      ? (isDark ? AppColors.primaryTeal : AppColors.primaryBlue)
                                      : AppColors.getTextSecondary(isDark),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                      color: isActive
                                          ? AppColors.getTextPrimary(isDark)
                                          : AppColors.getTextSecondary(isDark),
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.primaryTeal : AppColors.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // User info & Logout at bottom
              Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryBlue,
                      child: Text(
                        (state.currentUser?.fullName ?? 'User')
                            .trim()
                            .isEmpty
                            ? 'U'
                            : (state.currentUser?.fullName ?? 'User')
                                .trim()
                                .characters
                                .first
                                .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role == UserRole.admin
                                ? 'Administrator'
                                : (state.currentUser?.fullName ?? 'Patient'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.getTextPrimary(isDark),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            role == UserRole.admin
                                ? 'System Operations'
                                : (state.currentUser?.email ?? 'patient@healthguard.ai'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDark),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.logout, size: 18, color: AppColors.getTextSecondary(isDark)),
                      tooltip: 'Logout',
                      onPressed: () {
                        state.logout();
                        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


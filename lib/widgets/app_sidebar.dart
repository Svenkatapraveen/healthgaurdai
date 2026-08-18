import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../state/app_state.dart';
import 'app_layout.dart';

enum UserRole { patient, doctor, admin }

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
      case UserRole.doctor:
        return [
          SidebarNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/doctor-dashboard', id: 'dashboard'),
          SidebarNavItem(label: "Today's Schedule", icon: Icons.today_outlined, route: '/doctor-dashboard?tab=schedule', id: 'schedule'),
          SidebarNavItem(label: 'Appointments', icon: Icons.calendar_month_outlined, route: '/doctor-dashboard?tab=appointments', id: 'appointments'),
          SidebarNavItem(label: 'My Patients', icon: Icons.people_outline, route: '/doctor-dashboard?tab=patients', id: 'patients'),
          SidebarNavItem(label: 'Medical Reports', icon: Icons.description_outlined, route: '/doctor-dashboard?tab=reports', id: 'reports'),
          SidebarNavItem(label: 'Consultations', icon: Icons.medical_information_outlined, route: '/doctor-dashboard?tab=consultations', id: 'consultations'),
          SidebarNavItem(label: 'Notifications', icon: Icons.notifications_outlined, route: '/notifications', id: 'notifications'),
          SidebarNavItem(label: 'Profile', icon: Icons.person_outline, route: '/profile', id: 'profile'),
        ];
      case UserRole.patient:
        return [
          SidebarNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/dashboard', id: 'dashboard'),
          SidebarNavItem(label: 'Health Assessment', icon: Icons.assignment_outlined, route: '/assessment', id: 'assessment'),
          SidebarNavItem(label: 'Appointments', icon: Icons.calendar_month_outlined, route: '/my-appointments', id: 'appointments'),
          SidebarNavItem(label: 'Reports', icon: Icons.description_outlined, route: '/report', id: 'reports'),
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

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.navyDark,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.white.withOpacity(0.08),
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
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(10),
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
                      const Text(
                        'HealthGuard AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        role == UserRole.admin
                            ? 'Admin Workspace'
                            : role == UserRole.doctor
                                ? 'Clinical Portal'
                                : 'Patient Portal',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
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
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),

          // Nav Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final bool isActive = currentRoute == item.route || currentRoute.startsWith(item.route);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: isActive ? AppColors.primaryTeal.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        if (onNavigate != null) {
                          onNavigate!(item.route);
                        } else {
                          AppLayout.safeNavigate(context, item.route, currentRoute);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 18,
                              color: isActive ? AppColors.primaryTeal : Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryTeal,
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
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryTeal,
                  child: Text(
                    (role == UserRole.doctor
                            ? (state.currentDoctor?.name ?? 'Doctor')
                            : (state.currentUser?.fullName ?? 'User'))
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
                        role == UserRole.doctor
                            ? (state.currentDoctor?.name ?? 'Dr. Medical')
                            : (state.currentUser?.fullName ?? 'Patient'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        role == UserRole.doctor
                            ? (state.currentDoctor?.specialty ?? 'Physician')
                            : (state.currentUser?.email ?? 'patient@healthguard.ai'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18, color: Colors.white60),
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
    );
  }
}

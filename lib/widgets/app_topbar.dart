import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../state/app_state.dart';

class AppTopbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const AppTopbar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        border: Border(
          bottom: BorderSide(
            color: AppColors.getBorder(isDark),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Drawer menu button if desktop sidebar is hidden
          if (MediaQuery.of(context).size.width < 900)
            IconButton(
              icon: Icon(Icons.menu, color: AppColors.getTextPrimary(isDark)),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextPrimary(isDark),
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
              ],
            ],
          ),

          const Spacer(),

          if (actions != null) ...actions!,

          // Theme toggle button
          IconButton(
            icon: Icon(
              state.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppColors.getTextSecondary(isDark),
              size: 20,
            ),
            tooltip: state.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              state.toggleTheme();
            },
          ),

          const SizedBox(width: 8),

          // Notifications bell
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications_none_outlined,
                  color: AppColors.getTextSecondary(isDark),
                  size: 22,
                ),
                if (state.notifications.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/notifications');
            },
          ),

          const SizedBox(width: 12),

          // User Profile Quick Badge
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    (state.currentDoctor?.name ?? state.currentUser?.fullName ?? 'U')
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
                if (MediaQuery.of(context).size.width > 600) ...[
                  const SizedBox(width: 8),
                  Text(
                    state.currentDoctor?.name ?? state.currentUser?.fullName ?? 'Account',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

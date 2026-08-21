import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/empty_state.dart';
import '../state/app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final notifications = state.notifications;

    final role = state.currentUser?.isAdmin == true ? UserRole.admin : UserRole.patient;
    final backTarget = role == UserRole.admin ? '/admin-dashboard' : '/dashboard';

    return AppLayout(
      title: 'Notifications Hub',
      subtitle: 'System alerts, appointment updates, and health reminders',
      role: role,
      currentRoute: '/notifications',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppButton(
                label: 'Back to Dashboard',
                icon: Icons.arrow_back,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, backTarget);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          notifications.isEmpty
              ? EmptyState(
                  icon: Icons.notifications_off_outlined,
                  title: 'All Caught Up!',
                  description: 'You currently have no unread notifications.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Notifications (${notifications.length})',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
                    ),
                    const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    IconData categoryIcon = Icons.notifications;
                    Color categoryColor = AppColors.primaryTeal;

                    if (notif.category == 'Alert') {
                      categoryIcon = Icons.warning_amber_rounded;
                      categoryColor = AppColors.danger;
                    } else if (notif.category == 'Appointment') {
                      categoryIcon = Icons.event_available;
                      categoryColor = AppColors.primaryBlue;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(categoryIcon, color: categoryColor, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        notif.title,
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.getTextPrimary(isDark)),
                                      ),
                                      AppBadge(label: notif.category, isSmall: true),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.body,
                                    style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark), height: 1.4),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${notif.timestamp.day}/${notif.timestamp.month}/${notif.timestamp.year} at ${notif.timestamp.hour}:${notif.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(isDark)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

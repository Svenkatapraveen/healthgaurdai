import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../state/app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final notifications = state.notifications;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: const Text('Notifications Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.getTextSecondary(isDark)),
                  const SizedBox(height: 16),
                  Text(
                    'All caught up! No notifications.',
                    style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];

                // Category styling
                IconData categoryIcon = Icons.notifications;
                Color categoryColor = AppColors.primaryTeal;
                
                if (notif.category == 'Alert') {
                  categoryIcon = Icons.warning_amber_rounded;
                  categoryColor = AppColors.riskCritical;
                } else if (notif.category == 'Appointment') {
                  categoryIcon = Icons.event_available;
                  categoryColor = Colors.blueAccent;
                } else if (notif.category == 'Reminder') {
                  categoryIcon = Icons.medication;
                  categoryColor = Colors.purpleAccent;
                } else if (notif.category == 'Health') {
                  categoryIcon = Icons.water_drop;
                  categoryColor = AppColors.primaryTeal;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(categoryIcon, color: categoryColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.body,
                                style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark), height: 1.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTimestamp(notif.timestamp),
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
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

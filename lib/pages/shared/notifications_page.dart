import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../main.dart';

class NotificationItem {
  final String title;
  final String desc;
  final String time;
  final IconData icon;
  const NotificationItem(
    this.title,
    this.desc,
    this.time,
    this.icon,
  );
}

class NotificationsPage extends StatelessWidget {
  final AppRole role;
  const NotificationsPage({
    super.key,
    this.role = AppRole.consumer,
  });

  Widget _buildNotificationCard(NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: AppColors.navy,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.time,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inspector = role == AppRole.inspector;

    // Consumer ke liye static items
    final consumerItems = const [
      NotificationItem(
        'Certificate verified',
        'LM/DL/2026/00452 was verified successfully.',
        'Today · 10:42 AM',
        Icons.check_rounded,
      ),
      NotificationItem(
        'Report status updated',
        'Your report RPT-260112-0042 is under review.',
        'Yesterday',
        Icons.message_outlined,
      ),
    ];

    return Shell(
      role: role,
      title: 'Notifications',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Updates for you',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              inspector
                  ? 'Assignments and field reminders'
                  : 'Certificate and report activity',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: 16),

            // MAGIC YAHAN HAI: Agar inspector hai toh ValueListenableBuilder lagao
            if (inspector)
              ValueListenableBuilder<
                List<NotificationItem>
              >(
                valueListenable:
                    inspectorNotificationsNotifier,
                builder: (context, notifications, child) {
                  return Column(
                    children: notifications
                        .map(
                          (item) =>
                              _buildNotificationCard(item),
                        )
                        .toList(),
                  );
                },
              )
            else
              // Agar consumer hai toh normal map karo
              Column(
                children: consumerItems
                    .map(
                      (item) =>
                          _buildNotificationCard(item),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

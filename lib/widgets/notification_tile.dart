import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.notification, this.onTap});

  String get _emoji {
    switch (notification.type) {
      case 'request':
        return '📨';
      case 'accepted':
        return '✅';
      case 'rejected':
        return '❌';
      case 'session_started':
        return '▶️';
      case 'session_ended':
        return '🏁';
      case 'credits':
        return '⚡';
      case 'file_received':
        return '📁';
      default:
        return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = !notification.isRead;
    final bg = isUnread
        ? (isDark
            ? AppColors.spaceIndigo
            : AppColors.powderBlue.withOpacity(0.5))
        : (isDark ? AppColors.spaceMidnight : AppColors.white);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isUnread
                  ? AppColors.primaryBlue.withOpacity(0.3)
                  : AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.pastelBlue.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(_emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title,
                      style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                        color:
                            isDark ? AppColors.starWhite : AppColors.textDark,
                      )),
                  const SizedBox(height: 2),
                  Text(notification.body,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMed)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(AppFormatters.timeAgo(notification.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight)),
                if (isUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

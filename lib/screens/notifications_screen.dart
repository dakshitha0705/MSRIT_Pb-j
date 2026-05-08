import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import '../theme/app_colors.dart';
import '../widgets/notification_tile.dart';
import 'session_screen.dart';
import 'request_action_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _handleNotificationTap(
      BuildContext context, NotificationModel notification) async {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    // Mark as read
    await fs.markNotificationRead(notification.notificationId);

    if (!context.mounted) return;

    // 'request' / 'emergency_request' → lender sees Accept/Reject screen
    if ((notification.type == 'request' ||
            notification.type == 'emergency_request') &&
        notification.sessionId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RequestActionScreen(sessionId: notification.sessionId),
        ),
      );
      return;
    }

    // 'accepted' → requester navigates to session for verification
    if (notification.type == 'accepted' && notification.sessionId.isNotEmpty) {
      // fromUserId = lender who accepted; toUserId = requester
      // isSender (lender role) = true only if current user IS the lender
      final isSender = notification.fromUserId == auth.uid;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionScreen(
            sessionId: notification.sessionId,
            isSender: isSender,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().uid;
    final fs = context.read<FirestoreService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBg : AppColors.lightBg),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                        icon: Icon(Icons.arrow_back_ios_rounded,
                            color: isDark
                                ? AppColors.starWhite
                                : AppColors.textDark),
                        onPressed: () => Navigator.pop(context)),
                    Expanded(
                        child: Text('Notifications',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.starWhite
                                    : AppColors.textDark))),
                    TextButton(
                        onPressed: () => fs.markAllNotificationsRead(uid),
                        child: const Text('Mark all read',
                            style: TextStyle(
                                color: AppColors.primaryBlue, fontSize: 13))),
                  ],
                ),
              ),

              // Notification list
              Expanded(
                child: StreamBuilder<List<NotificationModel>>(
                  stream: fs.notificationsStream(uid),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final notifs = snap.data ?? [];
                    if (notifs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🔔', style: TextStyle(fontSize: 56)),
                            SizedBox(height: 16),
                            Text('No notifications yet',
                                style: TextStyle(
                                    fontSize: 16, color: AppColors.textMed)),
                            SizedBox(height: 8),
                            Text('Requests and updates will appear here.',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textLight)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: notifs.length,
                      itemBuilder: (_, i) => NotificationTile(
                        notification: notifs[i],
                        onTap: () => _handleNotificationTap(context, notifs[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

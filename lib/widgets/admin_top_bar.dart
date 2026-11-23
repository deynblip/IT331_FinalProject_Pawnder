import 'package:flutter/material.dart';

import '../screens/notifications_screen.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';

/// Background used by every admin tab: orange at the top that fades into
/// the cream page color, so the cards below always sit on cream.
const LinearGradient kAdminGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [kOrangeSoft, kPeach, kCream],
  stops: [0.0, 0.3, 0.55],
);

/// Shared top bar of the admin tabs: white logo, notification bell with an
/// unread badge, an optional log out button, and a thin divider.
class AdminTopBar extends StatelessWidget {
  final VoidCallback? onLogout;

  const AdminTopBar({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 38,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
            const Spacer(),
            ListenableBuilder(
              listenable: NotificationService.changes,
              builder: (context, _) {
                final int unread = NotificationService.unreadCount;
                return IconButton(
                  tooltip: 'Notifications',
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                );
              },
            ),
            if (onLogout != null)
              IconButton(
                tooltip: 'Log Out',
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: onLogout,
              ),
          ],
        ),
        const Divider(color: Colors.white54, height: 12),
      ],
    );
  }
}
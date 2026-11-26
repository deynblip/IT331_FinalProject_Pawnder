import 'package:flutter/material.dart';

import '../screens/notifications_screen.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';

/// Background used by every admin tab: a soft peach at the top that fades
/// into the cream page color. Kept light so the orange banner and the cards
/// stand out, and the brown text stays easy to read.
const LinearGradient kAdminGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFFFE8D6), Color(0xFFFFF6EC)], // fixed light: admin stays light
  stops: [0.0, 0.35],
);

/// Shared top bar of the admin tabs: menu button (opens the admin drawer
/// with Settings and Log Out), brown logo, notification bell with an unread
/// badge, and a thin divider.
class AdminTopBar extends StatelessWidget {
  const AdminTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Menu',
              icon: Icon(Icons.menu, color: kNavy),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            Expanded(
              child: Center(
                child: Image.asset('assets/logo.png', height: 38),
              ),
            ),
            ListenableBuilder(
              listenable: NotificationService.changes,
              builder: (context, _) {
                final int unread = NotificationService.unreadCount;
                return IconButton(
                  tooltip: 'Notifications',
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    child: Icon(
                      Icons.notifications_none,
                      color: kNavy,
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
          ],
        ),
        Divider(color: kNavy.withValues(alpha: 0.15), height: 12),
      ],
    );
  }
}
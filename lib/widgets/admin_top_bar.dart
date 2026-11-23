import 'package:flutter/material.dart';

import '../screens/drawer/settings.dart';
import '../screens/notifications_screen.dart';
import '../services/auth_service.dart';
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

/// Shared top bar of the admin tabs: brown logo, notification bell with an
/// unread badge, optional account buttons, and a thin divider.
///
/// The admin has no drawer. Only what the admin needs from the user drawer
/// is kept: Change Password and a Log Out button that is always visible.
class AdminTopBar extends StatelessWidget {
  /// When set, Change Password and Log Out are shown (used on Admin Home).
  final VoidCallback? onLogout;

  const AdminTopBar({super.key, this.onLogout});

  void _openChangePassword(BuildContext context) {
    final String? email = AuthService.currentEmail;
    if (email == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChangePasswordPage(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Image.asset('assets/logo.png', height: 38),
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
            if (onLogout != null) ...[
              IconButton(
                tooltip: 'Change Password',
                icon: const Icon(Icons.manage_accounts_outlined, color: kNavy),
                onPressed: () => _openChangePassword(context),
              ),
              IconButton(
                tooltip: 'Log Out',
                icon: const Icon(Icons.logout, color: kNavy),
                onPressed: onLogout,
              ),
            ],
          ],
        ),
        Divider(color: kNavy.withValues(alpha: 0.15), height: 12),
      ],
    );
  }
}
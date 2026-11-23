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

enum _AccountAction { changePassword, logOut }

/// Shared top bar of the admin tabs: white logo, notification bell with an
/// unread badge, an optional account menu, and a thin divider.
///
/// The admin has no drawer. The account menu only holds what the admin
/// needs from the user drawer: Change Password and Log Out.
class AdminTopBar extends StatelessWidget {
  /// When set, the account menu is shown (used on Admin Home).
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
              PopupMenuButton<_AccountAction>(
                tooltip: 'Account',
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: kCardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (action) {
                  switch (action) {
                    case _AccountAction.changePassword:
                      _openChangePassword(context);
                    case _AccountAction.logOut:
                      onLogout!();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _AccountAction.changePassword,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_outline, color: kNavy),
                      title: Text(
                        'Change Password',
                        style: TextStyle(color: kNavy),
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: _AccountAction.logOut,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        'Log Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const Divider(color: Colors.white54, height: 12),
      ],
    );
  }
}
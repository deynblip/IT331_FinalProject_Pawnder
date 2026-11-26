import 'package:flutter/material.dart';

import '../services/report_service.dart';
import '../models/app_notification.dart';
import '../services/application_service.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';
import '../utils/report_style.dart';
import 'application_details_screen.dart';
import 'owner_application_screen.dart';
import 'report_details_screen.dart';
import '../utils/responsive.dart';

/// Opened from the bell icon. Newest first. Tapping a notification opens the
/// related report or application.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _open(BuildContext context, AppNotification n) async {
    NotificationService.markRead(n.id);
    final id = n.targetId;

    switch (n.type) {
      case NotificationType.rescueResponse:
        final report = id == null
            ? null
            : (ReportService.byId(id) ?? await ReportService.refreshOne(id));
        if (!context.mounted) return;
        if (report == null) return _snack(context, 'This report is gone.');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailsScreen(
              report: report,
              onChanged: (_) {}, // TEMP: connect to the backend later
            ),
          ),
        );

      case NotificationType.applicationForwarded:
      case NotificationType.applicationApproved:
      case NotificationType.applicationRejected:
        final app = ApplicationService.forCurrentUser()
            .where((a) => a.id == id)
            .firstOrNull;
        if (app == null) {
          return _snack(context, 'This application is no longer available.');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplicationDetailsScreen(application: app),
          ),
        );

      case NotificationType.applicationForOwner:
        final app = ApplicationService.forMyPets()
            .where((a) => a.id == id)
            .firstOrNull;
        if (app == null) {
          return _snack(context, 'This application is no longer available.');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerApplicationScreen(application: app),
          ),
        );
      case NotificationType.applicationSubmitted:
      case NotificationType.postApproved:
      case NotificationType.postRemoved:
      case NotificationType.rescuerApproved:
      case NotificationType.rescuerRejected:
      case NotificationType.rescuerFlagged:
      // Nothing to open, so show the full message.
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              n.title,
              style: TextStyle(
                color: kNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(n.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kSurfaceWhite,
        foregroundColor: kNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: NotificationService.changes,
            builder: (context, _) => TextButton(
              onPressed: NotificationService.unreadCount == 0
                  ? null
                  : NotificationService.markAllRead,
              child: const Text('Mark all read'),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: kCardBorder),
        ),
      ),
      body: ListenableBuilder(
        listenable: NotificationService.changes,
        builder: (context, _) {
          final items = NotificationService.all;

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 48, color: kHintGray),
                    const SizedBox(height: 12),
                    Text(
                      NotificationService.pushEnabled
                          ? 'No notifications yet.'
                          : 'Notifications are turned off. '
                          'You can turn them on in Settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kHintGray),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(context.hPad, 16, context.hPad, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _NotificationCard(
              notification: items[i],
              onTap: () => _open(context, items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  IconData get _icon => switch (notification.type) {
    NotificationType.rescueResponse => Icons.groups,
    NotificationType.applicationForOwner =>
    Icons.mark_email_unread_outlined,
    NotificationType.applicationForwarded => Icons.forward_to_inbox,
    NotificationType.applicationApproved => Icons.check_circle_outline,
    NotificationType.applicationRejected => Icons.cancel_outlined,
    NotificationType.postRemoved => Icons.remove_circle_outline,
    NotificationType.postApproved => Icons.check_circle_outline,
    NotificationType.rescuerApproved => Icons.verified_outlined,
    NotificationType.rescuerRejected => Icons.cancel_outlined,
    NotificationType.rescuerFlagged => Icons.flag_outlined,
    NotificationType.applicationSubmitted => Icons.assignment_outlined,
  };

  Color get _color => switch (notification.type) {
    NotificationType.applicationApproved => ReportColors.green,
    NotificationType.postApproved => ReportColors.green,
    NotificationType.rescuerApproved => ReportColors.green,
    NotificationType.applicationRejected => ReportColors.red,
    NotificationType.rescuerRejected => ReportColors.red,
    NotificationType.rescuerFlagged => ReportColors.red,
    NotificationType.postRemoved => ReportColors.orange,
    _ => ReportColors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? kPeach : kSurfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kCardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: kNavy,
                      fontSize: 15,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: kHintGray,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.timeText,
                    style: TextStyle(color: kHintGray, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (unread)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: kBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
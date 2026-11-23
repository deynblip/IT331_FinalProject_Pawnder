// ======================================
// TEMPORARY IN-MEMORY NOTIFICATION STORE
// ======================================
// Sample notifications so you can SEE every type before the backend exists.
// They reset every time the app restarts.
// Later, the backend will create these (for example when an admin forwards
// an application) and this service will just read them.

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import 'auth_service.dart';

class NotificationService {
  static DateTime _ago(Duration d) => DateTime.now().subtract(d);

  // targetId values match the sample data:
  //   report '1'      = Injured Dog (posted by the logged-in user)
  //   'demo1'..'demo3' = the user's applications, 'demo4' = application for
  //   the user's own pet (Brownie)
  static final List<AppNotification> _items = [
    AppNotification(
      id: 'n1',
      type: NotificationType.rescueResponse,
      title: 'Someone is on the way',
      message: 'A community member is responding to your Injured Dog report.',
      createdAt: _ago(const Duration(minutes: 20)),
      targetId: '1',
    ),
    AppNotification(
      id: 'n2',
      type: NotificationType.applicationForOwner,
      title: 'New application for Brownie',
      message: 'An application passed admin screening and needs your '
          'decision.',
      createdAt: _ago(const Duration(hours: 3)),
      targetId: 'demo4',
    ),
    AppNotification(
      id: 'n3',
      type: NotificationType.applicationForwarded,
      title: 'Application forwarded',
      message: 'Your application for Buddy was forwarded to the pet owner '
          'for the final decision.',
      createdAt: _ago(const Duration(days: 1, hours: 1)),
      read: true,
      targetId: 'demo1',
    ),
    AppNotification(
      id: 'n4',
      type: NotificationType.applicationApproved,
      title: 'Application approved',
      message: 'Good news! Your application for Mingming was approved.',
      createdAt: _ago(const Duration(days: 2)),
      read: true,
      targetId: 'demo2',
    ),
    AppNotification(
      id: 'n5',
      type: NotificationType.applicationRejected,
      title: 'Application not approved',
      message: 'Your application for Mimi was not approved.',
      createdAt: _ago(const Duration(days: 4)),
      read: true,
      targetId: 'demo3',
    ),
    AppNotification(
      id: 'n6',
      type: NotificationType.postRemoved,
      title: 'Post removed by admin',
      message: 'One of your adoption posts was removed by an administrator '
          'because it did not follow the community guidelines.',
      createdAt: _ago(const Duration(days: 6)),
      read: true,
    ),
  ];

  /// Bumps every time something changes so screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void _notify() => changes.value++;

  // ---- Settings > Notifications switches ----
  // They live here so the bell and the Notifications screen follow them.
  // (They reset when the app restarts; save with shared_preferences later.)
  static bool pushEnabled = true; // master switch
  static bool reportUpdates = true; // rescue responses on your reports
  static bool adoptionUpdates = true; // applications and adoption posts

  static void setPushEnabled(bool value) {
    pushEnabled = value;
    _notify();
  }

  static void setReportUpdates(bool value) {
    reportUpdates = value;
    _notify();
  }

  static void setAdoptionUpdates(bool value) {
    adoptionUpdates = value;
    _notify();
  }

  /// Is this notification allowed by the user's Settings?
  static bool _visible(AppNotification n) {
    if (!pushEnabled) return false;

    // Notifications made for one specific user are hidden from everyone else.
    if (n.userEmail != null && n.userEmail != AuthService.currentEmail) {
      return false;
    }

    return switch (n.type) {
      NotificationType.rescueResponse => reportUpdates,
      NotificationType.rescuerApproved ||
      NotificationType.rescuerRejected ||
      NotificationType.rescuerFlagged =>
      true,
      _ => adoptionUpdates,
    };
  }

  /// Newest first. Only the notifications the user's Settings allow.
  static List<AppNotification> get all {
    final list = _items.where(_visible).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static int get unreadCount =>
      _items.where((n) => _visible(n) && !n.read).length;

  static void markRead(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i == -1 || _items[i].read) return;
    _items[i] = _items[i].copyWith(read: true);
    _notify();
  }

  static void markAllRead() {
    if (unreadCount == 0) return;
    for (var i = 0; i < _items.length; i++) {
      if (_visible(_items[i])) _items[i] = _items[i].copyWith(read: true);
    }
    _notify();
  }

  /// Adds a new (unread) notification. Used by the app/backend when
  /// something happens that the user should know about.
  /// Pass [userEmail] to show it only to that user.
  static void add({
    required NotificationType type,
    required String title,
    required String message,
    String? targetId,
    String? userEmail,
  }) {
    _items.add(
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        targetId: targetId,
        userEmail: userEmail,
      ),
    );
    _notify();
  }
}
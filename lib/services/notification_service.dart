// ===================================
// NOTIFICATIONS (Supabase)
// ===================================
// The DATABASE creates the notifications (for example when an admin forwards
// an application). This service only reads the logged-in user's own rows and
// marks them as read. The bell and the Notifications screen listen to
// [changes]. They refresh by polling (see MainLayout and AdminLayout).

import 'dart:async';
import 'push_service.dart';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import 'auth_service.dart';
import 'db_errors.dart';

class NotificationService {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Rows from the database (only the logged-in user's own).
  static List<AppNotification> _fromDb = [];

  /// Ids the user already opened here, so a refresh does not flip them back
  /// to unread before the database has saved the change.
  static final Set<String> _readHere = {};

  static bool _loaded = false;
  static Future<void>? _loading;
  static String? _loadError;
  static DateTime? _lastTry;
  static int _generation = 0;

  /// Bumps every time something changes so screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void _notify() => changes.value++;

  static bool get isLoaded => _loaded;
  static String? get loadError => _loadError;

  // ---- Settings > Notifications switches ----
  // They live here so the bell and the Notifications screen follow them.
  // (They reset when the app restarts; save with shared_preferences later.)
  static bool pushEnabled = true; // master switch
  static bool reportUpdates = true; // rescue responses on your reports
  static bool adoptionUpdates = true; // applications and adoption posts

  static void setPushEnabled(bool value) {
    pushEnabled = value;
    unawaited(PushService.setEnabled(value));
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

  // ---------------------------------------------------------------- Loading

  static Future<void> load() {
    final Future<void>? running = _loading;
    if (running != null) return running;
    final Future<void> f = _fetch().whenComplete(() => _loading = null);
    _loading = f;
    return f;
  }

  static void _kick() {
    if (_loaded || _loading != null) return;
    if (AuthService.currentUserId == null) return;
    final DateTime? t = _lastTry;
    if (t != null &&
        DateTime.now().difference(t) < const Duration(seconds: 15)) {
      return;
    }
    unawaited(load());
  }

  static Future<void> _fetch() async {
    final int gen = _generation;
    _lastTry = DateTime.now();
    try {
      final rows = await _db
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      if (gen != _generation) return; // logged out while loading

      final List<AppNotification> list = [];
      for (final dynamic r in rows) {
        final AppNotification? n =
        _fromRow(Map<String, dynamic>.from(r as Map));
        if (n != null) list.add(n);
      }
      _fromDb = list;
      _loaded = true;
      _loadError = null;
    } catch (e) {
      if (gen != _generation) return;
      _loadError =
          friendlyDbError(e, fallback: 'Could not load the notifications.');
    }
    _notify();
  }

  /// Forget everything (log out / switch account).
  static void reset() {
    _generation++;
    _fromDb = [];
    _readHere.clear();
    _loaded = false;
    _loading = null;
    _loadError = null;
    _lastTry = null;
    _notify();
  }

  // ---------------------------------------------------------------- Mapping

  static AppNotification? _fromRow(Map<String, dynamic> row) {
    final NotificationType? type = _typeFrom(row['type'] as String? ?? '');
    if (type == null) return null; // a type this app version does not know

    final String id = row['id'] as String;
    return AppNotification(
      id: id,
      type: type,
      title: row['title'] as String? ?? '',
      message: row['message'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      read: row['is_read'] == true || _readHere.contains(id),
      targetId: row['target_id'] as String?,
    );
  }

  static NotificationType? _typeFrom(String v) => switch (v) {
    'rescue_response' => NotificationType.rescueResponse,
    'application_submitted' => NotificationType.applicationSubmitted,
    'application_for_owner' => NotificationType.applicationForOwner,
    'application_forwarded' => NotificationType.applicationForwarded,
    'application_approved' => NotificationType.applicationApproved,
    'application_rejected' => NotificationType.applicationRejected,
    'post_approved' => NotificationType.postApproved,
    'post_removed' => NotificationType.postRemoved,
    'rescuer_approved' => NotificationType.rescuerApproved,
    'rescuer_rejected' => NotificationType.rescuerRejected,
    'rescuer_flagged' => NotificationType.rescuerFlagged,
    _ => null,
  };

  // ---------------------------------------------------------------- Reading

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

  static List<AppNotification> get _everything => [..._fromDb];

  /// Newest first. Only the notifications the user's Settings allow.
  static List<AppNotification> get all {
    _kick();
    final list = _everything.where(_visible).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static int get unreadCount {
    _kick();
    return _everything.where((n) => _visible(n) && !n.read).length;
  }

  // ---------------------------------------------------------------- Actions

  static void markRead(String id) {
    final int d = _fromDb.indexWhere((n) => n.id == id);
    if (d != -1) {
      if (_fromDb[d].read) return;
      _fromDb[d] = _fromDb[d].copyWith(read: true);
      _readHere.add(id);
      _notify();
      unawaited(_saveRead(id));
      return;
    }
  }

  static void markAllRead() {
    if (unreadCount == 0) return;

    var anyFromDb = false;
    for (var i = 0; i < _fromDb.length; i++) {
      if (_visible(_fromDb[i]) && !_fromDb[i].read) {
        _readHere.add(_fromDb[i].id);
        _fromDb[i] = _fromDb[i].copyWith(read: true);
        anyFromDb = true;
      }
    }
    _notify();
    if (anyFromDb) unawaited(_saveAllRead());
  }

  static Future<void> _saveRead(String id) async {
    try {
      await _db.rpc('mark_notification_read', params: {'p_id': id});
    } catch (e) {
      debugPrint('Could not save "read": $e');
    }
  }

  static Future<void> _saveAllRead() async {
    try {
      await _db.rpc('mark_all_notifications_read');
    } catch (e) {
      debugPrint('Could not save "read all": $e');
    }
  }
}
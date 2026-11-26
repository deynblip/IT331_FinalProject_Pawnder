import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/notifications_screen.dart';
import '../utils/app_colors.dart';
import 'auth_service.dart';
import 'notification_service.dart';

// ===================================
// PUSH NOTIFICATIONS (FCM)  -  Batch 8A
// ===================================
// The DATABASE still creates the notifications. This service only:
//  1. gets this phone's FCM token and saves it for the logged-in user
//     (register_device_token), and removes it on log out;
//  2. when a push arrives while the app is open: refreshes the bell and
//     shows a banner at the top of the app (Android shows nothing itself);
//  3. opens the Notifications screen when the user taps a push or the banner.
// When the app is in the background or closed, Android shows the push in
// the tray / as a pop-up by itself (channel "pawnder_high", see
// MainActivity.kt). The push itself is sent by the Edge Function (Batch 8B).
// If Firebase fails to start (no Google Play services), the app still works.

class PushService {
  static SupabaseClient get _db => Supabase.instance.client;

  static GlobalKey<NavigatorState>? _navigatorKey;
  static Future<void>? _init;
  static bool _ready = false;
  static String? _token;

  /// A push was tapped but the app was not ready to open the screen yet.
  static bool _pendingOpen = false;

  static OverlayEntry? _banner;
  static Timer? _bannerTimer;

  /// Call once at app start. Safe to call without awaiting.
  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) {
    return _init ??= _start(navigatorKey);
  }

  static Future<void> _start(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    try {
      await Firebase.initializeApp();
      final FirebaseMessaging fm = FirebaseMessaging.instance;

      // App is open: refresh the bell and show the banner.
      FirebaseMessaging.onMessage.listen((RemoteMessage m) {
        unawaited(NotificationService.load());
        _showBanner(m);
      });

      // App was in the background and the user tapped the push.
      FirebaseMessaging.onMessageOpenedApp.listen((_) {
        _pendingOpen = true;
        openPendingTap();
      });

      // App was closed and the user tapped the push.
      final RemoteMessage? first = await fm.getInitialMessage();
      if (first != null) _pendingOpen = true;

      fm.onTokenRefresh.listen((String t) {
        _token = t;
        if (AuthService.sessionActive && NotificationService.pushEnabled) {
          unawaited(_save(t));
        }
      });

      _ready = true;
    } catch (e) {
      debugPrint('Push init error: $e');
    }
  }

  // ---------------------------------------------------------------- Token

  /// Asks permission (Android 13+), gets the token, saves it for this user.
  static Future<void> register() async {
    if (!NotificationService.pushEnabled) return;
    try {
      await _init;
      if (!_ready) return;

      final FirebaseMessaging fm = FirebaseMessaging.instance;
      final NotificationSettings s = await fm.requestPermission();
      if (s.authorizationStatus == AuthorizationStatus.denied) return;

      final String? t = await fm.getToken();
      if (t == null) return;
      _token = t;
      await _save(t);
    } catch (e) {
      debugPrint('Push register error: $e');
    }
  }

  static Future<void> _save(String token) async {
    try {
      await _db.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': 'android',
      });
    } catch (e) {
      debugPrint('Could not save the device token: $e');
    }
  }

  /// Log out / switch off pushes: remove the token from the database and
  /// throw the token away, so the next account on this phone gets a new one.
  static Future<void> unregister() async {
    if (!_ready) return;
    try {
      await Future<void>(() async {
        final String? t = _token;
        if (t != null) {
          try {
            await _db.rpc('unregister_device_token', params: {'p_token': t});
          } catch (e) {
            debugPrint('Could not remove the device token: $e');
          }
        }
        await FirebaseMessaging.instance.deleteToken();
      }).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Push unregister error: $e');
    }
    _token = null;
    _removeBanner();
  }

  /// The "Push notifications" switch in Settings.
  static Future<void> setEnabled(bool on) {
    return on ? register() : unregister();
  }

  // ---------------------------------------------------------------- Banner

  /// App is open: show the push as a banner at the top of the screen.
  static void _showBanner(RemoteMessage m) {
    final RemoteNotification? n = m.notification;
    final OverlayState? overlay = _navigatorKey?.currentState?.overlay;
    if (n == null || overlay == null) return;

    _removeBanner();
    final OverlayEntry entry = OverlayEntry(
      builder: (_) => _PushBanner(
        title: n.title ?? '',
        body: n.body ?? '',
        onTap: () {
          _removeBanner();
          _pendingOpen = true;
          openPendingTap();
        },
        onClose: _removeBanner,
      ),
    );
    _banner = entry;
    overlay.insert(entry);
    _bannerTimer = Timer(const Duration(seconds: 5), _removeBanner);
  }

  static void _removeBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
    _banner?.remove();
    _banner = null;
  }

  // ---------------------------------------------------------------- Tap

  /// Opens the Notifications screen if a push was tapped. Called when the
  /// app is already open, and by Home / Admin right after they appear.
  static void openPendingTap() {
    if (!_pendingOpen || !AuthService.sessionActive) return;
    final NavigatorState? nav = _navigatorKey?.currentState;
    if (nav == null) return;
    _pendingOpen = false;
    nav.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }
}

/// The banner that slides in from the top. Tap = open Notifications,
/// swipe up = close.
class _PushBanner extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _PushBanner({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, -40 * (1 - v)),
                child: child,
              ),
            ),
            child: GestureDetector(
              onTap: onTap,
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < 0) onClose();
              },
              child: Material(
                elevation: 6,
                color: kCardColor,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kCardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pets,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title.isNotEmpty)
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: kNavy,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            if (body.isNotEmpty)
                              Text(
                                body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: kNavy,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
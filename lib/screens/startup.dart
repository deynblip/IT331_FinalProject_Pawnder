// Ilagay sa: lib/screens/startup.dart  (BAGONG FILE)
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/response_service.dart';
import '../utils/app_colors.dart';
import 'admin/admin_layout.dart';
import 'main_layout.dart';
import 'welcome.dart';

// ===============================
// STARTUP SCREEN
// ===============================
// Shown for a moment every time the app opens. It checks if the phone
// still has a valid session, loads the profile, then goes straight to
// Home (or Admin). No session -> Welcome.
//
// No internet but there IS a session: we do NOT log the user out. We show
// "Can't connect" with a Retry button instead.

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (_offline) setState(() => _offline = false);

    final SessionStatus status = await AuthService.restoreSession();
    if (!mounted) return;

    switch (status) {
      case SessionStatus.ready:
        if (AuthService.isCurrentAdmin) {
          _goTo(AdminLayout(name: AuthService.currentName));
        } else {
          unawaited(ResponseService.loadMe());
          _goTo(MainLayout(
            name: AuthService.currentName,
            email: AuthService.currentEmail ?? '',
          ));
        }
      case SessionStatus.none:
        _goTo(const WelcomePage());
      case SessionStatus.restricted:
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        _goTo(const WelcomePage());
        messenger.showSnackBar(
          const SnackBar(content: Text('Your account has been restricted.')),
        );
      case SessionStatus.offline:
        setState(() => _offline = true);
    }
  }

  void _goTo(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _logOut() async {
    await AuthService.signOut();
    if (mounted) _goTo(const WelcomePage());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The logo is a single brown color, so tint it white in dark mode.
              Image.asset(
                'assets/logo.png',
                height: 90,
                color: isDark ? Colors.white : null,
                colorBlendMode: isDark ? BlendMode.srcIn : null,
              ),
              const SizedBox(height: 28),
              if (!_offline)
                const CircularProgressIndicator(color: kOrange)
              else ...[
                const Text(
                  "Can't connect. Try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please check your internet connection.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: _logOut,
                  child: const Text('Log out'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import 'welcome.dart';

// ===============================
// STARTUP SCREEN
// ===============================
// Shown every time the app opens. It is the Welcome page in loading mode:
// it checks the saved session, then goes to Home / Admin or shows
// Get Started. No internet but a session exists: "Can't connect" + Retry.

class StartupPage extends StatelessWidget {
  final Future<void>? backendReady;

  const StartupPage({super.key, this.backendReady});

  @override
  Widget build(BuildContext context) {
    return WelcomePage(checkSession: true, waitFor: backendReady);
  }
}
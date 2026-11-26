// Ilagay sa: lib/main.dart  (PALITAN ANG BUONG LAMAN)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/auth_service.dart';
import 'services/supabase_config.dart';

import 'screens/startup.dart';
import 'screens/welcome.dart';
import 'utils/app_colors.dart';
import 'utils/responsive.dart';
import 'utils/theme_controller.dart';

/// Lets us change screens from outside a widget (used when the session ends).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Show the app right away; the database connects while the loading screen shows.
  runApp(PawnderApp(backendReady: _initBackend()));
}

Future<void> _initBackend() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  _listenForEndedSession();
}

/// If the server ends the session while the app is open (expired, or the
/// user was logged out from another device), go back to Welcome.
/// A normal Log Out does not trigger this: AuthService marks the session as
/// ended first.
void _listenForEndedSession() {
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedOut && AuthService.sessionActive) {
      AuthService.endSession();

      final NavigatorState? nav = navigatorKey.currentState;
      final BuildContext? ctx = navigatorKey.currentContext;
      if (nav == null || ctx == null) return;

      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(ctx);
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomePage()),
            (route) => false,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('You were logged out. Please log in again.')),
      );
    }
  });
}

class PawnderApp extends StatelessWidget {
  final Future<void>? backendReady;

  const PawnderApp({super.key, this.backendReady});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Pawnder',
          themeMode: mode,
          theme: ThemeData(
            fontFamily: 'Nunito',
            colorScheme: ColorScheme.fromSeed(seedColor: kOrange),
            scaffoldBackgroundColor: kCream,
          ),
          darkTheme: ThemeData(
            fontFamily: 'Nunito',
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kOrange,
              brightness: Brightness.dark,
            ).copyWith(surface: kDarkSurface),
            scaffoldBackgroundColor: kDarkBg,
          ),
          builder: (context, child) => _ResponsiveFrame(child: child!),
          home: StartupPage(backendReady: backendReady),
        );
      },
    );
  }
}

/// Keeps every screen readable on all phones and tablets:
/// - limits very large system font sizes so fixed-height layouts don't break
/// - centers the app at [Responsive.maxContentWidth] on tablets and wide screens
class _ResponsiveFrame extends StatelessWidget {
  final Widget child;

  const _ResponsiveFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double width = media.size.width > Responsive.maxContentWidth
        ? Responsive.maxContentWidth
        : media.size.width;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          height: media.size.height,
          child: MediaQuery(
            data: media.copyWith(
              size: Size(width, media.size.height),
              textScaler: media.textScaler.clamp(
                maxScaleFactor: Responsive.maxTextScale,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
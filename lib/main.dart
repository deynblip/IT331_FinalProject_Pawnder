import 'package:flutter/material.dart';

import 'screens/welcome.dart';
import 'utils/app_colors.dart';
import 'utils/responsive.dart';
import 'utils/theme_controller.dart';

void main() {
  runApp(const PawnderApp());
}

class PawnderApp extends StatelessWidget {
  const PawnderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
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
          home: const WelcomePage(),
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
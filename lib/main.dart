import 'package:flutter/material.dart';

import 'screens/welcome.dart';
import 'utils/app_colors.dart';
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
          home: const WelcomePage(),
        );
      },
    );
  }
}
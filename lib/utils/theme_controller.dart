import 'package:flutter/material.dart';

// Holds the app's current theme (light / dark). Changing it rebuilds the app.
final ValueNotifier<ThemeMode> themeModeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.light);

const Color kDarkBg = Color(0xFF121826);
const Color kDarkSurface = Color(0xFF1B2335);
const Color kDarkAccent = Color(0xFF8FB3EE);
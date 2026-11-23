import 'package:flutter/material.dart';

// Holds the app's current theme (light / dark). Changing it rebuilds the app.
final ValueNotifier<ThemeMode> themeModeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.light);

const Color kDarkBg = Color(0xFF1E1715);
const Color kDarkSurface = Color(0xFF2A211E);
const Color kDarkAccent = Color(0xFFF59E5B);
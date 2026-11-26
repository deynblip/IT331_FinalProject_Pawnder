import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Holds the app's current theme (light / dark). Changing it rebuilds the app.
final ValueNotifier<ThemeMode> themeModeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.light);

/// True while the dark theme is on. app_colors.dart reads this.
bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

/// The Admin side and the Login / Welcome screens are always light.
/// (Does not touch the saved choice.)
void resetToLightMode() => themeModeNotifier.value = ThemeMode.light;

bool _darkPref = false; // the user's saved choice

/// Call once in main() before runApp.
Future<void> loadDarkPref() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkPref = prefs.getBool('dark_mode') ?? false;
  } catch (_) {}
}

/// User side: switch to the saved choice (called when the main app opens).
void applySavedMode() {
  themeModeNotifier.value = _darkPref ? ThemeMode.dark : ThemeMode.light;
}

/// Settings switch: apply the choice and remember it.
Future<void> setDarkMode(bool dark) async {
  _darkPref = dark;
  themeModeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', dark);
  } catch (_) {}
}

const Color kDarkBg = Color(0xFF1E1715);
const Color kDarkSurface = Color(0xFF2A211E);
const Color kDarkAccent = Color(0xFFF59E5B);
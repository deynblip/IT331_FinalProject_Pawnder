import 'package:flutter/material.dart';

import 'theme_controller.dart';
// ===============================
// SUNSET PAWS PALETTE
// ===============================


/// Cocoa brown: headings, body text. Light cream in dark mode.
Color get kNavy =>
    isDarkMode ? const Color(0xFFF5EBE4) : const Color(0xFF3D2C29);

/// Same brown, for FILLS that carry white text (selected chips, FAB, snackbars).
Color get kNavyFill =>
    isDarkMode ? const Color(0xFF6B4F47) : const Color(0xFF3D2C29);

/// Dark orange: buttons, selected chips, links, icons (was blue).
const Color kBlue = Color(0xFFC4531F);

/// Orange: welcome / settings buttons (was light blue).
const Color kButtonBlue = Color(0xFFE0662E);

/// Warm gray: hints and secondary text.
Color get kHintGray =>
    isDarkMode ? const Color(0xFFB5A198) : const Color(0xFF8A746C);

const Color kOrange = Color(0xFFE0662E); // primary orange
const Color kOrangeSoft = Color(0xFFF59E5B); // gradient end
Color get kPeach => // icon circles, soft fills
isDarkMode ? const Color(0xFF3A2B24) : const Color(0xFFFFE8D6);
Color get kCream => // page background
isDarkMode ? const Color(0xFF1E1715) : const Color(0xFFFFF6EC);
Color get kCardColor => // cards
isDarkMode ? const Color(0xFF2A211E) : const Color(0xFFFFFCF8);
Color get kCardBorder => // card borders
isDarkMode ? const Color(0xFF3D312C) : const Color(0xFFF5DEC8);
Color get kSurfaceWhite => // white fills: form fields, sheets, app bars
isDarkMode ? const Color(0xFF2A211E) : const Color(0xFFFFFFFF);
const Color kTeal = Color(0xFF2BA59A); // secondary accent

const LinearGradient kSunsetGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kOrange, kOrangeSoft],
);
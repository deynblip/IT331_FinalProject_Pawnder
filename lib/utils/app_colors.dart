import 'package:flutter/material.dart';

// ===============================
// SUNSET PAWS PALETTE
// ===============================
// The old names (kNavy, kBlue, ...) are kept so every screen picks up the
// new colors without renaming. Read them as their new roles below.

/// Cocoa brown: headings, body text, main dark buttons (was navy).
const Color kNavy = Color(0xFF3D2C29);

/// Dark orange: buttons, selected chips, links, icons (was blue).
/// White text on it is readable.
const Color kBlue = Color(0xFFC4531F);

/// Orange: welcome / settings buttons (was light blue).
const Color kButtonBlue = Color(0xFFE0662E);

/// Warm gray: hints and secondary text.
const Color kHintGray = Color(0xFF8A746C);

const Color kOrange = Color(0xFFE0662E); // primary orange
const Color kOrangeSoft = Color(0xFFF59E5B); // gradient end
const Color kPeach = Color(0xFFFFE8D6); // icon circles, soft fills
const Color kCream = Color(0xFFFFF6EC); // page background
const Color kCardColor = Color(0xFFFFFCF8); // cards (warm white)
const Color kCardBorder = Color(0xFFF5DEC8); // card borders
const Color kTeal = Color(0xFF2BA59A); // secondary accent

const LinearGradient kSunsetGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kOrange, kOrangeSoft],
);
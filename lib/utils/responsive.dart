import 'package:flutter/material.dart';

/// Layout values that adapt to the phone's screen width, so screens look
/// right on small phones, large phones and tablets.
class Responsive {
  Responsive._();

  /// On tablets and wide screens the app is centered at this width,
  /// so layouts keep the size they were designed for.
  static const double maxContentWidth = 600;

  /// Largest text size allowed from the phone's font settings. Bigger text
  /// would break layouts that have fixed heights.
  static const double maxTextScale = 1.3;

  /// Left and right page padding: 16 on small phones (< 360 dp wide),
  /// 20 on regular phones and 24 on large phones and tablets (>= 400 dp).
  static double pagePadding(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 16;
    if (width < 400) return 20;
    return 24;
  }
}

extension ResponsiveContext on BuildContext {
  /// Shortcut for [Responsive.pagePadding].
  double get hPad => Responsive.pagePadding(this);
}
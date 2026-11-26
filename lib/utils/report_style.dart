import 'package:flutter/material.dart';
import '../models/stray_report.dart';
import 'app_colors.dart';

// Colors for urgency levels and rescue statuses (Sunset Paws palette).
class ReportColors {
  static Color get navy => kNavy;
  static const blue = Color(0xFF2BA59A);
  static const red = Color(0xFFE04F4F);
  static const orange = Color(0xFFE9A23B);
  static const green = Color(0xFF4CAF6E);
  static Color get grey => kHintGray;
}

Color urgencyColor(Urgency u) {
  switch (u) {
    case Urgency.urgent:
      return ReportColors.red;
    case Urgency.needsHelp:
      return ReportColors.orange;
    case Urgency.sighted:
      return ReportColors.blue;
  }
}

Color statusColor(RescueStatus s) {
  switch (s) {
    case RescueStatus.needsRescue:
      return ReportColors.red;
    case RescueStatus.inProgress:
      return ReportColors.navy;
    case RescueStatus.rescued:
      return ReportColors.green;
  }
}

/// Tag for reports marked "Possibly a lost pet".
const Color lostPetColor = Color(0xFF7A5AA6);
import 'package:flutter/material.dart';
import '../models/stray_report.dart';

// Kulay galing sa UI. Pwede niyong ilipat/i-merge sa app_colors.dart.
class ReportColors {
  static const navy = Color(0xFF22365C);
  static const blue = Color(0xFF3F5F94);
  static const red = Color(0xFFB85A5A);
  static const orange = Color(0xFFC17F5E);
  static const green = Color(0xFF5B9A3C);
  static const grey = Color(0xFF8A8F98);
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
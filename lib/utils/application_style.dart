import 'package:flutter/material.dart';

import '../models/adoption_application.dart';
import 'report_style.dart';

Color applicationStatusColor(ApplicationStatus s) => switch (s) {
  ApplicationStatus.pendingScreening => const Color(0xFFB8860B),
  ApplicationStatus.forwardedToOwner => ReportColors.blue,
  ApplicationStatus.approved => ReportColors.green,
  ApplicationStatus.rejected => ReportColors.red,
};

/// Plain-language explanation shown on the Application Details screen.
String applicationStatusMessage(AdoptionApplication a) => switch (a.status) {
  ApplicationStatus.pendingScreening =>
  'Your application was submitted and is waiting for the '
      "administrator's initial screening.",
  ApplicationStatus.forwardedToOwner =>
  'Your application passed screening and was forwarded to '
      '${a.posterName}, the pet owner, who will make the final decision.',
  ApplicationStatus.approved =>
  'Good news! ${a.posterName} approved your application for '
      '${a.petName}.',
  ApplicationStatus.rejected =>
  'Unfortunately, your application for ${a.petName} was not approved.',
};
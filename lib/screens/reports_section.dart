import 'package:flutter/material.dart';

import 'maps.dart';
import 'report.dart';

class ReportsSection extends StatelessWidget {
  /// false = show the Map (default), true = show the Reports Bulletin.
  final bool showBulletin;

  /// Called by the Map's "View All Reports" button.
  final VoidCallback onViewAllReports;

  /// Called by the Bulletin's "View Map" button.
  final VoidCallback onViewMap;

  const ReportsSection({
    super.key,
    required this.showBulletin,
    required this.onViewAllReports,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: showBulletin ? 1 : 0,
      children: [
        MapsPage(onViewAllReports: onViewAllReports),
        ReportsPage(onViewMap: onViewMap),
      ],
    );
  }
}
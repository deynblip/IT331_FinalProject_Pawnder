// File: lib/widgets/location_banner.dart  (NEW FILE)

import 'package:flutter/material.dart';

import '../services/report_service.dart';
import '../utils/app_colors.dart';

// ===============================
// LOCATION BANNER
// ===============================
// Shown when the app doesn't have the phone's location yet. The system
// permission pop-up appears only AFTER the user taps the button here.
// It hides itself when the location works.

class LocationBanner extends StatefulWidget {
  const LocationBanner({super.key});

  @override
  State<LocationBanner> createState() => _LocationBannerState();
}

class _LocationBannerState extends State<LocationBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from the phone's settings: try again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ReportService.locationProblem != null) {
      ReportService.refreshLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReportService.changes,
      builder: (context, _) {
        final String? problem = ReportService.locationProblem;
        if (problem == null || ReportService.myLat != null) {
          return const SizedBox.shrink();
        }

        final (String text, String button, IconData icon) = switch (problem) {
          'off' => (
          "Turn on your phone's location to see how far the reports are.",
          'Settings',
          Icons.location_off_outlined,
          ),
          'forever' => (
          'Location is blocked for Pawnder. Open Settings to allow it.',
          'Settings',
          Icons.location_off_outlined,
          ),
          'denied' => (
          'Location is not allowed. Allow it to see how far the reports are.',
          'Allow',
          Icons.location_off_outlined,
          ),
          _ => (
          'Use your location to see how far the reports are from you.',
          'Use location',
          Icons.my_location,
          ),
        };

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: kPeach,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: kBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: kNavy, fontSize: 12.5),
                ),
              ),
              TextButton(
                onPressed: ReportService.fixLocation,
                child: Text(
                  button,
                  style: const TextStyle(
                    color: kBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
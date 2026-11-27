import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/report_service.dart';
import '../models/stray_report.dart';
import '../widgets/report_card.dart';
import 'report_details_screen.dart';
import '../utils/responsive.dart';
import '../widgets/location_banner.dart';
import '../widgets/paw_banner.dart';

class HomePage extends StatefulWidget {
  final String name;

  /// Opens the Report a Stray screen (provided by MainLayout).
  final VoidCallback? onReportTap;

  /// Opens the Reports Bulletin inside the Reports tab (provided by MainLayout).
  final VoidCallback? onViewAllTap;

  const HomePage({
    super.key,
    required this.name,
    this.onReportTap,
    this.onViewAllTap,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Loads the reports from the database (and the phone's location).
    ReportService.ensureLoaded();
  }

  void _showComingSoon(BuildContext context, String page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$page is coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // The 2 nearest reports of OTHER users that are not rescued yet.
  // If the phone's location is unknown, the 2 newest are shown instead.
  List<StrayReport> get _nearby {
    final list = ReportService.all
        .where((r) => r.status != RescueStatus.rescued && !r.isMine)
        .toList()
      ..sort((a, b) {
        final byDistance = (a.distanceKm ?? double.infinity)
            .compareTo(b.distanceKm ?? double.infinity);
        if (byDistance != 0) return byDistance;
        return b.date.compareTo(a.date);
      });
    return list.take(2).toList();
  }

  void _openDetails(BuildContext context, StrayReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(
          report: report,
          onChanged: (_) {}, // the list updates itself (ReportService)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Row(
            children: [
              Text(
                'Welcome back, ',
                style: TextStyle(
                  color: kNavy,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),

              Expanded(
                child: Text(
                  widget.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Home banner (the card inside assets/home_banner.png).
          const PawBanner(),

          const SizedBox(height: 25),

          // Report a Stray
          Text(
            'See an animal in need?',
            style: TextStyle(
              color: kNavy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Report it so rescuers can find it.',
            style: TextStyle(
              color: kHintGray,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 15),

          _actionCard(
            icon: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: kPeach,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera, color: kBlue, size: 30),
            ),
            title: 'Report a Stray',
            onTap: () {
              if (widget.onReportTap != null) {
                widget.onReportTap!();
              } else {
                _showComingSoon(context, 'Report a Stray');
              }
            },
          ),

          const SizedBox(height: 30),

          // Nearby reports
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Reports',
                style: TextStyle(
                  color: kNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: widget.onViewAllTap,
                child: Text(
                  'View All',
                  style: TextStyle(color: kHintGray),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          const LocationBanner(),
          ListenableBuilder(
            listenable: ReportService.changes,
            builder: (context, _) {
              if (!ReportService.isLoaded) {
                if (ReportService.loadError != null) {
                  return _infoBox(
                    Icons.cloud_off_outlined,
                    ReportService.loadError!,
                    onRetry: ReportService.load,
                  );
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final nearby = _nearby;
              if (nearby.isEmpty) {
                return _infoBox(
                  Icons.location_on_outlined,
                  'No nearby reports yet',
                );
              }

              return Column(
                children: nearby
                    .map(
                      (r) => ReportCard(
                    report: r,
                    showStatus: false,
                    onTap: () => _openDetails(context, r),
                  ),
                )
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 30),

          // Safety guidelines
          Text(
            'Safety Guidelines',
            style: TextStyle(
              color: kNavy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Keep yourself and the animals safe.',
            style: TextStyle(
              color: kHintGray,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 15),

          _guidelineCard(
            icon: Icons.visibility_outlined,
            title: 'Keep a Safe Distance',
            description:
            'Observe stray animals from a safe distance. Avoid approaching unfamiliar animals.',
          ),

          _guidelineCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Protect Yourself',
            description:
            'Avoid touching or handling injured or frightened animals without proper assistance.',
          ),

          _guidelineCard(
            icon: Icons.camera_alt_outlined,
            title: 'Report Responsibly',
            description:
            'Provide accurate information and a clear photo when reporting a stray animal.',
          ),

          _guidelineCard(
            icon: Icons.favorite_border,
            title: 'Be Kind to Animals',
            description:
            'Treat every animal with patience and kindness. Avoid disturbing or frightening them.',
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Empty / error message box
  Widget _infoBox(IconData icon, String text, {VoidCallback? onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: kBlue, size: 35),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: kHintGray, fontSize: 14),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }

  // Quick action card
  Widget _actionCard({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 130),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: kCardColor,
          border: Border.all(color: kCardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14C4531F),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kNavy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Safety guideline card
  Widget _guidelineCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kCardColor,
        border: Border.all(color: kCardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14C4531F),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: kBlue,
            size: 28,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: kNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: TextStyle(
                    color: kHintGray,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
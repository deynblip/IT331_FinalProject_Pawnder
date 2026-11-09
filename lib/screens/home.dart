import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../data/mock_reports.dart';
import '../models/stray_report.dart';
import '../widgets/report_card.dart';
import 'report_details_screen.dart';

class HomePage extends StatelessWidget {
  final String name;

  /// Opens the Report a Stray screen (provided by MainLayout).
  final VoidCallback? onReportTap;

  /// Opens the Adopt screen (provided by MainLayout).
  final VoidCallback? onAdoptTap;

  /// Switches to the Reports tab (provided by MainLayout).
  final VoidCallback? onViewAllTap;

  const HomePage({
    super.key,
    required this.name,
    this.onReportTap,
    this.onAdoptTap,
    this.onViewAllTap,
  });

  void _showComingSoon(BuildContext context, String page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$page is coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 2 pinakamalapit na report na hindi pa rescued
  List<StrayReport> get _nearby {
    final list = mockReports
        .where((r) => r.status != RescueStatus.rescued)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return list.take(2).toList();
  }

  void _openDetails(BuildContext context, StrayReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(
          report: report,
          onChanged: (_) {}, // TEMP: ikakabit sa backend later
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearby = _nearby;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Row(
            children: [
              const Text(
                'Welcome back, ',
                style: TextStyle(
                  color: kNavy,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),

              Expanded(
                child: Text(
                  name,
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

          // Home banner
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              'assets/home_banner.png',
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 25),

          // Quick actions
          const Text(
            'What would you like to do?',
            style: TextStyle(
              color: kNavy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _actionCard(
                  emoji: '📷',
                  title: 'Report a Stray',
                  onTap: () {
                    if (onReportTap != null) {
                      onReportTap!();
                    } else {
                      _showComingSoon(context, 'Report a Stray');
                    }
                  },
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: _actionCard(
                  emoji: '🐾',
                  title: 'Adopt a Pet',
                  onTap: () {
                    if (onAdoptTap != null) {
                      onAdoptTap!();
                    } else {
                      _showComingSoon(context, 'Adopt a Pet');
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Nearby reports
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Reports',
                style: TextStyle(
                  color: kNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: onViewAllTap,
                child: const Text(
                  'View All',
                  style: TextStyle(color: kHintGray),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          if (nearby.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: kBlue,
                    size: 35,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No nearby reports yet',
                    style: TextStyle(
                      color: kHintGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...nearby.map(
                  (r) => ReportCard(
                report: r,
                showStatus: false,
                onTap: () => _openDetails(context, r),
              ),
            ),

          const SizedBox(height: 30),

          // Safety guidelines
          const Text(
            'Safety Guidelines',
            style: TextStyle(
              color: kNavy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
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

  // Quick action card
  Widget _actionCard({
    required String emoji,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 35),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
        color: const Color(0xFFF5F7FA),
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
                  style: const TextStyle(
                    color: kNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: const TextStyle(
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
import 'package:flutter/material.dart';

import '../../services/adoption_service.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../services/content_report_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/admin_top_bar.dart';
import '../../widgets/paw_banner.dart';

class AdminDashboard extends StatelessWidget {
  final String name;

  const AdminDashboard({super.key, required this.name});

  // Two stat cards side by side. IntrinsicHeight keeps both cards the same
  // height, even with bigger system text.
  Widget _statRow(Widget left, Widget right) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 14),
          Expanded(child: right),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fills the whole tab so the gradient always ends in cream.
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: kAdminGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MENU + LOGO + BELL
              const AdminTopBar(),
              const SizedBox(height: 16),

              // WELCOME TEXT (with paw watermark)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -10,
                    top: -20,
                    child: Icon(
                      Icons.pets,
                      size: 130,
                      color: kOrange.withValues(alpha: 0.08),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${name.isNotEmpty ? name : 'Admin'}!',
                        style: TextStyle(
                          color: kNavy,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage listings, applications, and keep\n'
                            'the community safe for stray animals',
                        style: TextStyle(
                          color: kHintGray,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // BANNER CARD (same as the user Home)
              const PawBanner(),

              const SizedBox(height: 20),

              // STAT CARDS (2 x 2). Rebuilds when the counts change.
              ListenableBuilder(
                listenable: Listenable.merge([
                  ApplicationService.changes,
                  AdoptionService.changes,
                  ContentReportService.changes,
                  AuthService.userCountChanges,
                ]),
                builder: (context, _) {
                  final int posts = AdoptionService.all.length;
                  final int applications = ApplicationService.all.length;
                  final int reported = ContentReportService.pendingCount;
                  final int users = AuthService.userCount;

                  return Column(
                    children: [
                      _statRow(
                        _StatCard(
                          icon: Icons.pets,
                          color: kBlue,
                          value: posts,
                          label: 'Adoption Posts',
                        ),
                        _StatCard(
                          icon: Icons.description,
                          color: kNavy,
                          value: applications,
                          label: 'Adoption\nApplications',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _statRow(
                        _StatCard(
                          icon: Icons.flag,
                          color: const Color(0xFFE04F4F),
                          value: reported,
                          label: 'Reported Content',
                        ),
                        _StatCard(
                          icon: Icons.groups,
                          color: const Color(0xFFE9A23B),
                          value: users,
                          label: 'Registered Users',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E2D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 42),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              color: kNavy,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: kBlue,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
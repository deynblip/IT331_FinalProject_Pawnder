import 'package:flutter/material.dart';

import '../../data/mock_reports.dart';
import '../../services/adoption_service.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class AdminDashboard extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;

  const AdminDashboard({
    super.key,
    required this.name,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6F8FC0), Color(0xFFDDE4F0), Colors.white],
          stops: [0.0, 0.4, 0.62],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LOGO + ACTIONS
              Row(
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset('assets/logo.png', height: 38),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    tooltip: 'Log Out',
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: onLogout,
                  ),
                ],
              ),
              const Divider(color: Colors.white54, height: 12),
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
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${name.isNotEmpty ? name : 'Admin'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Manage listings, applications, and keep\n'
                            'the community safe for stray animals',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // BANNER CARD
              const _Banner(),

              const SizedBox(height: 20),

              // STAT CARDS (2 x 2). Rebuilds when applications change.
              ValueListenableBuilder<int>(
                valueListenable: ApplicationService.changes,
                builder: (context, _, __) {
                  final int posts = AdoptionService.all.length;
                  final int applications = ApplicationService.all.length;
                  final int reported = mockReports.length;
                  final int users = AuthService.userCount;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.pets,
                              color: kBlue,
                              value: posts,
                              label: 'Adoption Posts',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.description,
                              color: kNavy,
                              value: applications,
                              label: 'Adoption\nApplications',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.flag,
                              color: const Color(0xFFD9534F),
                              value: reported,
                              label: 'Reported Content',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.groups,
                              color: const Color(0xFFC9805A),
                              value: users,
                              label: 'Registered Users',
                            ),
                          ),
                        ],
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

// White card, navy text, paws row cropped from assets/home_banner.png.
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Text(
              'Together, we can make a difference\nfor stray animals.',
              style: TextStyle(
                color: kNavy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
          _PawStrip(),
        ],
      ),
    );
  }
}

// Shows only the row of paws from home_banner.png (no new asset needed).
// If the crop looks off, adjust _x/_y/_w/_h (pixels in the original image).
class _PawStrip extends StatelessWidget {
  const _PawStrip();

  static const double _imgW = 1123;
  static const double _imgH = 1401;
  static const double _x = 29;
  static const double _y = 712;
  static const double _w = 1066;
  static const double _h = 176;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final double scale = c.maxWidth / _w;
        final double stripH = _h * scale;

        return SizedBox(
          width: c.maxWidth,
          height: stripH,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -_x * scale,
                top: -_y * scale,
                width: _imgW * scale,
                height: _imgH * scale,
                child: Image.asset(
                  'assets/home_banner.png',
                  fit: BoxFit.fill,
                ),
              ),
              // Fades the top of the strip into the white card.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: stripH * 0.5,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Color(0x00FFFFFF)],
                    ),
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
      height: 168,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 42), // was 30
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
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
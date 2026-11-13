import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/theme_controller.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? kDarkBg : Colors.white;
    final Color titleColor = isDark ? Colors.white : kNavy;
    final Color bodyColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final Color cardColor = isDark ? kDarkSurface : Colors.grey.shade50;
    final Color cardBorder = isDark ? Colors.white12 : Colors.grey.shade200;
    final Color accent = isDark ? kDarkAccent : kBlue;

    Widget feature(IconData icon, String title, String description) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: kBlue.withOpacity(0.15),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: bodyColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: titleColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'About Pawnder',
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white24 : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOGO + NAME
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset('assets/logo.png', height: 80),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pawnder',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Every Paw Deserves Help',
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: bodyColor, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Who We Are',
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pawnder is a community app that helps stray and injured '
                  'animals get the care they need. It connects people who spot '
                  'animals in need with those who can help, and gives rescued '
                  'pets a chance to find a loving home.',
              style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 24),

            Text(
              'Our Mission',
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To make it easier for everyone to report, rescue, and adopt, '
                  'so that no animal is left without help.',
              style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 24),

            Text(
              'What You Can Do',
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            feature(
              Icons.report_gmailerrorred_outlined,
              'Report a Stray',
              'Submit a report with photos and the animal\'s location so help can be arranged.',
            ),
            feature(
              Icons.map_outlined,
              'View the Map',
              'See reported animals near you and follow their rescue status.',
            ),
            feature(
              Icons.pets_outlined,
              'Adopt a Pet',
              'Browse pets looking for a home and submit an adoption application.',
            ),
            feature(
              Icons.volunteer_activism_outlined,
              'Post a Pet for Adoption',
              'Help a pet find a new family by posting it for adoption.',
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                'Made with care for animals in need.\n© 2026 Pawnder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
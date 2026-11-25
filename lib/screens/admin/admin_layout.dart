import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/adoption_service.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../services/content_report_service.dart';
import '../../services/rescuer_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../login.dart';
import 'admin_dashboard.dart';
import 'admin_posts_screen.dart';
import 'admin_applications_screen.dart';
import 'admin_reported_screen.dart';
import 'admin_rescuers_screen.dart';

// Admin shell: bottom navigation + the five admin tabs.
class AdminLayout extends StatefulWidget {
  final String name;

  const AdminLayout({super.key, required this.name});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  Timer? _poll;

  void _reload() {
    AdoptionService.load();
    ApplicationService.load();
    NotificationService.load();
    RescuerService.load();
    ContentReportService.load();
  }

  @override
  void initState() {
    super.initState();
    _reload();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _reload());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Out?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      AuthService.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  Widget _badged(IconData icon, int count) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AdminDashboard(name: widget.name, onLogout: _confirmLogout),
      const AdminPostsScreen(),
      const AdminApplicationsScreen(),
      const AdminReportedScreen(),
      const AdminRescuersScreen(), // Verified Rescuer applications
    ];

    return Scaffold(
      backgroundColor: kCream,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([
          RescuerService.changes,
          AdoptionService.changes,
          ApplicationService.changes,
          ContentReportService.changes,
        ]),
        builder: (context, _) {
          final pendingRescuers =
              RescuerService.pendingCount + RescuerService.flaggedCount;
          final pendingPosts = AdoptionService.pendingCount;
          final pendingApps = ApplicationService.pendingCount;
          final pendingReports = ContentReportService.pendingCount;

          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: kBlue,
            unselectedItemColor: kHintGray,
            showUnselectedLabels: true,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            onTap: (i) {
              setState(() => _selectedIndex = i);
              _reload();
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _badged(Icons.pets_outlined, pendingPosts),
                activeIcon: _badged(Icons.pets, pendingPosts),
                label: 'Posts',
              ),
              BottomNavigationBarItem(
                icon: _badged(Icons.insert_drive_file_outlined, pendingApps),
                activeIcon: _badged(Icons.insert_drive_file, pendingApps),
                label: 'Application',
              ),
              BottomNavigationBarItem(
                icon: _badged(Icons.flag_outlined, pendingReports),
                activeIcon: _badged(Icons.flag, pendingReports),
                label: 'Reported',
              ),
              BottomNavigationBarItem(
                icon: _badged(Icons.verified_user_outlined, pendingRescuers),
                activeIcon: _badged(Icons.verified_user, pendingRescuers),
                label: 'Rescuers',
              ),
            ],
          );
        },
      ),
    );
  }
}
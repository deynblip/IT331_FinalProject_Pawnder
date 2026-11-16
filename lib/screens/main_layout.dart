import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/theme_controller.dart';
import 'home.dart';
import 'reports_section.dart';
import 'report_stray.dart';
import 'adopt.dart';
import 'profile.dart';
import 'login.dart';
import 'drawer/about.dart';
import 'drawer/settings.dart';
import 'drawer/help_support.dart';
import 'drawer/terms_conditions.dart';
import 'drawer/privacy_policy.dart';

class MainLayout extends StatefulWidget {
  final String name;
  final String email; // needed by Settings > Change Password

  const MainLayout({
    super.key,
    required this.name,
    this.email = '',
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Tabs: 0 = Home, 1 = Reports, 2 = Adopt, 3 = Profile
  int _selectedIndex = 0;

  // Inside the Reports tab: false = Map (default), true = Reports Bulletin
  bool _showBulletin = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showComingSoon(String page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$page is coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Opens the "Report a Stray" form as its own screen (not a tab).
  void _openReportStray() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportStrayPage(),
      ),
    );
  }

  void _openHelpSupport(BuildContext drawerContext) {
    Navigator.pop(drawerContext);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpSupportPage()),
    );
  }

  void _openAbout(BuildContext drawerContext) {
    Navigator.pop(drawerContext);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutPage()),
    );
  }

  void _openSettings(BuildContext drawerContext) {
    Navigator.pop(drawerContext);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(email: widget.email),
      ),
    );
  }

  void _openTermsConditions(BuildContext drawerContext) {
    Navigator.pop(drawerContext);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsConditionsPage()),
    );
  }

  void _openPrivacyPolicy(BuildContext drawerContext) {
    Navigator.pop(drawerContext);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  // Asks the user to confirm before logging out.
  Future<void> _confirmLogout(BuildContext drawerContext) async {
    Navigator.pop(drawerContext); // close the drawer first

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color shellBg = isDark ? kDarkSurface : Colors.white;
    final Color iconColor = isDark ? Colors.white : kNavy;
    final Color lineColor = isDark ? Colors.white24 : const Color(0xFFE5E5E5);

    // Order must match the bottom navigation items below:
    // Home, Reports, Adopt, Profile
    final List<Widget> pages = [
      HomePage(
        name: widget.name,
        onReportTap: _openReportStray,
        onViewAllTap: () => setState(() {
          _selectedIndex = 1;
          _showBulletin = true;
        }),
      ),
      ReportsSection(
        showBulletin: _showBulletin,
        onViewAllReports: () => setState(() => _showBulletin = true),
        onViewMap: () => setState(() => _showBulletin = false),
      ),
      AdoptPage(
        posterName: widget.name.trim().isNotEmpty ? widget.name : 'Dane Angela',
      ),
      ProfilePage(
        name: widget.name,
        onBrowseAdoptions: () => setState(() => _selectedIndex = 2),
      ),
    ];

    return PopScope(
      canPop: !(_selectedIndex == 1 && _showBulletin),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final scaffold = _scaffoldKey.currentState;
        if (scaffold != null && scaffold.isDrawerOpen) {
          scaffold.closeDrawer();
          return;
        }
        setState(() => _showBulletin = false);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: shellBg,

        // APP BAR
        appBar: AppBar(
          backgroundColor: shellBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (drawerContext) {
              return IconButton(
                icon: Icon(Icons.menu, color: iconColor),
                onPressed: () => Scaffold.of(drawerContext).openDrawer(),
              );
            },
          ),
          title: Image.asset('assets/logo.png', height: 40),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_none, color: iconColor),
              onPressed: () => _showComingSoon('Notifications'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: lineColor),
          ),
        ),

        // DRAWER
        drawer: Drawer(
          backgroundColor: shellBg,
          child: SafeArea(
            child: Column(
              children: [
                // DRAWER HEADER
                Container(
                  width: double.infinity,
                  height: 160,
                  color: kBlue,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: kBlue, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.name.isNotEmpty ? widget.name : 'Pawnder User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // GENERAL MENU ITEMS
                _drawerItem(
                  Icons.help_outline,
                  'Help & Support',
                  onTap: _openHelpSupport,
                ),
                _drawerItem(
                  Icons.info_outline,
                  'About Pawnder',
                  onTap: _openAbout,
                ),
                _drawerItem(
                  Icons.settings_outlined,
                  'Settings',
                  onTap: _openSettings,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: lineColor, thickness: 1),
                ),

                // LEGAL MENU ITEMS
                _drawerItem(
                  Icons.description_outlined,
                  'Terms & Conditions',
                  onTap: _openTermsConditions,
                ),
                _drawerItem(
                  Icons.privacy_tip_outlined,
                  'Privacy Policy',
                  onTap: _openPrivacyPolicy,
                ),

                const Spacer(),

                Divider(color: lineColor),

                // LOG OUT (asks for confirmation first)
                Builder(
                  builder: (drawerContext) {
                    return ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () => _confirmLogout(drawerContext),
                    );
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // PAGE CONTENT
        // The tab pages still use fixed light colors, so the content area
        // stays white even in dark mode (see note below the code).
        body: SafeArea(
          child: ColoredBox(
            color: Colors.white,
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ),

        // BOTTOM NAVIGATION: Home, Reports, Adopt, Profile
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: shellBg,
          selectedItemColor: isDark ? kDarkAccent : kBlue,
          unselectedItemColor: kHintGray,
          showUnselectedLabels: true,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              if (index == 1) _showBulletin = false;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_outlined),
              activeIcon: Icon(Icons.pets),
              label: 'Adopt',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // DRAWER MENU ITEM
  Widget _drawerItem(
      IconData icon,
      String title, {
        Function(BuildContext)? onTap,
      }) {
    return Builder(
      builder: (drawerContext) {
        final bool isDark = Theme.of(drawerContext).brightness == Brightness.dark;
        final Color color = isDark ? Colors.white : kNavy;

        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            if (onTap != null) {
              onTap(drawerContext);
            } else {
              Navigator.pop(drawerContext);
              _showComingSoon(title);
            }
          },
        );
      },
    );
  }
}
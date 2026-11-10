import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'home.dart';
import 'reports_section.dart';
import 'report_stray.dart';
import 'adopt.dart';
import 'profile.dart';
import 'login.dart';
import 'drawer/help_support.dart';
import 'drawer/terms_conditions.dart';

class MainLayout extends StatefulWidget {
  final String name;

  const MainLayout({
    super.key,
    required this.name,
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
      MaterialPageRoute(
        builder: (context) => const HelpSupportPage(),
      ),
    );
  }

  void _openTermsConditions(BuildContext drawerContext) {
    Navigator.pop(drawerContext);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsConditionsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Order must match the bottom navigation items below:
    // Home, Reports, Adopt, Profile
    final List<Widget> pages = [
      HomePage(
        name: widget.name,
        onReportTap: _openReportStray,
        // Home's "View All" opens the Reports tab directly on the Bulletin.
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
      ProfilePage(name: widget.name),
    ];

    // Android Back button: while the Bulletin is showing, go back to the Map
    // instead of leaving the screen. In every other case Back behaves as before.
    return PopScope(
      canPop: !(_selectedIndex == 1 && _showBulletin),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final scaffold = _scaffoldKey.currentState;
        if (scaffold != null && scaffold.isDrawerOpen) {
          scaffold.closeDrawer(); // an open drawer closes first
          return;
        }
        setState(() => _showBulletin = false);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,

        // APP BAR
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,

          leading: Builder(
            builder: (drawerContext) {
              return IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: kNavy,
                ),
                onPressed: () {
                  Scaffold.of(drawerContext).openDrawer();
                },
              );
            },
          ),

          title: Image.asset(
            'assets/logo.png',
            height: 40,
          ),

          centerTitle: true,

          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: kNavy,
              ),
              onPressed: () => _showComingSoon('Notifications'),
            ),
          ],

          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE5E5E5),
            ),
          ),
        ),

        // DRAWER
        drawer: Drawer(
          backgroundColor: Colors.white,
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
                        child: Icon(
                          Icons.person,
                          color: kBlue,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        widget.name.isNotEmpty
                            ? widget.name
                            : 'Pawnder User',
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
                  onTap: (drawerContext) {
                    _openHelpSupport(drawerContext);
                  },
                ),

                _drawerItem(
                  Icons.info_outline,
                  'About Pawnder',
                ),

                _drawerItem(
                  Icons.settings_outlined,
                  'Settings',
                ),

                // DIVIDER
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: Color(0xFFE5E5E5),
                    thickness: 1,
                  ),
                ),

                // LEGAL MENU ITEMS
                _drawerItem(
                  Icons.description_outlined,
                  'Terms & Conditions',
                  onTap: (drawerContext) {
                    _openTermsConditions(drawerContext);
                  },
                ),

                _drawerItem(
                  Icons.privacy_tip_outlined,
                  'Privacy Policy',
                ),

                const Spacer(),

                const Divider(),

                // LOG OUT
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                          (route) => false,
                    );
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // PAGE CONTENT
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
        ),

        // BOTTOM NAVIGATION: Home, Reports, Adopt, Profile
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: kBlue,
          unselectedItemColor: kHintGray,
          showUnselectedLabels: true,

          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              // Selecting Reports always opens the Map (the default view).
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
        return ListTile(
          leading: Icon(
            icon,
            color: kNavy,
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: kNavy,
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
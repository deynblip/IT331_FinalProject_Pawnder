import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'home.dart';
import 'report.dart';
import 'adopt.dart';
import 'maps.dart';
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
  int _selectedIndex = 0;

  void _showComingSoon(String page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$page is coming soon!'),
        duration: const Duration(seconds: 2),
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
    final List<Widget> pages = [
      HomePage(name: widget.name),
      const ReportPage(),
      const AdoptPage(),
      const MapsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
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

      // BOTTOM NAVIGATION
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
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Report',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Adopt',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Maps',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
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
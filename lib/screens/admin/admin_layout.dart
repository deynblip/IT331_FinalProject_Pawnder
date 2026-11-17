import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../login.dart';
import 'admin_dashboard.dart';
import 'admin_posts_screen.dart';
import 'admin_applications_screen.dart';

// Admin shell: bottom navigation + the four admin tabs.
class AdminLayout extends StatefulWidget {
  final String name;

  const AdminLayout({super.key, required this.name});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

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

  Widget _placeholder(String title) {
    return SafeArea(
      child: Center(
        child: Text(
          '$title\n(coming soon)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kNavy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AdminDashboard(name: widget.name, onLogout: _confirmLogout),
      const AdminPostsScreen(), // <-- the new Animal Adoptions page
      const AdminApplicationsScreen(),
      _placeholder('Reported Content'),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: kBlue,
        unselectedItemColor: kHintGray,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_drive_file_outlined),
            activeIcon: Icon(Icons.insert_drive_file),
            label: 'Application',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'Reported',
          ),
        ],
      ),
    );
  }
}
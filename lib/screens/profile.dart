import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/mock_reports.dart';
import '../utils/app_colors.dart';
import 'my_reports_screen.dart';

class ProfilePage extends StatefulWidget {
  final String name;

  const ProfilePage({super.key, required this.name});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // TEMP: papalitan ng totoong bilang galing backend kapag tapos na ang Adoption
  static const int _applicationsCount = 1;
  static const int _postsCount = 1;

  final ImagePicker _picker = ImagePicker();

  // Naka-bytes para gumana sa phone at sa Chrome (web)
  // TEMP: mawawala ito kapag nag-restart ang app. Ise-save sa backend later.
  Uint8List? _photoBytes;

  void _comingSoon(String page) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$page is coming soon!')));
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (mounted) setState(() => _photoBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            // Walang camera sa Chrome, kaya gallery lang doon
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera, color: kBlue),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhoto(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: kBlue),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _photoBytes = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    const double size = 120;

    final Widget picture = _photoBytes != null
        ? Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: kNavy, width: 4),
      ),
      child: ClipOval(
        child: Image.memory(
          _photoBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    )
    // Default: ang avatar.png mo (may ring na siya)
        : Image.asset(
      'assets/images/avatar.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: kNavy, width: 4),
        ),
        child: const Icon(Icons.person, size: 80, color: kNavy),
      ),
    );

    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Stack(
        children: [
          picture,
          // Maliit na camera badge para halatang pwedeng palitan
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: kBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsCount = mockReports.where((r) => r.isMine).length;
    final displayName =
    widget.name.trim().isNotEmpty ? widget.name : 'Pawnder User';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        children: [
          _avatar(),

          const SizedBox(height: 14),

          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kNavy,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 36),

          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 6),
              child: Text(
                'My Activity',
                style: TextStyle(
                  color: kNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE3E5EA)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _activityRow(
                  icon: Icons.assignment_outlined,
                  title: 'My Reports',
                  count: reportsCount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyReportsScreen()),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE3E5EA)),
                _activityRow(
                  icon: Icons.pets,
                  title: 'Adoption Applications',
                  count: _applicationsCount,
                  onTap: () => _comingSoon('Adoption Applications'),
                ),
                const Divider(height: 1, color: Color(0xFFE3E5EA)),
                _activityRow(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'My Adoption Posts',
                  count: _postsCount,
                  onTap: () => _comingSoon('My Adoption Posts'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow({
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: kNavy, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: kNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(color: kHintGray, fontSize: 17),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: kHintGray),
          ],
        ),
      ),
    );
  }
}
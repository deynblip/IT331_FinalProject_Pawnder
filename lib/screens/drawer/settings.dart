import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/theme_controller.dart';
import '../../utils/validators.dart';

// ===============================
// SETTINGS PAGE
// ===============================

class SettingsPage extends StatefulWidget {
  final String email;

  const SettingsPage({super.key, this.email = ''});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // The notification switches live in NotificationService, so the bell and
  // the Notifications screen follow them. (They reset when the app restarts;
  // save with shared_preferences later.)

  bool get _isDark => themeModeNotifier.value == ThemeMode.dark;

  void _openChangePassword() {
    if (widget.email.trim().isEmpty) {
      showMessage(context, 'Could not find your account. Please log in again.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordPage(email: widget.email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? kDarkBg : Colors.white;
    final Color titleColor = isDark ? Colors.white : kNavy;
    final Color subColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final Color cardColor = isDark ? kDarkSurface : Colors.grey.shade50;
    final Color cardBorder = isDark ? Colors.white12 : Colors.grey.shade200;
    final Color accent = isDark ? kDarkAccent : kBlue;

    Widget sectionLabel(String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    Widget card(List<Widget> children) {
      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Column(children: children),
      );
    }

    Widget divider() => Divider(height: 1, color: cardBorder);

    Widget switchTile({
      required IconData icon,
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return SwitchListTile(
        secondary: Icon(icon, color: accent),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: subColor, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
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
          'Settings',
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // APPEARANCE
          sectionLabel('Appearance'),
          card([
            switchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Use a darker theme for the app',
              value: _isDark,
              onChanged: (value) {
                themeModeNotifier.value =
                value ? ThemeMode.dark : ThemeMode.light;
                setState(() {});
              },
            ),
          ]),

          // NOTIFICATIONS
          sectionLabel('Notifications'),
          card([
            switchTile(
              icon: Icons.notifications_active_outlined,
              title: 'Push Notifications',
              subtitle: 'Allow Pawnder to send you notifications',
              value: NotificationService.pushEnabled,
              onChanged: (v) =>
                  setState(() => NotificationService.setPushEnabled(v)),
            ),
            divider(),
            switchTile(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Report Updates',
              subtitle: 'Get notified when your report status changes',
              value: NotificationService.reportUpdates,
              onChanged: (v) =>
                  setState(() => NotificationService.setReportUpdates(v)),
            ),
            divider(),
            switchTile(
              icon: Icons.pets_outlined,
              title: 'Adoption Updates',
              subtitle: 'Get notified about your adoption applications',
              value: NotificationService.adoptionUpdates,
              onChanged: (v) =>
                  setState(() => NotificationService.setAdoptionUpdates(v)),
            ),
          ]),

          // ACCOUNT
          sectionLabel('Account'),
          card([
            ListTile(
              leading: Icon(Icons.lock_outline, color: accent),
              title: Text(
                'Change Password',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Update the password for your account',
                style: TextStyle(color: subColor, fontSize: 12),
              ),
              trailing: Icon(Icons.chevron_right, color: subColor),
              onTap: _openChangePassword,
            ),
          ]),

          // APP INFO
          sectionLabel('App'),
          card([
            ListTile(
              leading: Icon(Icons.info_outline, color: accent),
              title: Text(
                'Version',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: Text(
                '1.0.0',
                style: TextStyle(color: subColor, fontSize: 13),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ===============================
// CHANGE PASSWORD PAGE
// ===============================

class ChangePasswordPage extends StatefulWidget {
  final String email;

  const ChangePasswordPage({super.key, required this.email});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final current = _currentController.text;
    final newPassword = _newController.text;

    if (!AuthService.passwordMatches(widget.email, current)) {
      showMessage(context, 'Your current password is incorrect.');
      return;
    }

    AuthService.updatePassword(widget.email, newPassword);
    showMessage(context, 'Password changed successfully!');
    Navigator.pop(context);
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hidden,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? kDarkBg : Colors.white;
    final Color titleColor = isDark ? Colors.white : kNavy;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: titleColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Change Password',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your current password, then choose a new one '
                    '(at least 6 characters).',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              _field(
                label: 'Current Password',
                controller: _currentController,
                hidden: _hideCurrent,
                onToggle: () => setState(() => _hideCurrent = !_hideCurrent),
                validator: validatePassword,
              ),
              const SizedBox(height: 14),

              _field(
                label: 'New Password',
                controller: _newController,
                hidden: _hideNew,
                onToggle: () => setState(() => _hideNew = !_hideNew),
                validator: (value) {
                  final error = validatePassword(value);
                  if (error != null) return error;
                  if (value == _currentController.text) {
                    return 'New password must be different from the current one';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              _field(
                label: 'Confirm New Password',
                controller: _confirmController,
                hidden: _hideConfirm,
                onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Save Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_widgets.dart';

// ===============================
// FORGOT PASSWORD PAGE
// ===============================
// Step 1: enter the email of your account.
// Step 2: choose a new password.
// (With a real backend like Firebase, step 2 would instead be an emailed
// reset link, e.g. FirebaseAuth.instance.sendPasswordResetEmail(...).)

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  late final TextEditingController emailController;
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool _emailVerified = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_emailFormKey.currentState!.validate()) return;

    if (!AuthService.emailExists(emailController.text)) {
      showMessage(context, 'No account found with this email.');
      return;
    }

    setState(() => _emailVerified = true);
  }

  void _resetPassword() {
    if (!_passwordFormKey.currentState!.validate()) return;

    AuthService.updatePassword(
      emailController.text,
      newPasswordController.text,
    );

    showMessage(context, 'Password updated! Please log in.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      panelTopFraction: 0.35,
      curveOnRight: true,
      title: _emailVerified ? 'Reset Password' : 'Forgot Password?',
      children: [
        if (!_emailVerified) ...[
          const Text(
            "Enter the email you signed up with and we'll help you reset your password.",
            textAlign: TextAlign.center,
            style: TextStyle(color: kHintGray, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 22),
          Form(
            key: _emailFormKey,
            child: Column(
              children: [
                AuthField(
                  label: 'Email',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                ),
                const SizedBox(height: 22),
                AuthButton(text: 'Continue', onPressed: _continue),
              ],
            ),
          ),
        ] else ...[
          Text(
            'Choose a new password for\n${emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kHintGray, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 22),
          Form(
            key: _passwordFormKey,
            child: Column(
              children: [
                AuthField(
                  label: 'New Password',
                  controller: newPasswordController,
                  obscure: true,
                  validator: validatePassword,
                ),
                const SizedBox(height: 14),
                AuthField(
                  label: 'Confirm New Password',
                  controller: confirmPasswordController,
                  obscure: true,
                  validator: (value) {
                    final basic = validatePassword(value);
                    if (basic != null) return basic;
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                AuthButton(text: 'Reset Password', onPressed: _resetPassword),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        AuthLink(
          text: 'Back to log in',
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

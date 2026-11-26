import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_widgets.dart';

// ===============================
// FORGOT PASSWORD PAGE
// ===============================

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
  final TextEditingController codeController = TextEditingController();
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
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _busy = false;

  // Step 1: send the reset code to the email.
  Future<void> _continue() async {
    if (_busy) return;
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await AuthService.sendPasswordResetCode(emailController.text);
    } on AuthFailure catch (e) {
      if (mounted) showAuthMessage(context, e.message);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;

    showAuthMessage(
      context,
      'If an account exists for this email, we sent a reset code to it.',
    );
    setState(() => _emailVerified = true);
  }

  // Step 2: check the code and save the new password.
  Future<void> _resetPassword() async {
    if (_busy) return;
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await AuthService.resetPasswordWithCode(
        email: emailController.text,
        code: codeController.text,
        newPassword: newPasswordController.text,
      );
    } on AuthFailure catch (e) {
      if (mounted) showAuthMessage(context, e.message);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;

    showAuthMessage(context, 'Password updated! Please log in.');
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
          Text(
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
                AuthButton(
                  text: _busy ? 'Sending...' : 'Send Code',
                  onPressed: _continue,
                ),
              ],
            ),
          ),
        ] else ...[
          Text(
            'Enter the code we sent to\n${emailController.text.trim()}\nand choose a new password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kHintGray, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 22),
          Form(
            key: _passwordFormKey,
            child: Column(
              children: [
                AuthField(
                  label: 'Code from Email',
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Please enter the code from your email';
                    if (!RegExp(r'^\d{6,10}$').hasMatch(v)) {
                      return 'Please enter the numbers from your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
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
                AuthButton(
                  text: _busy ? 'Saving...' : 'Reset Password',
                  onPressed: _resetPassword,
                ),
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
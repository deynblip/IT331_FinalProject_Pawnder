import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_widgets.dart';
import 'admin/admin_layout.dart';
import 'login.dart';
import 'main_layout.dart';

// ===============================
// VERIFY EMAIL PAGE
// ===============================
// Shown after Sign Up (and when someone logs in with an email that is not
// verified yet). The user types the code from the email. When it is right,
// the account is verified and the user goes straight into the app.

class VerifyEmailPage extends StatefulWidget {
  final String email;

  /// True for Professional Rescuer sign ups (changes the welcome message).
  final bool applying;

  const VerifyEmailPage({
    super.key,
    required this.email,
    this.applying = false,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();

  bool _busy = false;
  bool _resending = false;

  // Seconds before the user can ask for another code.
  int _cooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await AuthService.verifyEmailCode(
        email: widget.email,
        code: codeController.text,
      );
    } on AuthFailure catch (e) {
      if (mounted) showMessage(context, e.message);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;

    showMessage(
      context,
      widget.applying
          ? 'Email verified! Your rescuer application is pending verification.'
          : 'Email verified! Welcome to Pawnder.',
    );

    final String name = AuthService.currentName;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => AuthService.isCurrentAdmin
            ? AdminLayout(name: name)
            : MainLayout(
          name: name,
          email: AuthService.currentEmail ?? widget.email.toLowerCase(),
        ),
      ),
          (route) => false,
    );
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;

    setState(() => _resending = true);
    try {
      await AuthService.resendSignupCode(widget.email);
      if (!mounted) return;
      showMessage(context, 'We sent a new code to ${widget.email}.');
      setState(_startCooldown);
    } on AuthFailure catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      panelTopFraction: 0.35,
      curveOnRight: true,
      title: 'Verify Your Email',
      children: [
        Text(
          'We sent a code to\n${widget.email}\nEnter it below to finish creating your account.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: kHintGray, fontSize: 13, height: 1.3),
        ),
        const SizedBox(height: 22),
        Form(
          key: _formKey,
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
              const SizedBox(height: 22),
              AuthButton(
                text: _busy ? 'Verifying...' : 'Verify',
                onPressed: _verify,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Can't find it? Check your Spam folder.",
          textAlign: TextAlign.center,
          style: TextStyle(color: kHintGray, fontSize: 12),
        ),
        const SizedBox(height: 6),
        AuthLink(
          text: _cooldown > 0
              ? 'Resend code in ${_cooldown}s'
              : (_resending ? 'Sending...' : 'Resend code'),
          onTap: _resend,
        ),
        const SizedBox(height: 10),
        AuthLink(
          text: 'Back to log in',
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'admin/admin_layout.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_widgets.dart';

import 'signup.dart';
import 'forgot_password.dart';
import 'main_layout.dart';
import 'verify_email.dart';

// ===============================
// LOG IN PAGE
// ===============================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _busy = false;

  // The email is not verified yet: send a new code, then show Enter code.
  Future<void> _goToVerify(String email) async {
    try {
      await AuthService.resendSignupCode(email);
    } on AuthFailure catch (_) {
      // Too soon for a new email? The user can still use the earlier code.
    }
    if (!mounted) return;
    showAuthMessage(context, 'Please verify your email first. Enter the code we sent you.');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VerifyEmailPage(email: email)),
    );
  }

  Future<void> _logIn() async {
    if (_busy) return;

    // 1. Check the format of the email and password
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    // 2. Log in with Supabase (checks the email and password)
    setState(() => _busy = true);
    try {
      await AuthService.logIn(email, password);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      if (e.emailNotConfirmed) {
        await _goToVerify(email);
        return;
      }
      showAuthMessage(context, e.message);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;

    // 3. Login successful. Admins go to the dashboard, everyone else to the app.
    final String name = AuthService.currentName;
    final String userEmail = AuthService.currentEmail ?? email.toLowerCase();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => AuthService.isCurrentAdmin
            ? AdminLayout(name: name)
            : MainLayout(name: name, email: userEmail),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      panelTopFraction: 0.35,
      curveOnRight: true,
      title: 'Welcome Back!',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthField(
                label: 'Email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
              ),

              const SizedBox(height: 14),

              AuthField(
                label: 'Password',
                controller: passwordController,
                obscure: true,
                validator: validatePassword,
              ),

              const SizedBox(height: 22),

              AuthButton(
                text: _busy ? 'Logging in...' : 'Log In',
                onPressed: _logIn,
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        AuthLink(
          text: 'Forgot password?',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ForgotPasswordPage(
                  initialEmail: emailController.text.trim(),
                ),
              ),
            );
          },
        ),

        AuthLink(
          text: "Don't have an account? Sign up here.",
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SignUpPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_widgets.dart';

import 'signup.dart';
import 'forgot_password.dart';
import 'main_layout.dart';

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

  void _logIn() {
    // 1. Check the format of the email and password
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    // 2. Check that the account exists
    if (!AuthService.emailExists(email)) {
      showMessage(context, 'No account found with this email.');
      return;
    }

    // 3. Check that the password is correct
    if (!AuthService.passwordMatches(email, password)) {
      showMessage(context, 'Incorrect password. Please try again.');
      return;
    }

    // 4. Login successful
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainLayout(
          name: AuthService.nameOf(email) ?? '',
        ),
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
                text: 'Log In',
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
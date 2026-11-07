import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_widgets.dart';

import 'login.dart';

// ===============================
// SIGN UP PAGE
// ===============================

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();

    if (AuthService.emailExists(email)) {
      showMessage(context, 'An account with this email already exists.');
      return;
    }

    AuthService.register(
      nameController.text,
      email,
      passwordController.text,
    );

    showMessage(context, 'Account created! Please log in.');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      panelTopFraction: 0.37,
      curveOnRight: false,
      title: 'Create An Account',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthField(
                label: 'Name',
                controller: nameController,
                validator: validateName,
              ),
              const SizedBox(height: 14),
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
              AuthButton(text: 'Sign Up', onPressed: _signUp),
            ],
          ),
        ),
        const SizedBox(height: 22),
        AuthLink(
          text: 'Already have an account? Log in here.',
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
      ],
    );
  }
}

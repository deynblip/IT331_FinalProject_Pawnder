import 'package:flutter/material.dart';
import 'app_colors.dart';

// ===============================
// VALIDATORS
// ===============================

final RegExp emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Please enter your email';
  if (!emailRegex.hasMatch(v)) return 'Please enter a valid email address';
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Please enter your password';
  if (v.length < 6) return 'Password must be at least 6 characters';
  return null;
}

String? validateName(String? value) {
  if ((value?.trim() ?? '').isEmpty) return 'Please enter your name';
  return null;
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kNavy,
      ),
    );
}

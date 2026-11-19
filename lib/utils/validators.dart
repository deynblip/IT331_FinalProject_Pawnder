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

String? Function(String?) requiredField(String message) {
  return (value) => (value?.trim().isEmpty ?? true) ? message : null;
}

String? validateContactNumber(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Please enter a contact number';
  final digits = v.replaceAll(RegExp(r'[\s\-+()]'), '');
  if (!RegExp(r'^\d{7,13}$').hasMatch(digits)) {
    return 'Please enter a valid contact number';
  }
  return null;
}

String? validateOfficialPage(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Please enter the official page or website';
  if (v.contains(' ') || !v.contains('.')) {
    return 'Please enter a valid page or website link';
  }
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
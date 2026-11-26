import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Red color of the required-field asterisk.
const Color kRequiredColor = Color(0xFFE04F4F);

/// A form label. When [required] is true, a red " *" is added after it,
/// so users can see which fields they must fill in.
class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  final TextStyle? style;

  const FieldLabel(
      this.text, {
        super.key,
        this.required = false,
        this.style,
      });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: style ??
            TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: kNavy,
            ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: kRequiredColor),
            ),
        ],
      ),
    );
  }
}

/// Small note shown at the top of a form.
class RequiredNote extends StatelessWidget {
  const RequiredNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 12, color: kHintGray),
        children: [
          TextSpan(text: 'Fields marked with '),
          TextSpan(text: '*', style: TextStyle(color: kRequiredColor)),
          TextSpan(text: ' are required.'),
        ],
      ),
    );
  }
}
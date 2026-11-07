import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class AdoptPage extends StatelessWidget {
  const AdoptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Adopt a Pet',
          style: TextStyle(
            color: kNavy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
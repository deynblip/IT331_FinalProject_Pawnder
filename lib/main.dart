import 'package:flutter/material.dart';

import 'screens/welcome.dart';
import 'utils/app_colors.dart';

void main() {
  runApp(const PawnderApp());
}

class PawnderApp extends StatelessWidget {
  const PawnderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pawnder',
      theme: ThemeData(
        fontFamily: 'Nunito',
        colorScheme: ColorScheme.fromSeed(seedColor: kBlue),
      ),
      home: const WelcomePage(),
    );
  }
}
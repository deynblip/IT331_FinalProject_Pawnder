import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// ===============================
// SHARED AUTH LAYOUT (background + logo + curved white panel)
// ===============================

class AuthLayout extends StatelessWidget {
  final double panelTopFraction; // where the white panel starts (0-1 of height)
  final bool curveOnRight; // true = rounded top-right, false = top-left
  final String title;
  final List<Widget> children;

  const AuthLayout({
    super.key,
    required this.panelTopFraction,
    required this.curveOnRight,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double panelTop = size.height * panelTopFraction;
    const double curveRadius = 70;

    return Scaffold(
      backgroundColor: kCream,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Logo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: panelTop,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, left: 24, right: 24),
                  child: Image.asset(
                    'assets/logo.png',
                    width: size.width * 0.85,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // White panel
          Positioned(
            top: panelTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: curveOnRight
                      ? const Radius.circular(curveRadius)
                      : Radius.zero,
                  topLeft: curveOnRight
                      ? Radius.zero
                      : const Radius.circular(curveRadius),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    children: [
                      const SizedBox(height: 36),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kNavy,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ...children,
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
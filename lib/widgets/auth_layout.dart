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
    final double keyboard = MediaQuery.of(context).viewInsets.bottom;
    final bool typing = keyboard > 0;
    final double logoZone = size.height * panelTopFraction;
    final double panelTop = typing ? size.height * 0.12 : logoZone;
    const double curveRadius = 70;

    return Scaffold(
      backgroundColor: kCream,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: logoZone,
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
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            top: panelTop,
            left: 0,
            right: 0,
            bottom: keyboard,
            child: Container(
              // Clip so nothing scrolls outside the rounded corner
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: kCardColor,
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
                bottom: !typing,
                child: Column(
                  children: [
                    // Title stays fixed; only the fields scroll below it
                    Padding(
                      padding: const EdgeInsets.fromLTRB(36, 32, 36, 14),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kNavy,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(36, 10, 36, 24),
                        child: Column(children: children),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
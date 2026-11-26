import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/response_service.dart';
import '../utils/app_colors.dart';
import 'admin/admin_layout.dart';
import 'main_layout.dart';
import 'signup.dart';

// ===============================
// WELCOME PAGE
// ===============================
// With checkSession = true this is also the loading screen: only the logo
// and a progress bar show while the session is checked. Then it either goes
// to Home / Admin, or fades in the phrase and the Get Started button.

enum _Stage { loading, offline, ready }

class WelcomePage extends StatefulWidget {
  final bool checkSession;

  // The app opens first, then the database connects. This is that wait.
  final Future<void>? waitFor;

  const WelcomePage({super.key, this.checkSession = false, this.waitFor});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _buttonFade;
  late final Animation<double> _buttonScale;

  late _Stage _stage;

  @override
  void initState() {
    super.initState();

    _stage = widget.checkSession ? _Stage.loading : _Stage.ready;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo: 0.0 -> 0.3
    final logoCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _logoFade = logoCurve;
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(logoCurve);

    // Tagline: 0.4 -> 0.75
    final textCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
    );
    _textFade = textCurve;
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(textCurve);

    // Button: 0.65 -> 1.0 (pops in)
    final buttonCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutBack),
    );
    _buttonFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.9, curve: Curves.easeOut),
    );
    _buttonScale = Tween<double>(begin: 0.6, end: 1.0).animate(buttonCurve);

    if (widget.checkSession) {
      // Logo only for now; the rest shows after the session check.
      _controller.animateTo(0.3);
      _checkSession();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    if (_stage != _Stage.loading) setState(() => _stage = _Stage.loading);

    // Wait for the database to connect (it starts while this screen shows).
    try {
      await widget.waitFor;
    } catch (_) {
      if (mounted) setState(() => _stage = _Stage.offline);
      return;
    }
    if (!mounted) return;

    // Small minimum time so the progress bar does not just flash.
    final results = await Future.wait<Object?>([
      AuthService.restoreSession(),
      Future<void>.delayed(const Duration(milliseconds: 800)),
    ]);
    if (!mounted) return;

    final SessionStatus status = results[0] as SessionStatus;

    switch (status) {
      case SessionStatus.ready:
        if (AuthService.isCurrentAdmin) {
          _goTo(AdminLayout(name: AuthService.currentName));
        } else {
          unawaited(ResponseService.loadMe());
          _goTo(MainLayout(
            name: AuthService.currentName,
            email: AuthService.currentEmail ?? '',
          ));
        }
      case SessionStatus.none:
        _showWelcome();
      case SessionStatus.restricted:
        _showWelcome();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account has been restricted.')),
        );
      case SessionStatus.offline:
        setState(() => _stage = _Stage.offline);
    }
  }

  void _showWelcome() {
    setState(() => _stage = _Stage.ready);
    _controller.forward();
  }

  void _goTo(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _logOut() async {
    await AuthService.signOut();
    if (mounted) _showWelcome();
  }

  Widget _loadingBar(double width) {
    return SizedBox(
      key: const ValueKey('loading'),
      width: width * 0.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          minHeight: 6,
          color: kOrange,
          backgroundColor: kOrange.withAlpha(50),
        ),
      ),
    );
  }

  Widget _offlineBox() {
    return Column(
      key: const ValueKey('offline'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Can't connect. Try again.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kNavy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Please check your internet connection.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kNavy),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _checkSession,
          style: ElevatedButton.styleFrom(
            backgroundColor: kOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
        TextButton(
          onPressed: _logOut,
          child: const Text('Log out'),
        ),
      ],
    );
  }

  Widget _getStartedButton() {
    return FadeTransition(
      opacity: _buttonFade,
      child: ScaleTransition(
        scale: _buttonScale,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpPage()),
            );
          },
          icon: const Icon(Icons.pets, size: 22, color: kBlue),
          label: const Text(
            'Get Started',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kButtonBlue,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool ready = _stage == _Stage.ready;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Logo: centered at about 25% of the screen height
            Align(
              alignment: const Alignment(0, -0.43),
              child: FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset(
                    'assets/logo.png',
                    width: size.width * 0.88,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Phrase: only after the session check says there is no session
            if (ready)
              Align(
                alignment: const Alignment(0, 0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: const Text(
                        'A simple and friendly\nplatform to become part of a\ncaring pet community.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kBlue,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Bottom spot: progress bar, then "can't connect", then the button
            Align(
              alignment: const Alignment(0, 0.49),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_stage) {
                  _Stage.loading => _loadingBar(size.width),
                  _Stage.offline => _offlineBox(),
                  _Stage.ready => _getStartedButton(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
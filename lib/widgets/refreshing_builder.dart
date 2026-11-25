import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Works like [ListenableBuilder], and also lets the user pull down to
/// refresh. Pulling works even when the list is empty or too short to scroll.
class RefreshingBuilder extends StatelessWidget {
  const RefreshingBuilder({
    super.key,
    required this.listenable,
    required this.onRefresh,
    required this.builder,
  });

  final Listenable listenable;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kBlue,
      onRefresh: onRefresh,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Invisible scroll area under the content: it catches the pull
          // when the real list cannot scroll.
          ListView(physics: const AlwaysScrollableScrollPhysics()),
          ListenableBuilder(listenable: listenable, builder: builder),
        ],
      ),
    );
  }
}
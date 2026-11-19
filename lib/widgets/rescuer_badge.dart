import 'package:flutter/material.dart';

import '../utils/report_style.dart';

/// "Verified Rescuer · [Organization]"
class RescuerBadge extends StatelessWidget {
  final String organization;
  final bool compact;

  const RescuerBadge({
    super.key,
    required this.organization,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = compact ? 11 : 13;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: ReportColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ReportColors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: ReportColors.green, size: fontSize + 3),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Verified Rescuer · $organization',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ReportColors.green,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Rescued by [Organization]" tag for adoption posts.
class RescuedByTag extends StatelessWidget {
  final String organization;
  final bool onPhoto; // true = solid background so it reads on top of a photo

  const RescuedByTag({
    super.key,
    required this.organization,
    this.onPhoto = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: onPhoto
            ? Colors.white.withValues(alpha: 0.92)
            : ReportColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: ReportColors.green, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Rescued by $organization',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ReportColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
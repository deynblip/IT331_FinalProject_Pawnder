import 'package:flutter/material.dart';

import '../models/adoption_pet.dart';
import '../utils/report_style.dart';

/// "Rescued Stray" (highlighted) or "Rehoming" (quiet) tag for adoption posts.
class PetSourceTag extends StatelessWidget {
  final PetSource source;
  final bool onPhoto; // true = solid background so it reads on top of a photo

  const PetSourceTag({super.key, required this.source, this.onPhoto = false});

  @override
  Widget build(BuildContext context) {
    final rescued = source == PetSource.rescuedStray;
    final Color fg = rescued ? Colors.white : const Color(0xFF3D2C29);
    final Color bg = rescued
        ? ReportColors.green
        : (onPhoto ? Colors.white.withValues(alpha: 0.92) : Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: rescued ? null : Border.all(color: const Color(0xFFE8D3C2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rescued ? Icons.volunteer_activism : Icons.home_outlined,
            color: fg,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            source.label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
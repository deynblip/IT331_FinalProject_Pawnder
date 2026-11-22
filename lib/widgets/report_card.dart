import 'package:flutter/material.dart';
import '../models/stray_report.dart';
import '../utils/report_style.dart';
import 'report_image.dart';
import 'status_chip.dart';

/// Gamit sa Reports list at sa Home (Nearby Reports).
/// showStatus = false sa Home para Urgency chip lang ang lalabas.
class ReportCard extends StatelessWidget {
  final StrayReport report;
  final VoidCallback onTap;
  final bool showStatus;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE3E5EA)),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              ReportImage(asset: report.imageAsset, width: 76, height: 76),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        StatusChip(
                          label: report.urgency.label,
                          color: urgencyColor(report.urgency),
                        ),
                        if (showStatus)
                          StatusChip(
                            label: report.status.label,
                            color: statusColor(report.status),
                            outlined: true,
                          ),
                        if (report.possiblyLostPet)
                          const StatusChip(
                            label: 'Possibly a lost pet',
                            color: lostPetColor,
                            outlined: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.title,
                      style: const TextStyle(
                        color: ReportColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${report.distanceText}  ·  ${report.dateText}',
                      style: const TextStyle(color: ReportColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ReportColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
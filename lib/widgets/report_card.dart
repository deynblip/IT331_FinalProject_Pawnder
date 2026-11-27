import 'package:flutter/material.dart';
import '../models/stray_report.dart';
import '../utils/app_colors.dart';
import '../utils/report_style.dart';
import 'report_image.dart';
import 'status_chip.dart';

/// Used in the Reports Bulletin and on Home (Nearby Reports).
/// showStatus = false on Home, so only the urgency chip is shown.
class ReportCard extends StatelessWidget {
  final StrayReport report;
  final VoidCallback onTap;
  final bool showStatus;
  final bool compact;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    this.showStatus = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 0 : 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(compact ? 8 : 14),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kCardBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x14C4531F), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              ReportImage(
                asset: report.coverPhoto,
                width: compact ? 56 : 76,
                height: compact ? 56 : 76,
              ),
              SizedBox(width: compact ? 10 : 14),
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
                      maxLines: compact ? 1 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                      style: TextStyle(
                        color: ReportColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${report.distanceText}  ·  ${report.dateTimeText}',
                      style: TextStyle(color: ReportColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: ReportColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
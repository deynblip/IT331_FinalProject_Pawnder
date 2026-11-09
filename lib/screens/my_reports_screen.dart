import 'package:flutter/material.dart';

import '../data/mock_reports.dart';
import '../models/stray_report.dart';
import '../utils/app_colors.dart';
import '../widgets/report_card.dart';
import 'report_details_screen.dart';

/// Mga report na ginawa ng user (galing sa Profile > My Reports).
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  // TEMP: papalitan ng reports ng naka-login na user galing backend
  List<StrayReport> get _mine => mockReports.where((r) => r.isMine).toList();

  @override
  Widget build(BuildContext context) {
    final items = _mine;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: kBlue),
                  ),
                  const Text(
                    'My Reports',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                  child: Text(
                    "You haven't submitted any reports yet.",
                    style: TextStyle(color: kHintGray),
                  ),
                )
                    : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => ReportCard(
                    report: items[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailsScreen(
                          report: items[i],
                          onChanged: (_) {}, // TEMP
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
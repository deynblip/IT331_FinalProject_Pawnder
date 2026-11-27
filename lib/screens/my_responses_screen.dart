import 'package:flutter/material.dart';

import '../models/stray_report.dart';
import '../services/report_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/report_card.dart';
import 'report_details_screen.dart';

/// Reports the logged-in user responded to ("I'm on my way!"), from
/// Profile > My Activity > My Responses. Active ones are listed first.
/// Pull down to refresh.
class MyResponsesScreen extends StatefulWidget {
  const MyResponsesScreen({super.key});

  @override
  State<MyResponsesScreen> createState() => _MyResponsesScreenState();
}

class _MyResponsesScreenState extends State<MyResponsesScreen> {
  @override
  void initState() {
    super.initState();
    ReportService.ensureLoaded();
    ReportService.loadMyResponses();
  }

  Future<void> _refresh() async {
    await ReportService.load();
    await ReportService.loadMyResponses();
  }

  Widget _message(String text) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: kHintGray),
          ),
        ),
      ],
    );
  }

  /// Small label above each card: what I did on that report.
  Widget _stateLabel(StrayReport report) {
    final String? state = ReportService.myResponseState(report.id);
    final (IconData icon, String text, Color color) = switch (state) {
      'active' => (Icons.directions_run, 'You are responding', kBlue),
      'cancelled' => (Icons.undo, 'You withdrew', kHintGray),
      _ => (Icons.check_circle_outline, 'Completed', kTeal),
    };
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4, top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    return ListenableBuilder(
      listenable: ReportService.changes,
      builder: (context, _) {
        if (!ReportService.isLoaded) {
          if (ReportService.loadError != null) {
            return _message(ReportService.loadError!);
          }
          return const Center(child: CircularProgressIndicator());
        }

        final items = ReportService.respondedByMe;
        if (items.isEmpty) {
          return _message(
            "You haven't responded to any reports yet.\n"
                "Tap \"I'm on my way!\" on a report to help.",
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (_, i) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stateLabel(items[i]),
              ReportCard(
                report: items[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailsScreen(
                      report: items[i],
                      onChanged: (_) {}, // the list updates itself
                    ),
                  ),
                ).then((_) => ReportService.loadMyResponses()),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.hPad),
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
                  Text(
                    'My Responses',
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
                child: RefreshIndicator(
                  color: kBlue,
                  onRefresh: _refresh,
                  child: _list(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
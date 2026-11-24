import 'package:flutter/material.dart';

import '../services/report_service.dart';
import '../utils/app_colors.dart';
import '../widgets/report_card.dart';
import 'report_details_screen.dart';
import '../utils/responsive.dart';

/// Reports made by the logged-in user (Profile > My Reports).
/// Comes from the database (ReportService). Pull down to refresh.
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    ReportService.ensureLoaded();
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
            style: const TextStyle(color: kHintGray),
          ),
        ),
      ],
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

        final items = ReportService.mine;
        if (items.isEmpty) {
          return _message("You haven't submitted any reports yet.");
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (_, i) => ReportCard(
            report: items[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportDetailsScreen(
                  report: items[i],
                  onChanged: (_) {}, // the list updates itself (ReportService)
                ),
              ),
            ),
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
                child: RefreshIndicator(
                  color: kBlue,
                  onRefresh: ReportService.load,
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
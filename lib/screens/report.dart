import 'package:flutter/material.dart';

import '../models/stray_report.dart';
import '../services/report_service.dart';
import '../utils/app_colors.dart';
import '../widgets/report_card.dart';
import 'report_details_screen.dart';
import '../utils/responsive.dart';

/// Reports tab: the community reports bulletin (list + filters).
/// Reports come from the database (ReportService). Pull down to refresh.
class ReportsPage extends StatefulWidget {
  /// Switches back to the Map view (provided by ReportsSection).
  final VoidCallback? onViewMap;

  const ReportsPage({super.key, this.onViewMap});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // null = All
  final Map<String, Urgency?> _filters = {
    'All': null,
    'Urgent': Urgency.urgent,
    'Needs Help': Urgency.needsHelp,
    'Sighted': Urgency.sighted,
  };
  String _selected = 'All';

  @override
  void initState() {
    super.initState();
    ReportService.ensureLoaded();
  }

  List<StrayReport> _visible(List<StrayReport> reports) {
    final urgency = _filters[_selected];
    if (urgency == null) return reports;
    return reports.where((r) => r.urgency == urgency).toList();
  }

  void _openDetails(StrayReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(
          report: report,
          onChanged: (_) {}, // the list updates itself (ReportService)
        ),
      ),
    );
  }

  /// Message in the middle of the list area (still scrollable, so
  /// pull-to-refresh works).
  Widget _message(String text, {bool showRetry = false}) {
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
        if (showRetry)
          Center(
            child: TextButton(
              onPressed: ReportService.load,
              child: const Text('Try again'),
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
            return _message(ReportService.loadError!, showRetry: true);
          }
          return const Center(child: CircularProgressIndicator());
        }

        final items = _visible(ReportService.all);
        if (items.isEmpty) return _message('No reports yet');

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (_, i) => ReportCard(
            report: items[i],
            onTap: () => _openDetails(items[i]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reports',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: kNavy,
                ),
              ),
              ElevatedButton.icon(
                onPressed: widget.onViewMap,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text(
                  'View Map',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _filters.keys.map((f) {
              final selected = _selected == f;
              return ChoiceChip(
                label: Text(f),
                selected: selected,
                showCheckmark: false,
                selectedColor: kBlue,
                backgroundColor: Colors.white,
                side: const BorderSide(color: kBlue),
                labelStyle: TextStyle(color: selected ? Colors.white : kBlue),
                onSelected: (_) => setState(() => _selected = f),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              color: kBlue,
              onRefresh: ReportService.load,
              child: _list(),
            ),
          ),
        ],
      ),
    );
  }
}
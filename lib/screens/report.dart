import 'package:flutter/material.dart';

import '../data/mock_reports.dart';
import '../models/stray_report.dart';
import '../utils/app_colors.dart';
import '../widgets/report_card.dart';
import 'report_details_screen.dart';

/// Reports tab: the community reports bulletin (list + filters).
/// NOTE: Gumagamit pa ng mock data. Ikakabit sa ReportService sa backend step.
class ReportsPage extends StatefulWidget {
  /// Switches back to the Map view (provided by ReportsSection).
  final VoidCallback? onViewMap;

  const ReportsPage({super.key, this.onViewMap});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // TEMP: papalitan ng data galing backend
  final List<StrayReport> _reports = List.of(mockReports);

  // null = All
  final Map<String, Urgency?> _filters = {
    'All': null,
    'Urgent': Urgency.urgent,
    'Needs Help': Urgency.needsHelp,
    'Sighted': Urgency.sighted,
  };
  String _selected = 'All';

  List<StrayReport> get _visible {
    final urgency = _filters[_selected];
    if (urgency == null) return _reports;
    return _reports.where((r) => r.urgency == urgency).toList();
  }

  void _updateReport(StrayReport updated) {
    setState(() {
      final i = _reports.indexWhere((r) => r.id == updated.id);
      if (i != -1) _reports[i] = updated;
    });
  }

  Future<void> _openDetails(StrayReport report) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(
          report: report,
          onChanged: _updateReport,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
            child: items.isEmpty
                ? const Center(
              child: Text(
                'No reports yet',
                style: TextStyle(color: kHintGray),
              ),
            )
                : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => ReportCard(
                report: items[i],
                onTap: () => _openDetails(items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
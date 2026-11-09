import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Reports tab: the community reports bulletin (list + filters).
/// NOTE: The list is still a placeholder. It will be connected to the real
/// data (ReportService) in the next step.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final List<String> _filters = ['All', 'Urgent', 'Needs Help', 'Sighted'];
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reports',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _filters.map((f) {
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
          const Expanded(
            child: Center(
              child: Text(
                'No reports yet',
                style: TextStyle(color: kHintGray),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
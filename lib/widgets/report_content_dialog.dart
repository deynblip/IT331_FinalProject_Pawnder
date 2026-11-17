import 'package:flutter/material.dart';

import '../models/content_report.dart';
import '../services/content_report_service.dart';
import '../utils/app_colors.dart';

Future<void> showReportContentDialog(
    BuildContext context, {
      required ReportTarget target,
      required String targetId,
      required String targetTitle,
    }) async {
  final messenger = ScaffoldMessenger.of(context);

  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => _ReportDialog(
      target: target,
      targetId: targetId,
      targetTitle: targetTitle,
    ),
  );

  if (sent == true) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Thanks! An admin will review your report.'),
        ),
      );
  }
}

class _ReportDialog extends StatefulWidget {
  final ReportTarget target;
  final String targetId;
  final String targetTitle;

  const _ReportDialog({
    required this.target,
    required this.targetId,
    required this.targetTitle,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final TextEditingController _details = TextEditingController();
  ReportReason? _reason;
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;

    setState(() => _sending = true);
    await ContentReportService.submit(
      target: widget.target,
      targetId: widget.targetId,
      targetTitle: widget.targetTitle,
      reason: reason,
      details: _details.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Report ${widget.targetTitle}',
        style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this?'),
            const SizedBox(height: 4),
            ...ReportReason.values.map(
                  (r) => RadioListTile<ReportReason>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(r.label),
                value: r,
                groupValue: _reason,
                onChanged: _sending ? null : (v) => setState(() => _reason = v),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _details,
              maxLines: 3,
              enabled: !_sending,
              decoration: const InputDecoration(
                hintText: 'More details (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: (_reason == null || _sending) ? null : _submit,
          child: const Text(
            'Submit',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
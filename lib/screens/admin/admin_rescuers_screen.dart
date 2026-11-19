import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/rescuer_application.dart';
import '../../services/response_service.dart';
import '../../services/rescuer_service.dart';
import '../../utils/app_colors.dart';

String _dateText(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

Color _statusBg(RescuerStatus s) => switch (s) {
  RescuerStatus.pending => const Color(0xFFFFF3B0),
  RescuerStatus.verified => const Color(0xFF8ED16F),
  _ => const Color(0xFFFFB3B3),
};

Color _statusFg(RescuerStatus s) => switch (s) {
  RescuerStatus.pending => const Color(0xFF8A6D00),
  RescuerStatus.verified => const Color(0xFF1F5E10),
  _ => const Color(0xFF9B1C1C),
};

String _statusText(RescuerStatus s) => switch (s) {
  RescuerStatus.pending => 'Pending',
  RescuerStatus.verified => 'Approved',
  _ => 'Rejected',
};

// ------------------------------------------------------------ Main screen

class AdminRescuersScreen extends StatefulWidget {
  const AdminRescuersScreen({super.key});

  @override
  State<AdminRescuersScreen> createState() => _AdminRescuersScreenState();
}

class _AdminRescuersScreenState extends State<AdminRescuersScreen> {
  RescuerStatus _tab = RescuerStatus.pending;

  Widget _tabChip(RescuerStatus status, String label) {
    final selected = _tab == status;
    final count = RescuerService.byStatus(status).length;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        selectedColor: kBlue,
        labelStyle: TextStyle(
          color: selected ? Colors.white : kNavy,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _tab = status),
      ),
    );
  }

  void _openDetail(RescuerApplication app) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RescuerDetailSheet(app: app),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: RescuerService.changes,
        builder: (context, _) {
          final items = RescuerService.byStatus(_tab);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'Rescuer Applications',
                  style: TextStyle(
                    color: kNavy,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _tabChip(RescuerStatus.pending, 'Pending'),
                      _tabChip(RescuerStatus.verified, 'Approved'),
                      _tabChip(RescuerStatus.rejected, 'Rejected'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                  child: Text(
                    'No applications here.',
                    style: TextStyle(color: kHintGray),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ApplicationCard(
                    app: items[i],
                    onTap: () => _openDetail(items[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final RescuerApplication app;
  final VoidCallback onTap;

  const _ApplicationCard({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E5EA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFE6E9EF),
              child: Icon(Icons.verified_user_outlined, color: kBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.organization,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${app.applicantName} · ${app.roleInOrg}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kHintGray, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted ${_dateText(app.submittedAt)}',
                    style: const TextStyle(color: kHintGray, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBg(app.status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusText(app.status),
                style: TextStyle(
                  color: _statusFg(app.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Detail sheet

class _RescuerDetailSheet extends StatelessWidget {
  final RescuerApplication app;

  const _RescuerDetailSheet({required this.app});

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: kHintGray, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: kNavy,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPage(BuildContext context) async {
    var url = app.officialPage.trim();
    if (!url.startsWith('http')) url = 'https://$url';
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the page.')),
      );
    }
  }

  Future<void> _approve(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await RescuerService.approve(app.id);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${app.organization} approved.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _reject(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectDialog(applicantName: app.applicantName),
    );
    if (reason == null) return;

    try {
      await RescuerService.reject(app.id, reason);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Application rejected.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ResponseService.statsFor(app.email);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.organization,
              style: const TextStyle(
                color: kNavy,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Submitted ${_dateText(app.submittedAt)}',
              style: const TextStyle(color: kHintGray, fontSize: 12),
            ),
            const SizedBox(height: 18),

            _row('Applicant', '${app.applicantName} (${app.email})'),
            _row('Role in organization', app.roleInOrg),
            _row('Contact person', app.contactPerson),
            _row('Contact number', app.contactNumber),
            _row('Official page / website', app.officialPage),

            OutlinedButton.icon(
              onPressed: () => _openPage(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open official page'),
            ),
            const SizedBox(height: 18),

            // Track record
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Track record on Pawnder',
                    style: TextStyle(
                      color: kNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (stats.responses == 0)
                    const Text(
                      'No responses yet.',
                      style: TextStyle(color: kHintGray, fontSize: 13),
                    )
                  else
                    Text(
                      'Responses: ${stats.responses}\n'
                          'Successful rescues: ${stats.rescues}\n'
                          'Unable to locate: ${stats.unableToLocate}\n'
                          'Check-in rate: ${stats.checkInRate}',
                      style: const TextStyle(
                        color: kNavy,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Confirm the applicant with the organization through its '
                  'official page or contact details before approving.',
              style: TextStyle(color: kHintGray, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 18),

            if (app.status == RescuerStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reject(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approve(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              )
            else if (app.status == RescuerStatus.rejected)
              Text(
                'Rejected: ${app.rejectionReason ?? '-'}',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              )
            else
              const Text(
                'Approved. The user has the Verified Rescuer badge.',
                style: TextStyle(color: Color(0xFF1F5E10), fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}

/// A reason is required when rejecting.
class _RejectDialog extends StatefulWidget {
  final String applicantName;
  const _RejectDialog({required this.applicantName});

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Reject ${widget.applicantName}?',
        style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: _reason,
        maxLines: 3,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Reason (required) - the applicant will see this',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _reason.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _reason.text.trim()),
          child: const Text(
            'Reject',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
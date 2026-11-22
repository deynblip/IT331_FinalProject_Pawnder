import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/stray_report.dart';
import '../services/auth_service.dart';
import '../services/rescuer_service.dart';
import '../services/response_service.dart';
import '../utils/app_colors.dart';
import '../utils/report_style.dart';
import '../widgets/report_image.dart';
import '../widgets/status_chip.dart';
import '../widgets/rescuer_badge.dart';
import '../models/content_report.dart';
import '../widgets/report_content_dialog.dart';

class ReportDetailsScreen extends StatefulWidget {
  final StrayReport report;
  final ValueChanged<StrayReport> onChanged;

  const ReportDetailsScreen({super.key, required this.report, required this.onChanged});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  late StrayReport _report = widget.report;
  bool _checkingIn = false;

  bool get _isVerified => RescuerService.isCurrentVerified;

  void _apply(StrayReport updated) {
    setState(() => _report = updated);
    widget.onChanged(updated); // so the list updates too
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows an error, or updates the report from the service result.
  void _handle(ActionResult result) {
    if (!result.ok) {
      _snack(result.error!);
      return;
    }
    final newStatus = result.status ?? _report.status;
    _apply(_report.copyWith(
      status: newStatus,
      responders: newStatus == RescueStatus.rescued
          ? _report.responders
          : ResponseService.forReport(_report.id).length,
    ));
  }

  Future<bool> _confirm(String title, String message, String yes) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(color: ReportColors.navy, fontWeight: FontWeight.w800)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(yes, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _onMyWay() async {
    // Regular users get a safety warning on Urgent reports.
    if (_report.urgency == Urgency.urgent && !_isVerified) {
      final ok = await _confirm(
        'Safety first',
        'This is an Urgent report. The animal may be injured, frightened or '
            'aggressive. Keep a safe distance, do not handle it bare-handed, '
            'and consider waiting for a Verified Rescuer.',
        "I understand, I'm going",
      );
      if (!ok || !mounted) return;
    }
    _handle(ResponseService.respond(_report));
  }

  /// "I've arrived": checks the phone's GPS against the report's pin.
  Future<void> _checkIn() async {
    if (_checkingIn) return;
    setState(() => _checkingIn = true);
    final result = await ResponseService.checkIn(_report);
    if (!mounted) return;
    setState(() => _checkingIn = false);
    _handle(result);
    if (result.ok) _snack('Checked in. You are now on site.');
  }

  Future<void> _withdraw() async {
    final ok = await _confirm(
      "Can't make it?",
      'You will be removed from this report. If nobody else is responding, '
          'it goes back to Needs Rescue. This counts as a cancelled '
          'response in your Rescue Record.',
      'Withdraw',
    );
    if (!ok || !mounted) return;
    _handle(ResponseService.withdraw(_report.id));
  }

  Future<void> _takeOver() async {
    final ok = await _confirm(
      'Take over this report?',
      'There have been no recent updates. You will become the lead '
          'responder and the current responders will be assisting.',
      'Take over',
    );
    if (!ok || !mounted) return;
    _handle(ResponseService.takeOver(_report));
  }

  IconData _outcomeIcon(RescueOutcome o) => switch (o) {
    RescueOutcome.rescuedOnSite => Icons.check_circle_outline,
    RescueOutcome.broughtToVetShelter => Icons.local_hospital_outlined,
    RescueOutcome.unableToLocate => Icons.search_off,
  };

  Future<void> _markRescued() async {
    var outcome = RescueOutcome.rescuedOnSite;

    // Verified Rescuers can choose other outcomes too.
    if (_isVerified) {
      final picked = await showModalBottomSheet<RescueOutcome>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How did this end?',
                    style: TextStyle(
                        color: ReportColors.navy, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final o in RescueOutcome.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_outcomeIcon(o), color: ReportColors.navy),
                    title: Text(o.label),
                    onTap: () => Navigator.pop(sheetContext, o),
                  ),
              ],
            ),
          ),
        ),
      );
      if (picked == null || !mounted) return;
      outcome = picked;
    }

    if (_checkingIn) return;
    setState(() => _checkingIn = true);
    final result = await ResponseService.finish(_report, outcome);
    if (!mounted) return;
    setState(() => _checkingIn = false);
    _handle(result);
  }

  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_report.lat},${_report.lng}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  /// Shown when the reporter said the animal has a collar / looks owned.
  Widget _lostPetNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lostPetColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lostPetColor.withValues(alpha: 0.4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.pets, color: lostPetColor),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Possibly a lost pet',
                  style: TextStyle(
                    color: lostPetColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'The reporter said this animal has a collar or looks like '
                      "someone's pet. Please don't take it home right away. Ask "
                      'around the area or check with the barangay first.',
                  style: TextStyle(
                    color: ReportColors.navy,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: ReportColors.navy, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: ReportColors.navy, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ReportColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 17)),
      ),
    );
  }

  Widget _secondaryButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ReportColors.navy,
          side: const BorderSide(color: ReportColors.navy),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _responderTile(ReportResponder r) {
    final isMe = r.email == AuthService.currentEmail;
    final isLead = r.role == ResponderRole.lead;
    final stats = ResponseService.statsFor(r.email);
    final record = r.isVerified
        ? '${stats.rescues} rescues'
        : '${stats.trustLevel.label} · ${stats.rescues} rescues';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            r.checkedIn ? Icons.check_circle : Icons.person_outline,
            color: r.checkedIn ? ReportColors.green : ReportColors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.name}${isMe ? ' (you)' : ''}  ·  ${isLead ? 'Lead' : 'Assisting'}',
                  style: TextStyle(
                    color: ReportColors.navy,
                    fontSize: 14,
                    fontWeight: isLead ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record,
                  style: const TextStyle(
                    color: ReportColors.grey,
                    fontSize: 12,
                  ),
                ),
                if (r.organization != null) ...[
                  const SizedBox(height: 3),
                  RescuerBadge(organization: r.organization!, compact: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final Widget content;
    switch (_report.status) {
      case RescueStatus.needsRescue:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatusChip(label: 'Needs Rescue', color: ReportColors.red, outlined: true, fontSize: 16),
            const SizedBox(height: 8),
            const Text('The animal still needs assistance',
                style: TextStyle(color: ReportColors.navy, fontSize: 15)),
            const SizedBox(height: 12),
            _primaryButton("I'm on my way!", _onMyWay),
            if (_report.isMine) ...[
              const SizedBox(height: 10),
              _secondaryButton('Mark as Rescued', _markRescued),
            ],
          ],
        );
        break;

      case RescueStatus.inProgress:
        final me = ResponseService.mine(_report.id);
        final responders = ResponseService.forReport(_report.id);
        final inactive = ResponseService.isInactive(_report);
        final count = responders.isEmpty ? _report.responders : responders.length;

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatusChip(label: 'Rescue in Progress', color: ReportColors.navy, outlined: true, fontSize: 16),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.groups, color: ReportColors.navy),
                const SizedBox(width: 8),
                Text('$count responding',
                    style: const TextStyle(color: ReportColors.navy, fontSize: 15)),
              ],
            ),
            if (responders.any((r) => r.checkedIn)) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.location_on, color: ReportColors.green, size: 20),
                  SizedBox(width: 6),
                  Text('Responder on site',
                      style: TextStyle(
                          color: ReportColors.green,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
            if (responders.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...responders.map(_responderTile),
            ],
            if (inactive) ...[
              const SizedBox(height: 4),
              const Text('No recent updates on this report.',
                  style: TextStyle(color: ReportColors.orange, fontSize: 13)),
            ],
            const SizedBox(height: 12),

            if (me == null) ...[
              _primaryButton("I'm on my way!", _onMyWay),
              if (_isVerified && inactive) ...[
                const SizedBox(height: 10),
                _secondaryButton('Take over this report', _takeOver),
              ],
              if (_report.isMine) ...[
                const SizedBox(height: 10),
                _secondaryButton('Mark as Rescued', _markRescued),
              ],
            ] else ...[
              if (!me.checkedIn) ...[
                _secondaryButton(
                  _checkingIn
                      ? 'Checking your location…'
                      : "I've arrived · Check in",
                  _checkingIn ? null : _checkIn,
                ),
                const SizedBox(height: 6),
                Text(
                  'You must be within ${ResponseService.checkInRadiusMeters.round()} m of the animal.',
                  style: const TextStyle(color: ReportColors.grey, fontSize: 12),
                ),
                const SizedBox(height: 10),
              ],
              // Regular users must check in first. Verified Rescuers can
              // always open the outcome choices (e.g. "Unable to locate").
              _primaryButton(
                'Mark as Rescued',
                (me.checkedIn || me.isVerified || _report.isMine)
                    ? _markRescued
                    : null,
              ),
              if (!me.checkedIn && !me.isVerified && !_report.isMine) ...[
                const SizedBox(height: 6),
                const Text(
                  'Check in at the location before you can mark this as rescued.',
                  style: TextStyle(color: ReportColors.grey, fontSize: 12),
                ),
              ],
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _withdraw,
                  child: const Text("Cancel · I can't make it",
                      style: TextStyle(color: ReportColors.grey)),
                ),
              ),
            ],
          ],
        );
        break;

      case RescueStatus.rescued:
        final closure = ResponseService.closureOf(_report.id);
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: ReportColors.green, size: 28),
                const SizedBox(height: 8),
                const Text('Animal Successfully Rescued',
                    style: TextStyle(color: ReportColors.navy, fontSize: 18)),
                const SizedBox(height: 4),
                if (closure != null) ...[
                  Text(closure.outcome.label,
                      style: const TextStyle(color: ReportColors.grey, fontSize: 13)),
                  if (closure.by.organization != null) ...[
                    const SizedBox(height: 8),
                    RescuerBadge(organization: closure.by.organization!),
                  ],
                  const SizedBox(height: 6),
                ],
                const Text('Thank you for everyone who helped!',
                    style: TextStyle(color: ReportColors.blue, fontSize: 13)),
              ],
            ),
          ),
        );
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5DEC8)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: ReportColors.blue),
                  ),
                  const Text('Reports',
                      style: TextStyle(color: ReportColors.navy, fontSize: 28, fontWeight: FontWeight.w800)),
                  // Report button (not shown on your own report)
                  if (!_report.isMine) ...[
                    const Spacer(),
                    IconButton(
                      tooltip: 'Report this post',
                      icon: const Icon(Icons.flag_outlined, color: ReportColors.grey),
                      onPressed: () => showReportContentDialog(
                        context,
                        target: ReportTarget.strayReport,
                        targetId: _report.id,
                        targetTitle: _report.title,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportImage(asset: _report.imageAsset, width: 150, height: 150),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip(
                          label: _report.urgency.label,
                          color: urgencyColor(_report.urgency),
                          fontSize: 18,
                        ),
                        const SizedBox(height: 12),
                        Text(_report.title,
                            style: const TextStyle(
                                color: ReportColors.navy, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(_report.distanceText,
                            style: const TextStyle(color: ReportColors.grey, fontSize: 15)),
                        Text(_report.dateText,
                            style: const TextStyle(color: ReportColors.grey, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _field('Animal Type', _report.animalType),
              _field('Urgency Level', _report.urgency.label),
              _field('Location', _report.location),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _openDirections,
                  icon: const Icon(Icons.navigation, color: ReportColors.navy),
                  label: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Get Directions', style: TextStyle(color: ReportColors.navy, fontSize: 17)),
                      Text('Open in Google Maps', style: TextStyle(color: ReportColors.grey, fontSize: 12)),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: Color(0xFFF5DEC8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_report.possiblyLostPet) _lostPetNotice(),
              _field('Condition and Behavior', _report.descriptionOrDefault),
              const SizedBox(height: 4),
              _statusCard(),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/stray_report.dart';
import '../services/report_service.dart';
import '../services/response_service.dart';
import '../utils/app_colors.dart';
import '../utils/report_style.dart';
import '../widgets/photo_gallery.dart';
import '../widgets/status_chip.dart';
import '../widgets/rescuer_badge.dart';
import '../models/content_report.dart';
import '../widgets/report_content_dialog.dart';
import '../utils/responsive.dart';
import 'edit_report_screen.dart';

class ReportDetailsScreen extends StatefulWidget {
  final StrayReport report;
  final ValueChanged<StrayReport> onChanged;

  /// True lang kapag galing sa Profile > My Reports. Doon lang lalabas ang
  /// Edit / Remove.
  final bool showOwnerActions;

  const ReportDetailsScreen({
    super.key,
    required this.report,
    required this.onChanged,
    this.showOwnerActions = false,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  late StrayReport _report = widget.report;

  /// Responders, track records and outcome (null while loading).
  RescueDetails? _details;
  String? _loadError;

  /// True while a button is waiting for the database (or GPS).
  bool _busy = false;
  String _busyText = '';

  bool get _isVerified => ResponseService.isCurrentVerified;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Loads the latest status and responders from the database.
  Future<void> _refresh() async {
    try {
      final details = await ResponseService.loadDetails(_report.id);
      if (!mounted) return;
      setState(() {
        _details = details;
        _report = details.report;
        _loadError = null;
      });
      widget.onChanged(details.report); // so the list updates too
    } on ReportFailure catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs a button's action: shows "busy", then an error or [success],
  /// then reloads the report so the screen shows the new status.
  Future<void> _run(
      String busyText,
      Future<ActionResult> Function() action, {
        String? success,
      }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busyText = busyText;
    });
    final result = await action();
    if (!mounted) return;
    if (!result.ok) {
      _snack(result.error!);
    } else if (success != null) {
      _snack(success);
    }
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<bool> _confirm(String title, String message, String yes) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: TextStyle(color: ReportColors.navy, fontWeight: FontWeight.w800)),
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
    await _run(
      'Sending...',
          () => ResponseService.respond(_report),
      success: "You're on your way. The reporter was notified.",
    );
  }

  /// "I've arrived": sends the phone's GPS. The database checks the 200 m.
  Future<void> _checkIn() => _run(
    'Checking your location...',
        () => ResponseService.checkIn(_report),
    success: 'Checked in. You are now on site.',
  );

  Future<void> _withdraw() async {
    final ok = await _confirm(
      "Can't make it?",
      'You will be removed from this report. If nobody else is responding, '
          'it goes back to Needs Rescue. This counts as a cancelled '
          'response in your Rescue Record.',
      'Withdraw',
    );
    if (!ok || !mounted) return;
    await _run('Cancelling...', () => ResponseService.withdraw(_report));
  }

  Future<void> _takeOver() async {
    final ok = await _confirm(
      'Take over this report?',
      'There have been no recent updates. You will become the lead '
          'responder and the current responders will be assisting.',
      'Take over',
    );
    if (!ok || !mounted) return;
    await _run(
      'Taking over...',
          () => ResponseService.takeOver(_report),
      success: 'You are now the lead responder.',
    );
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
        backgroundColor: kSurfaceWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How did this end?',
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

    await _run(
      outcome == RescueOutcome.unableToLocate
          ? 'Saving...'
          : 'Checking your location...',
          () => ResponseService.finish(_report, outcome),
    );
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
      child: Row(
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

  Widget _sightingRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: ReportColors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: ReportColors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: ReportColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sightingCard() {
    final Color accent = urgencyColor(_report.urgency);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: kCardColor,
          border: Border.all(color: kCardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sightingRow(
                          Icons.location_on, 'LOCATION', _report.location),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: kCardBorder),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _sightingRow(
                                Icons.pets, 'ANIMAL', _report.animalType),
                          ),
                          Expanded(
                            child: _sightingRow(Icons.near_me_outlined,
                                'DISTANCE', _report.distanceText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
              style: TextStyle(color: ReportColors.navy, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: ReportColors.navy, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback? onPressed) {
    if (_busy) onPressed = null;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kNavyFill,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 17)),
      ),
    );
  }

  Widget _secondaryButton(String text, VoidCallback? onPressed) {
    if (_busy) onPressed = null;
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ReportColors.navy,
          side: BorderSide(color: ReportColors.navy),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _responderTile(ReportResponder r, RescueDetails details) {
    final isMe = r.isMe;
    final isLead = r.role == ResponderRole.lead;
    final stats = details.statsOf(r.userId);
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
                  style: TextStyle(
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

  /// Small "busy" line under the buttons (e.g. "Checking your location...").
  Widget _busyLine() {
    if (!_busy) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(_busyText,
              style: TextStyle(color: ReportColors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final details = _details;

    // Still loading the responders (or it failed).
    if (details == null) {
      return _cardBox(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: _loadError == null
                ? const CircularProgressIndicator()
                : Column(
              children: [
                Text(_loadError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ReportColors.grey)),
                TextButton(
                  onPressed: _refresh,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Widget content;
    switch (_report.status) {
      case RescueStatus.needsRescue:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatusChip(label: 'Needs Rescue', color: ReportColors.red, outlined: true, fontSize: 16),
            const SizedBox(height: 8),
            Text('The animal still needs assistance',
                style: TextStyle(color: ReportColors.navy, fontSize: 15)),
            const SizedBox(height: 12),
            if (_report.isMine)
              _primaryButton('Mark as Rescued', _markRescued)
            else
              _primaryButton("I'm on my way!", _onMyWay),
            _busyLine(),
          ],
        );
        break;

      case RescueStatus.inProgress:
        final me = details.mine;
        final responders = details.responders;
        final inactive = details.isInactive;
        final count = responders.length;

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(label: 'Rescue in Progress', color: ReportColors.navy, outlined: true, fontSize: 16),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.groups, color: ReportColors.navy),
                const SizedBox(width: 8),
                Text('$count responding',
                    style: TextStyle(color: ReportColors.navy, fontSize: 15)),
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
              ...responders.map((r) => _responderTile(r, details)),
            ],
            if (inactive) ...[
              const SizedBox(height: 4),
              const Text('No recent updates on this report.',
                  style: TextStyle(color: ReportColors.orange, fontSize: 13)),
            ],
            const SizedBox(height: 12),

            if (me == null) ...[
              if (_report.isMine)
                _primaryButton('Mark as Rescued', _markRescued)
              else ...[
                _primaryButton("I'm on my way!", _onMyWay),
                if (_isVerified && inactive) ...[
                  const SizedBox(height: 10),
                  _secondaryButton('Take over this report', _takeOver),
                ],
              ],
            ] else ...[
              if (!me.checkedIn) ...[
                _secondaryButton("I've arrived · Check in", _checkIn),
                const SizedBox(height: 6),
                Text(
                  'You must be within ${ResponseService.checkInRadiusMeters.round()} m of the animal.',
                  style: TextStyle(color: ReportColors.grey, fontSize: 12),
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
                Text(
                  'Check in at the location before you can mark this as rescued.',
                  style: TextStyle(color: ReportColors.grey, fontSize: 12),
                ),
              ],
              _busyLine(),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _busy ? null : _withdraw,
                  child: Text("Cancel · I can't make it",
                      style: TextStyle(color: ReportColors.grey)),
                ),
              ),
            ],
          ],
        );
        break;

      case RescueStatus.rescued:
        final closure = details.closure;
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: ReportColors.green, size: 28),
                const SizedBox(height: 8),
                Text('Animal Successfully Rescued',
                    style: TextStyle(color: ReportColors.navy, fontSize: 18)),
                const SizedBox(height: 4),
                if (closure != null) ...[
                  Text(closure.outcome.label,
                      style: TextStyle(color: ReportColors.grey, fontSize: 13)),
                  if (closure.organization != null) ...[
                    const SizedBox(height: 8),
                    RescuerBadge(organization: closure.organization!),
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

    return _cardBox(content);
  }

  // ---------------------------------------------------------------- Contact

  /// Calls / emails the reporter. If no app can open it, the number or
  /// email is copied instead.
  Future<void> _contactReporter(Uri uri, String copyText, String what) async {
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (ok || !mounted) return;
    await Clipboard.setData(ClipboardData(text: copyText));
    if (mounted) _snack('$what copied: $copyText');
  }

  Widget _contactRow(
      IconData icon, String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: ReportColors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: ReportColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: ReportColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: ReportColors.grey),
          ],
        ),
      ),
    );
  }

  /// Reporter's name, phone and email, so the owner of a lost pet (or a
  /// rescuer) can reach them. Not tappable on your own report.
  Widget _contactCard() {
    final r = _report;
    final bool mine = r.isMine;
    final String phoneDigits = r.contactPhone.replaceAll(RegExp(r'[\s\-()]'), '');

    return _cardBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mine ? 'Your Contact Details' : 'Contact the Reporter',
            style: TextStyle(
              color: ReportColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mine
                ? 'Other users can see these on your report.'
                : 'Is this your pet, or do you need more details? Reach the '
                'person who reported it.',
            style: TextStyle(color: ReportColors.grey, fontSize: 13),
          ),
          const SizedBox(height: 6),
          if (r.contactName.isNotEmpty)
            _contactRow(Icons.person_outline, 'NAME', r.contactName, null),
          if (r.contactPhone.isNotEmpty)
            _contactRow(
              Icons.phone_outlined,
              'PHONE',
              r.contactPhone,
              mine
                  ? null
                  : () => _contactReporter(
                Uri(scheme: 'tel', path: phoneDigits),
                r.contactPhone,
                'Number',
              ),
            ),
          if (r.contactEmail.isNotEmpty)
            _contactRow(
              Icons.email_outlined,
              'EMAIL',
              r.contactEmail,
              mine
                  ? null
                  : () => _contactReporter(
                Uri(
                  scheme: 'mailto',
                  path: r.contactEmail,
                  query: 'subject=About%20your%20Pawnder%20report',
                ),
                r.contactEmail,
                'Email',
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardBox(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kCardBorder),
        boxShadow: const [BoxShadow(color: Color(0x14C4531F), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: child,
    );
  }

  Future<void> _editReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditReportScreen(report: _report)),
    );
    if (mounted) await _refresh(); // ipakita ang bagong laman
  }

  Future<void> _removeReport() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove this report?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'It will no longer show on Home, Map or the Reports list. '
                "This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ReportService.removeMine(_report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Report removed.')));
      Navigator.pop(context); // balik sa listahan
    } on ReportFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(e.message);
    }
  }

  Widget? _ownerBar() {
    if (!widget.showOwnerActions || !ReportService.canChange(_report)) {
      return null;
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(context.hPad, 10, context.hPad, 12),
        decoration: BoxDecoration(
          color: kCream,
          border: Border(top: BorderSide(color: kCardBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _editReport,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kBlue,
                  side: const BorderSide(color: kBlue),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _removeReport,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      bottomNavigationBar: _ownerBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(context.hPad, 12, context.hPad, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: ReportColors.blue),
                    ),
                    Text('Reports',
                        style: TextStyle(color: ReportColors.navy, fontSize: 28, fontWeight: FontWeight.w800)),
                    // Report button (not shown on your own report)
                    if (!_report.isMine) ...[
                      const Spacer(),
                      IconButton(
                        tooltip: 'Report this post',
                        icon: Icon(Icons.flag_outlined, color: ReportColors.grey),
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

                // Photo(s): swipe if more than one, tap to enlarge.
                // The urgency sits on the photo so it is seen first.
                PhotoGallery(
                  photos: _report.allPhotos,
                  height: 280,
                  overlay: StatusChip(
                    label: _report.urgency.label,
                    color: urgencyColor(_report.urgency),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),

                // Title + when it was reported
                Text(
                  _report.title,
                  style: TextStyle(
                    color: ReportColors.navy,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 16, color: ReportColors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Reported ${_report.dateText}',
                      style: TextStyle(
                          color: ReportColors.grey, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sighting details. The stripe takes the urgency color, so
                // this does not look like an adoption page.
                _sightingCard(),
                const SizedBox(height: 14),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _openDirections,
                    icon: Icon(Icons.navigation, color: ReportColors.navy),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Get Directions', style: TextStyle(color: ReportColors.navy, fontSize: 17)),
                        Text('Open in Google Maps', style: TextStyle(color: ReportColors.grey, fontSize: 12)),
                      ],
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: BorderSide(color: kCardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (_report.possiblyLostPet) _lostPetNotice(),
                _field('Condition and Behavior', _report.descriptionOrDefault),
                const SizedBox(height: 4),
                if (_report.hasContact) ...[
                  _contactCard(),
                  const SizedBox(height: 14),
                ],
                _statusCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
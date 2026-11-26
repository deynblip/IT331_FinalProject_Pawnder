import 'package:flutter/material.dart';

import '../models/adoption_application.dart';
import '../services/application_service.dart';
import '../utils/app_colors.dart';
import '../utils/application_style.dart';
import '../widgets/status_chip.dart';
import '../utils/responsive.dart';

/// The pet owner reads an application that the admin forwarded and makes the
/// final decision (Approve / Reject).
class OwnerApplicationScreen extends StatefulWidget {
  final AdoptionApplication application;

  const OwnerApplicationScreen({super.key, required this.application});

  @override
  State<OwnerApplicationScreen> createState() =>
      _OwnerApplicationScreenState();
}

class _OwnerApplicationScreenState extends State<OwnerApplicationScreen> {
  bool _busy = false;

  AdoptionApplication get _app => widget.application;

  bool get _waiting => _app.status == ApplicationStatus.forwardedToOwner;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approve() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Approve ${_app.fullName}?',
          style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '${_app.petName} will be adopted by this applicant. '
              'This is your final decision.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok == true) await _decide(approve: true);
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Reject ${_app.fullName}?',
          style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Reason (optional). The applicant will see this.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    if (ok == true) {
      await _decide(approve: false, reason: reason.isEmpty ? null : reason);
    }
  }

  Future<void> _decide({required bool approve, String? reason}) async {
    setState(() => _busy = true);
    try {
      await ApplicationService.decideAsOwner(
        _app.id,
        approve: approve,
        reason: reason,
      );
      if (!mounted) return;
      _snack(approve ? 'Application approved.' : 'Application rejected.');
      Navigator.pop(context);
    } catch (_) {
      _snack('Could not save your decision. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ----------------------------------------------------------------- UI

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        color: kNavy,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _row(String label, String value) {
    final text = value.trim().isEmpty ? '-' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: kNavy,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(text, style: TextStyle(color: kNavy, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _decisionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _busy ? null : _reject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reject'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _busy ? null : _approve,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _busy
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Approve',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _decidedNote() {
    final approved = _app.status == ApplicationStatus.approved;
    final reason = _app.rejectionReason;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        approved
            ? 'This application was approved.'
            : 'This application was rejected.'
            '${reason == null ? '' : '\nReason: $reason'}',
        style: TextStyle(color: kNavy, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: kBlue),
                  ),
                  Expanded(
                    child: Text(
                      'Application',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusChip(
                        label:
                        _waiting ? 'Needs your decision' : _app.status.label,
                        color: _waiting
                            ? kBlue
                            : applicationStatusColor(_app.status),
                        outlined: true,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_app.fullName} wants to adopt ${_app.petName}',
                        style: TextStyle(
                          color: kNavy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Applied ${_app.dateText}',
                        style: TextStyle(color: kHintGray),
                      ),
                      _heading('Applicant'),
                      _row('Full Name', _app.fullName),
                      _row('Phone Number', _app.phone),
                      _row('Email Address', _app.email),
                      _heading('Address'),
                      _row('Barangay, City, Province', _app.location),
                      _row('Street / Landmark', _app.street),
                      _heading('Home & Experience'),
                      _row('Home Environment', _app.homeEnvironment),
                      _row('Household Members', _app.householdMembers),
                      _row('Previous Pets', _app.previousPets),
                      _row('Pet Care Experience', _app.careExperience),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _waiting ? _decisionButtons() : _decidedNote(),
            ],
          ),
        ),
      ),
    );
  }
}
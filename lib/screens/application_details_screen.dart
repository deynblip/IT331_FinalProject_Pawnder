import 'package:flutter/material.dart';

import '../models/adoption_application.dart';
import '../services/adoption_service.dart';
import '../services/application_service.dart';
import '../utils/app_colors.dart';
import '../utils/application_style.dart';
import '../widgets/adopt_pet_photo.dart';
import '../widgets/status_chip.dart';
import '../utils/responsive.dart';
import 'adoption_application_screen.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final AdoptionApplication application;

  /// true only when opened from Profile > My Applications: shows the Edit and
  /// Withdraw bar at the bottom (when the application still allows it).
  final bool showOwnerActions;

  const ApplicationDetailsScreen({
    super.key,
    required this.application,
    this.showOwnerActions = false,
  });

  @override
  State<ApplicationDetailsScreen> createState() =>
      _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ApplicationService.load(); // show the newest status
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(AdoptionApplication a) async {
    final pet = AdoptionService.byId(a.petId);
    if (pet == null) {
      _snack('This pet is no longer available.');
      return;
    }
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdoptionApplicationScreen(pet: pet, existing: a),
      ),
    );
    if (mounted) await ApplicationService.refresh();
  }

  Future<void> _withdraw(AdoptionApplication a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Withdraw your application for ${a.petName}?',
          style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'It will no longer be reviewed. You will not be able to apply '
              'for this pet again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Withdraw',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ApplicationService.withdrawMine(a.id);
      if (mounted) _snack('Your application was withdrawn.');
    } on StateError catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _ownerBar(AdoptionApplication a) {
    final bool canEdit = a.canEdit;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(context.hPad, 10, context.hPad, 10),
        decoration: BoxDecoration(
          color: kCream,
          border: Border(top: BorderSide(color: kCardBorder)),
        ),
        child: Row(
          children: [
            if (canEdit) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _edit(a),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBlue,
                    side: const BorderSide(color: kBlue),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : () => _withdraw(a),
                icon: _busy
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.undo, size: 18),
                label: const Text('Withdraw'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD64545),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        color: kNavy,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: kNavy,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.trim().isEmpty ? '—' : value,
          style: TextStyle(color: kNavy, fontSize: 15),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Rebuilds by itself when the status changes (admin / owner decided).
    return ListenableBuilder(
      listenable: Listenable.merge([
        ApplicationService.changes,
        AdoptionService.changes,
      ]),
      builder: (context, _) {
        final a =
            ApplicationService.byId(widget.application.id) ?? widget.application;
        final pet = AdoptionService.byId(a.petId);
        final photo = pet?.coverPhoto;
        final color = applicationStatusColor(a.status);
        final bool showBar =
            widget.showOwnerActions && (a.canEdit || a.canWithdraw);

        final placeholder = Container(
          color: kPeach,
          child: const Center(
            child: Icon(Icons.pets, size: 36, color: Color(0xFF8A746C)),
          ),
        );

        return Scaffold(
          backgroundColor: kCream,
          bottomNavigationBar: showBar ? _ownerBar(a) : null,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.hPad),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: kBlue),
                      ),
                      Expanded(
                        child: Text(
                          'Application Details',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: kNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: kBlue,
                    onRefresh: ApplicationService.refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                          context.hPad, 12, context.hPad, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---- Pet summary
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: 96,
                                  height: 96,
                                  child: photo == null
                                      ? placeholder
                                      : PetPhoto(
                                      path: photo, fallback: placeholder),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.petName,
                                      style: TextStyle(
                                        color: kNavy,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (pet != null)
                                      Text(
                                        '${pet.animalType}  ·  ${pet.summary}',
                                        style:
                                        TextStyle(color: kHintGray),
                                      ),
                                    const SizedBox(height: 8),
                                    StatusChip(
                                      label: a.status.label,
                                      color: color,
                                      outlined: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // ---- Status banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color, width: 1.2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.status.label,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  applicationStatusMessage(a),
                                  style: TextStyle(
                                      color: kNavy, fontSize: 14),
                                ),
                                if (a.status == ApplicationStatus.rejected) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    (a.rejectionReason ?? '').trim().isEmpty
                                        ? 'No reason was provided.'
                                        : 'Reason: ${a.rejectionReason}',
                                    style: TextStyle(
                                      color: kNavy,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // ---- Application info
                          _section('Application'),
                          _field('Date submitted', a.dateText),
                          _field('Pet owner', a.posterName),

                          // ---- What the user submitted
                          _section('Your Information'),
                          _field('Full name', a.fullName),
                          _field('Phone number', a.phone),
                          _field('Email address', a.email),
                          _field(
                            'Address',
                            a.street.trim().isEmpty
                                ? a.location
                                : '${a.street}, ${a.location}',
                          ),

                          _section('Living Environment'),
                          _field('Home environment', a.homeEnvironment),
                          _field('Household members', a.householdMembers),

                          _section('Pet Ownership Experience'),
                          _field('Previous or current pets', a.previousPets),
                          _field('Pet care experience', a.careExperience),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';

import '../../models/adoption_application.dart';
import '../../models/adoption_pet.dart';
import '../../services/adoption_service.dart';
import '../../services/application_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/adopt_pet_photo.dart';

// ---------------------------------------------------------------- Helpers

/// "Pending" in the admin tab = not decided yet.
bool _isPending(AdoptionApplication a) =>
    a.status == ApplicationStatus.pendingScreening ||
        a.status == ApplicationStatus.forwardedToOwner;

String _statusLabel(AdoptionApplication a) =>
    _isPending(a) ? 'Pending' : a.status.label;

Color _statusBg(AdoptionApplication a) {
  if (_isPending(a)) return const Color(0xFFFFF3B0);
  return a.status == ApplicationStatus.approved
      ? const Color(0xFF8ED16F)
      : const Color(0xFFFFB3B3);
}

Color _statusFg(AdoptionApplication a) {
  if (_isPending(a)) return const Color(0xFF8A6D00);
  return a.status == ApplicationStatus.approved
      ? const Color(0xFF1F5E10)
      : const Color(0xFF9B1C1C);
}

const Color _kRejectPink = Color(0xFFFF9F9F);
const Color _kRejectText = Color(0xFF7A1F1F);

String _dateText(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

Widget _photo(String? path, {double iconSize = 30}) {
  final fallback = Container(
    color: const Color(0xFFE6E9EF),
    child: Center(
      child: Icon(Icons.pets, size: iconSize, color: const Color(0xFF8A8F98)),
    ),
  );
  if (path == null) return fallback;
  return PetPhoto(path: path, fallback: fallback);
}

/// Asks for an optional reason before rejecting. Pops with the reason
/// (may be empty), or null when the admin cancels.
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
        decoration: const InputDecoration(
          hintText: 'Reason (optional) - the applicant will see this',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _reason.text.trim()),
          child: const Text(
            'Reject',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

/// Approve / reject through the service (the service itself checks that the
/// logged-in account is an admin).
Future<void> _changeStatus(
    BuildContext context,
    AdoptionApplication app,
    ApplicationStatus status,
    ) async {
  final messenger = ScaffoldMessenger.of(context);
  String? reason;

  if (status == ApplicationStatus.rejected) {
    reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectDialog(applicantName: app.fullName),
    );
    if (reason == null) return; // cancelled
  } else if (status == ApplicationStatus.approved) {
    // Picking this applicant closes the other waiting ones for this pet.
    final others = ApplicationService.forPet(app.petId)
        .where((a) => a.id != app.id && _isPending(a))
        .length;
    if (others > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Approve ${app.fullName}?',
            style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'This picks ${app.fullName} to adopt ${app.petName}. The other '
                '$others waiting ${others == 1 ? 'applicant' : 'applicants'} '
                'for ${app.petName} will be rejected.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Approve',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
  }

  try {
    await ApplicationService.setStatus(
      app.id,
      status,
      reason: (reason == null || reason.isEmpty) ? null : reason,
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            status == ApplicationStatus.approved
                ? '${app.fullName} was approved to adopt ${app.petName}.'
                : '${app.fullName}\'s application was rejected.',
          ),
        ),
      );
  } on StateError catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
  }
}

class _StatusPill extends StatelessWidget {
  final AdoptionApplication app;
  const _StatusPill(this.app);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _statusBg(app),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(app),
        style: TextStyle(
          color: _statusFg(app),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ------------------------------------------------------ Applications page

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  static const List<String> _filters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  String _selected = 'All';

  bool _matches(AdoptionApplication a) {
    switch (_selected) {
      case 'Pending':
        return _isPending(a);
      case 'Approved':
        return a.status == ApplicationStatus.approved;
      case 'Rejected':
        return a.status == ApplicationStatus.rejected;
      default:
        return true;
    }
  }

  void _openDetails(AdoptionApplication app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminApplicationDetailsScreen(applicationId: app.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6F8FC0), Color(0xFFDDE4F0), Colors.white],
          stops: [0.0, 0.3, 0.5],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset('assets/logo.png', height: 38),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Notifications',
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white54, height: 12),
                  const SizedBox(height: 14),
                  const Text(
                    'Adoption Applications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final selected = _selected == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? kBlue : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kNavy),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: selected ? Colors.white : kNavy,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Expanded(
              // Rebuilds when an application OR a pet post changes.
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  ApplicationService.changes,
                  AdoptionService.changes,
                ]),
                builder: (context, _) {
                  final apps = ApplicationService.all.where(_matches).toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (apps.isEmpty) {
                    return Center(
                      child: Text(
                        _selected == 'All'
                            ? 'No adoption applications yet.'
                            : 'No ${_selected.toLowerCase()} applications.',
                        style: const TextStyle(color: kHintGray),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: apps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final app = apps[i];
                      return _ApplicationCard(
                        app: app,
                        pet: AdoptionService.byId(app.petId),
                        onView: () => _openDetails(app),
                        onAction: () => _changeStatus(
                          context,
                          app,
                          app.status == ApplicationStatus.approved
                              ? ApplicationStatus.rejected
                              : ApplicationStatus.approved,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final AdoptionApplication app;
  final AdoptionPet? pet; // null if the post was removed
  final VoidCallback onView;
  final VoidCallback onAction;

  const _ApplicationCard({
    required this.app,
    required this.pet,
    required this.onView,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool pending = _isPending(app);
    final bool approved = app.status == ApplicationStatus.approved;

    // Design: a PENDING application has a greyed-out Approve button, so the
    // admin must open "View Details" and review it first. To allow approving
    // straight from the list, change this to:  final VoidCallback? action = onAction;
    final VoidCallback? action = pending ? null : onAction;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _photo(pet?.coverPhoto),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.petName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kNavy,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _StatusPill(app),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (pet != null)
                      Text(
                        pet!.summary,
                        style: const TextStyle(color: kHintGray, fontSize: 12),
                      ),
                    Text(
                      'Applicant: ${app.fullName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kHintGray, fontSize: 12),
                    ),
                    Text(
                      'Applied on: ${_dateText(app.createdAt)}',
                      style: const TextStyle(color: kHintGray, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: onView,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kNavy,
                      side: const BorderSide(color: kNavy),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: action, // null = greyed out
                    style: ElevatedButton.styleFrom(
                      backgroundColor: approved ? _kRejectPink : kBlue,
                      foregroundColor: approved ? _kRejectText : Colors.white,
                      disabledBackgroundColor: const Color(0xFFF1F2F5),
                      disabledForegroundColor: const Color(0xFFB8BCC6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      approved ? 'Reject' : 'Approve',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- Details page

class AdminApplicationDetailsScreen extends StatelessWidget {
  final String applicationId;

  const AdminApplicationDetailsScreen({super.key, required this.applicationId});

  String _orDash(String v) => v.trim().isEmpty ? '—' : v;

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        color: kNavy,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kHintGray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: kNavy, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color bg,
    required Color fg,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: SizedBox(
        height: 46,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ApplicationService.changes,
        AdoptionService.changes,
      ]),
      builder: (context, _) {
        final app = ApplicationService.byId(applicationId);

        if (app == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Application Details')),
            body: const Center(child: Text('This application no longer exists.')),
          );
        }

        final pet = AdoptionService.byId(app.petId);
        final bool pending = _isPending(app);
        final bool approved = app.status == ApplicationStatus.approved;
        final bool rejected = app.status == ApplicationStatus.rejected;

        // The other people who applied for the same pet, to help the admin
        // pick the most deserving one.
        final others = ApplicationService.forPet(app.petId)
            .where((a) => a.id != app.id)
            .toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: kNavy,
            elevation: 0,
            title: const Text(
              'Application Details',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              // Pet being applied for
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: _photo(pet?.coverPhoto),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.petName,
                          style: const TextStyle(
                            color: kNavy,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (pet != null)
                          Text(
                            '${pet.animalType} · ${pet.summary}',
                            style: const TextStyle(
                                color: kHintGray, fontSize: 13),
                          ),
                        Text(
                          'Posted by: ${app.posterName}',
                          style:
                          const TextStyle(color: kHintGray, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(app),
                ],
              ),

              const Divider(height: 28),
              _section('Applicant'),
              _row('Full Name', app.fullName),
              _row('Phone', app.phone),
              _row('Email', app.email),
              _row('Address', '${app.street}, ${app.location}'),
              _row('Date Applied', _dateText(app.createdAt)),

              const Divider(height: 28),
              _section('Home & Experience'),
              _row('Home Environment', _orDash(app.homeEnvironment)),
              _row('Household Members', _orDash(app.householdMembers)),
              _row('Previous Pets', _orDash(app.previousPets)),
              _row('Pet Care Experience', _orDash(app.careExperience)),

              if (rejected &&
                  (app.rejectionReason ?? '').trim().isNotEmpty) ...[
                const Divider(height: 28),
                _section('Rejection Reason'),
                _row('Reason', app.rejectionReason!),
              ],

              if (others.isNotEmpty) ...[
                const Divider(height: 28),
                _section('Other applicants for ${app.petName}'),
                ...others.map(
                      (o) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.fullName,
                            style: const TextStyle(
                                color: kNavy, fontSize: 15),
                          ),
                        ),
                        _StatusPill(o),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Pending: Reject + Approve.  Approved: Reject.  Rejected: Approve.
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  if (!rejected)
                    _actionButton(
                      text: 'Reject',
                      bg: _kRejectPink,
                      fg: _kRejectText,
                      onPressed: () => _changeStatus(
                        context,
                        app,
                        ApplicationStatus.rejected,
                      ),
                    ),
                  if (pending) const SizedBox(width: 12),
                  if (!approved)
                    _actionButton(
                      text: 'Approve',
                      bg: kBlue,
                      fg: Colors.white,
                      onPressed: () => _changeStatus(
                        context,
                        app,
                        ApplicationStatus.approved,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
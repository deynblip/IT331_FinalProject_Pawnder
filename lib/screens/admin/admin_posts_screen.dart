import 'package:flutter/material.dart';

import '../../models/adoption_pet.dart';
import '../../services/adoption_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/adopt_pet_photo.dart';
import '../../utils/responsive.dart';

// ---------------------------------------------------------------- Helpers

Color _statusBg(PostStatus s) => switch (s) {
  PostStatus.pending => const Color(0xFFFFF3B0),
  PostStatus.approved => const Color(0xFF8ED16F),
  PostStatus.rejected => const Color(0xFFFFB3B3),
};

Color _statusFg(PostStatus s) => switch (s) {
  PostStatus.pending => const Color(0xFF8A6D00),
  PostStatus.approved => const Color(0xFF1F5E10),
  PostStatus.rejected => const Color(0xFF9B1C1C),
};

const Color _kRejectPink = Color(0xFFFF9F9F);
const Color _kRejectText = Color(0xFF7A1F1F);

String _dateText(DateTime? d) {
  if (d == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// Common rejection reasons the admin can tick.
const List<String> _kRejectReasons = [
  'Unclear or suspicious photos',
  'Incomplete information',
  'Selling or asking for fees',
  'Duplicate post',
  'Inappropriate content',
];

/// APPROVE: publishes the post to the Adoption Bulletin and notifies the
/// poster. Returns true when it worked.
Future<bool> _approvePost(BuildContext context, AdoptionPet pet) async {
  final messenger = ScaffoldMessenger.of(context);

  try {
    await AdoptionService.setPostStatus(pet.id, PostStatus.approved);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${pet.name} was approved and is now in the Adoption Bulletin.',
          ),
        ),
      );
    return true;
  } on StateError catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
}

/// REJECT: asks for a reason first (required), hides the post and notifies
/// the poster with that reason. Returns true when it worked.
Future<bool> _rejectPost(BuildContext context, AdoptionPet pet) async {
  final messenger = ScaffoldMessenger.of(context);

  final reason = await showDialog<String>(
    context: context,
    builder: (_) => _RejectPostDialog(petName: pet.name),
  );
  if (reason == null) return false;

  try {
    await AdoptionService.setPostStatus(
      pet.id,
      PostStatus.rejected,
      reason: reason,
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${pet.name} was rejected.')),
      );
    return true;
  } on StateError catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
}

/// Dialog with the common rejection reasons + an optional note.
/// Returns the combined reason text, or null if cancelled.
class _RejectPostDialog extends StatefulWidget {
  final String petName;
  const _RejectPostDialog({required this.petName});

  @override
  State<_RejectPostDialog> createState() => _RejectPostDialogState();
}

class _RejectPostDialogState extends State<_RejectPostDialog> {
  final Set<String> _selected = {};
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _hasReason => _selected.isNotEmpty || _note.text.trim().isNotEmpty;

  String get _reasonText {
    final parts = <String>[
      ..._kRejectReasons.where(_selected.contains),
      if (_note.text.trim().isNotEmpty) _note.text.trim(),
    ];
    return parts.join('; ');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Reject ${widget.petName}?',
        style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The post stays hidden and the poster is told why. '
                  'Choose at least one reason.',
              style: TextStyle(color: kHintGray, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _kRejectReasons.map((r) {
                return FilterChip(
                  label: Text(r, style: const TextStyle(fontSize: 12)),
                  selected: _selected.contains(r),
                  selectedColor: const Color(0xFFFFD6D6),
                  onSelected: (on) => setState(() {
                    if (on) {
                      _selected.add(r);
                    } else {
                      _selected.remove(r);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Extra note for the poster (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed:
          _hasReason ? () => Navigator.pop(context, _reasonText) : null,
          child: const Text(
            'Reject',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final PostStatus status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _statusFg(status),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Widget _photo(String? path, {double iconSize = 30}) {
  final fallback = Container(
    color: const Color(0xFFFFE8D6),
    child: Center(
      child: Icon(Icons.pets, size: iconSize, color: const Color(0xFF8A746C)),
    ),
  );
  if (path == null) return fallback;
  return PetPhoto(path: path, fallback: fallback);
}

// ------------------------------------------------------------ Posts page

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  static const List<String> _filters = [
    'Pending',
    'Approved',
    'Rejected',
    'All',
  ];

  // Opens on Pending: that is the review queue.
  String _selected = 'Pending';

  bool _matches(AdoptionPet pet) {
    switch (_selected) {
      case 'Pending':
        return pet.status == PostStatus.pending;
      case 'Approved':
        return pet.status == PostStatus.approved;
      case 'Rejected':
        return pet.status == PostStatus.rejected;
      default:
        return true;
    }
  }

  int _count(String filter) {
    switch (filter) {
      case 'Pending':
        return AdoptionService.byPostStatus(PostStatus.pending).length;
      case 'Approved':
        return AdoptionService.byPostStatus(PostStatus.approved).length;
      case 'Rejected':
        return AdoptionService.byPostStatus(PostStatus.rejected).length;
      default:
        return AdoptionService.all.length;
    }
  }

  void _openDetails(AdoptionPet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPostDetailsScreen(petId: pet.id),
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
          colors: [Color(0xFFF59E5B), Color(0xFFFFE8D6), Colors.white],
          stops: [0.0, 0.3, 0.5],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 0),
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
                    'Animal Listing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter chips with live counts
                  ValueListenableBuilder<int>(
                    valueListenable: AdoptionService.changes,
                    builder: (context, _, _) => SingleChildScrollView(
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
                                  '$f (${_count(f)})',
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
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Expanded(
              // Rebuilds whenever a post is added, edited or reviewed.
              child: ValueListenableBuilder<int>(
                valueListenable: AdoptionService.changes,
                builder: (context, _, _) {
                  final pets =
                  AdoptionService.all.where(_matches).toList();

                  if (pets.isEmpty) {
                    return Center(
                      child: Text(
                        _selected == 'All'
                            ? 'No adoption posts yet.'
                            : _selected == 'Pending'
                            ? 'No posts waiting for review.'
                            : 'No ${_selected.toLowerCase()} posts.',
                        style: const TextStyle(color: kHintGray),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(context.hPad, 4, context.hPad, 20),
                    itemCount: pets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final pet = pets[i];
                      return _PostCard(
                        pet: pet,
                        onView: () => _openDetails(pet),
                        // Approved -> Reject.  Rejected -> Approve.
                        // (Pending posts are reviewed in Post Details.)
                        onAction: () {
                          if (pet.status == PostStatus.approved) {
                            _rejectPost(context, pet);
                          } else {
                            _approvePost(context, pet);
                          }
                        },
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

class _PostCard extends StatelessWidget {
  final AdoptionPet pet;
  final VoidCallback onView;
  final VoidCallback onAction;

  const _PostCard({
    required this.pet,
    required this.onView,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = pet.status == PostStatus.pending;
    final bool isApproved = pet.status == PostStatus.approved;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E2D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                  child: _photo(pet.coverPhoto),
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
                            pet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kNavy,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _StatusPill(pet.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pet.summary,
                      style: const TextStyle(color: kHintGray, fontSize: 12),
                    ),
                    Text(
                      'Posted by: ${pet.posterName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kHintGray, fontSize: 12),
                    ),
                    if (pet.postedAt != null)
                      Text(
                        _dateText(pet.postedAt),
                        style:
                        const TextStyle(color: kHintGray, fontSize: 12),
                      ),
                    if (isPending && pet.resubmitted)
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Text(
                          'Edited by owner - needs re-review',
                          style: TextStyle(
                            color: kBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isPending)
          // Pending posts are reviewed in Post Details (photos, info,
          // contact details) before the admin decides.
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: onView,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Review Post',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
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
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isApproved ? _kRejectPink : kBlue,
                        foregroundColor:
                        isApproved ? _kRejectText : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isApproved ? 'Reject' : 'Approve',
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

class AdminPostDetailsScreen extends StatefulWidget {
  final String petId;

  const AdminPostDetailsScreen({super.key, required this.petId});

  @override
  State<AdminPostDetailsScreen> createState() =>
      _AdminPostDetailsScreenState();
}

class _AdminPostDetailsScreenState extends State<AdminPostDetailsScreen> {
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

  Widget _petPhotos(AdoptionPet pet) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: pet.photos.isEmpty
            ? _photo(null, iconSize: 60)
            : PageView(children: pet.photos.map((p) => _photo(p)).toList()),
      ),
    );
  }

  Widget _banner({
    required IconData icon,
    required Color color,
    required Color bg,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(AdoptionPet pet) async {
    final ok = await _approvePost(context, pet);
    if (ok && mounted) Navigator.pop(context); // back to the queue
  }

  Future<void> _reject(AdoptionPet pet) async {
    final ok = await _rejectPost(context, pet);
    if (ok && mounted) Navigator.pop(context); // back to the queue
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
    return ValueListenableBuilder<int>(
      valueListenable: AdoptionService.changes,
      builder: (context, _, _) {
        final pet = AdoptionService.byId(widget.petId);

        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Post Details')),
            body: const Center(child: Text('This post no longer exists.')),
          );
        }

        final bool isPending = pet.status == PostStatus.pending;
        final bool isApproved = pet.status == PostStatus.approved;
        final bool isRejected = pet.status == PostStatus.rejected;

        return Scaffold(
          backgroundColor: kCream,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: kNavy,
            elevation: 0,
            title: const Text(
              'Post Details',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(context.hPad, 4, context.hPad, 20),
            children: [
              _petPhotos(pet),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pet.name,
                      style: const TextStyle(
                        color: kNavy,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusPill(pet.status),
                ],
              ),
              const SizedBox(height: 14),

              if (isPending && pet.resubmitted)
                _banner(
                  icon: Icons.edit_note,
                  color: kNavy,
                  bg: const Color(0xFFFFE8D6),
                  text: 'The owner edited this post. Please review it again.',
                ),
              if (isRejected)
                _banner(
                  icon: Icons.cancel_outlined,
                  color: const Color(0xFF9B1C1C),
                  bg: const Color(0xFFFFE3E3),
                  text:
                  'Rejected. Reason: ${pet.rejectionReason ?? 'No reason given.'}',
                ),

              _section('Pet'),
              _row('Animal Type', pet.animalType),
              _row('Age', pet.age),
              _row('Sex', pet.sex),
              _row('Location', pet.location),
              _row('Description', pet.descriptionOrDefault),
              _row('Health Information', pet.healthInfoOrDefault),
              _row('Pet Source', pet.source.label),
              _row(pet.source.reasonLabel, _orDash(pet.reasonForAdoption)),

              const Divider(height: 28),
              _section('Pet Owner'),
              _row('Posted by', pet.posterName),
              if (pet.postedAt != null)
                _row('Date Posted', _dateText(pet.postedAt)),
              _row('Contact Person', _orDash(pet.contactPerson)),
              _row('Phone', _orDash(pet.contactPhone)),
              _row('Email', _orDash(pet.contactEmail)),
            ],
          ),
          // Pending: Reject + Approve.  Approved: Reject.  Rejected: Approve.
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 12),
              child: Row(
                children: [
                  if (!isRejected)
                    _actionButton(
                      text: 'Reject',
                      bg: _kRejectPink,
                      fg: _kRejectText,
                      onPressed: () => _reject(pet),
                    ),
                  if (isPending) const SizedBox(width: 12),
                  if (!isApproved)
                    _actionButton(
                      text: 'Approve',
                      bg: kBlue,
                      fg: Colors.white,
                      onPressed: () => _approve(pet),
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
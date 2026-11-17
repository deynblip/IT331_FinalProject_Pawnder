import 'package:flutter/material.dart';

import '../../models/adoption_pet.dart';
import '../../services/adoption_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/adopt_pet_photo.dart';

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

/// Approve / reject a post through the service (the service itself checks
/// that the logged-in account is an admin). Asks first before rejecting.
Future<void> _changePostStatus(
    BuildContext context,
    AdoptionPet pet,
    PostStatus status,
    ) async {
  final messenger = ScaffoldMessenger.of(context);

  if (status == PostStatus.rejected) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject ${pet.name}?',
          style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This post will not be shown on the Adopt board.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }

  try {
    await AdoptionService.setPostStatus(pet.id, status);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            status == PostStatus.approved
                ? '${pet.name} was approved and is now on the Adopt board.'
                : '${pet.name} was rejected.',
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
    color: const Color(0xFFE6E9EF),
    child: Center(
      child: Icon(Icons.pets, size: iconSize, color: const Color(0xFF8A8F98)),
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
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  String _selected = 'All';

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
                    'Animal Listing',
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
              // Rebuilds whenever a post is added, edited or reviewed.
              child: ValueListenableBuilder<int>(
                valueListenable: AdoptionService.changes,
                builder: (context, _, __) {
                  final pets =
                  AdoptionService.all.where(_matches).toList();

                  if (pets.isEmpty) {
                    return Center(
                      child: Text(
                        _selected == 'All'
                            ? 'No adoption posts yet.'
                            : 'No ${_selected.toLowerCase()} posts.',
                        style: const TextStyle(color: kHintGray),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: pets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final pet = pets[i];
                      return _PostCard(
                        pet: pet,
                        onView: () => _openDetails(pet),
                        // Approved -> Reject.  Pending / Rejected -> Approve.
                        onAction: () => _changePostStatus(
                          context,
                          pet,
                          pet.status == PostStatus.approved
                              ? PostStatus.rejected
                              : PostStatus.approved,
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
    final bool isApproved = pet.status == PostStatus.approved;

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
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isApproved ? _kRejectPink : kBlue,
                      foregroundColor: isApproved ? _kRejectText : Colors.white,
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

class AdminPostDetailsScreen extends StatelessWidget {
  final String petId;

  const AdminPostDetailsScreen({super.key, required this.petId});

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
      builder: (context, _, __) {
        final pet = AdoptionService.byId(petId);

        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Post Details')),
            body: const Center(child: Text('This post no longer exists.')),
          );
        }

        final bool isApproved = pet.status == PostStatus.approved;
        final bool isRejected = pet.status == PostStatus.rejected;

        return Scaffold(
          backgroundColor: Colors.white,
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
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

              _section('Pet'),
              _row('Animal Type', pet.animalType),
              _row('Age', pet.age),
              _row('Sex', pet.sex),
              _row('Location', pet.location),
              _row('Description', pet.descriptionOrDefault),
              _row('Health Information', pet.healthInfoOrDefault),
              _row('Reason for Adoption', _orDash(pet.reasonForAdoption)),

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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  if (!isRejected)
                    _actionButton(
                      text: 'Reject',
                      bg: _kRejectPink,
                      fg: _kRejectText,
                      onPressed: () => _changePostStatus(
                        context,
                        pet,
                        PostStatus.rejected,
                      ),
                    ),
                  if (!isRejected && !isApproved) const SizedBox(width: 12),
                  if (!isApproved)
                    _actionButton(
                      text: 'Approve',
                      bg: kBlue,
                      fg: Colors.white,
                      onPressed: () => _changePostStatus(
                        context,
                        pet,
                        PostStatus.approved,
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
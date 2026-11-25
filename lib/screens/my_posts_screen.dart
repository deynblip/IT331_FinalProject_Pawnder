import 'package:flutter/material.dart';

import '../models/adoption_application.dart';
import '../models/adoption_pet.dart';
import '../services/adoption_service.dart';
import '../services/application_service.dart';
import '../utils/app_colors.dart';
import '../utils/application_style.dart';
import '../widgets/adopt_pet_photo.dart';
import '../widgets/status_chip.dart';
import 'owner_application_screen.dart';
import 'post_pet_screen.dart';
import '../utils/responsive.dart';

/// Pets posted by the logged-in user, plus the applications forwarded to
/// them for the final decision (Profile > My Activity > My Adoption Posts).
/// Each post shows its review status: Pending, Approved or Rejected.
class MyPostsScreen extends StatelessWidget {
  final String posterName;

  const MyPostsScreen({super.key, required this.posterName});

  Future<void> _edit(BuildContext context, AdoptionPet pet) async {
    // Editing an approved post sends it back to Pending: warn first.
    if (pet.status == PostStatus.approved) {
      final go = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Edit approved post?',
            style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Saving changes sends this post back to Pending. It will be '
                'hidden from the Adoption Bulletin until the admin approves '
                'it again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (go != true || !context.mounted) return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostPetScreen(posterName: pet.posterName, pet: pet),
      ),
    );
  }

  Future<void> _remove(BuildContext context, AdoptionPet pet) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Remove ${pet.name}?',
          style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This post will be removed from the Adoption Board. '
              'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await AdoptionService.remove(pet.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${pet.name} was removed.')));
    } on StateError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove the post.')),
      );
    }
  }

  void _openApplication(BuildContext context, AdoptionApplication a) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerApplicationScreen(application: a),
      ),
    );
  }

  Widget _sectionTitle(String text, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: kNavy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null)
            Text(subtitle, style: const TextStyle(color: kHintGray)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.hPad),
          // Rebuilds by itself when a post or an application changes.
          child: ListenableBuilder(
            listenable: Listenable.merge([
              AdoptionService.changes,
              ApplicationService.changes,
            ]),
            builder: (context, _) {
              final pets = AdoptionService.mine;
              final requests = ApplicationService.forMyPets();
              final waiting = requests
                  .where((a) => a.status == ApplicationStatus.forwardedToOwner)
                  .toList();
              final decided = requests
                  .where((a) => a.status != ApplicationStatus.forwardedToOwner)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: kBlue),
                      ),
                      const Expanded(
                        child: Text(
                          'My Adoption Posts',
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
                  if (pets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 2),
                      child: Text(
                        pets.length == 1 ? '1 post' : '${pets.length} posts',
                        style: const TextStyle(color: kHintGray),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: pets.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volunteer_activism_outlined,
                              size: 48, color: kHintGray),
                          const SizedBox(height: 12),
                          const Text(
                            "You haven't posted any pets for "
                                'adoption yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kHintGray),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostPetScreen(
                                    posterName: posterName),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Post a Pet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView(
                      children: [
                        if (waiting.isNotEmpty) ...[
                          _sectionTitle(
                            'Needs your decision',
                            subtitle: 'Screened by the admin and '
                                'forwarded to you.',
                          ),
                          ...waiting.map(
                                (a) => _RequestCard(
                              application: a,
                              onTap: () => _openApplication(context, a),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _sectionTitle('My Posts'),
                        ...pets.map(
                              (p) => _PetPostCard(
                            pet: p,
                            waitingCount: waiting
                                .where((a) => a.petId == p.id)
                                .length,
                            onEdit: () => _edit(context, p),
                            onRemove: () => _remove(context, p),
                          ),
                        ),
                        if (decided.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _sectionTitle('Decided'),
                          ...decided.map(
                                (a) => _RequestCard(
                              application: a,
                              onTap: () => _openApplication(context, a),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Shared bits

const Color _kBorder = Color(0xFFF5DEC8);

BoxDecoration _cardDecoration() => BoxDecoration(
  color: kCardColor,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: _kBorder),
  boxShadow: const [
    BoxShadow(
        color: Color(0x14C4531F), blurRadius: 10, offset: Offset(0, 3)),
  ],
);

Widget _petThumb(String? photo) {
  final placeholder = Container(
    color: const Color(0xFFFFE8D6),
    child: const Center(
      child: Icon(Icons.pets, size: 30, color: Color(0xFF8A746C)),
    ),
  );
  return ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      width: 76,
      height: 76,
      child: photo == null
          ? placeholder
          : PetPhoto(path: photo, fallback: placeholder),
    ),
  );
}

// -------------------------------------------------------------- Pet post

class _PetPostCard extends StatelessWidget {
  final AdoptionPet pet;
  final int waitingCount;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _PetPostCard({
    required this.pet,
    required this.waitingCount,
    required this.onEdit,
    required this.onRemove,
  });

  /// Explains the review status to the poster.
  Widget _reviewNote() {
    switch (pet.status) {
      case PostStatus.pending:
        return _noteBox(
          icon: Icons.hourglass_top,
          color: const Color(0xFF8A6D00),
          bg: const Color(0xFFFFF8D6),
          text: pet.resubmitted
              ? 'Your changes are waiting for admin review. This post is '
              'hidden from the Adoption Bulletin until it is approved.'
              : 'Waiting for admin review. This post is not in the '
              'Adoption Bulletin yet.',
        );
      case PostStatus.rejected:
        return _noteBox(
          icon: Icons.cancel_outlined,
          color: const Color(0xFF9B1C1C),
          bg: const Color(0xFFFFE3E3),
          text: 'Not approved. Reason: '
              '${pet.rejectionReason ?? 'No reason given.'}\n'
              'Edit the post and resubmit it for review.',
        );
      case PostStatus.approved:
        return _noteBox(
          icon: Icons.check_circle_outline,
          color: const Color(0xFF1F5E10),
          bg: const Color(0xFFE6F6DE),
          text: 'Approved. This post is live in the Adoption Bulletin.',
        );
    }
  }

  Widget _noteBox({
    required IconData icon,
    required Color color,
    required Color bg,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool rejected = pet.status == PostStatus.rejected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                _petThumb(pet.coverPhoto),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kNavy,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${pet.animalType}  ·  ${pet.summary}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                        const TextStyle(color: kHintGray, fontSize: 13),
                      ),
                      Text(
                        pet.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                        const TextStyle(color: kHintGray, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      StatusChip(
                        label: pet.status.label,
                        color: pet.status == PostStatus.approved
                            ? const Color(0xFF4CAF6E)
                            : pet.status == PostStatus.rejected
                            ? const Color(0xFFE04F4F)
                            : const Color(0xFFE0A800),
                        fontSize: 11,
                      ),
                      if (waitingCount > 0) ...[
                        const SizedBox(height: 6),
                        StatusChip(
                          label: waitingCount == 1
                              ? '1 awaiting your decision'
                              : '$waitingCount awaiting your decision',
                          color: kBlue,
                          outlined: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            _reviewNote(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(rejected ? 'Resubmit' : 'Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kNavy,
                      side: const BorderSide(color: kNavy),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------ Application card

class _RequestCard extends StatelessWidget {
  final AdoptionApplication application;
  final VoidCallback onTap;

  const _RequestCard({required this.application, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pet = AdoptionService.byId(application.petId);
    final waiting =
        application.status == ApplicationStatus.forwardedToOwner;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _petThumb(pet?.coverPhoto),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                      label: waiting
                          ? 'Needs your decision'
                          : application.status.label,
                      color: waiting
                          ? kBlue
                          : applicationStatusColor(application.status),
                      outlined: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      application.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kNavy,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'For ${application.petName}  ·  ${application.dateText}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kHintGray, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kHintGray),
            ],
          ),
        ),
      ),
    );
  }
}
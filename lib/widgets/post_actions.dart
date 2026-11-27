import 'package:flutter/material.dart';

import '../models/adoption_pet.dart';
import '../screens/post_pet_screen.dart';
import '../services/adoption_service.dart';
import '../utils/app_colors.dart';

// ===============================
// MY ADOPTION POST
// ===============================

/// Opens the edit form. An approved post can be edited up to
/// [AdoptionPet.maxEdits] times (it stays live), so the owner is told how
/// many edits are left first.
Future<void> editMyPost(BuildContext context, AdoptionPet pet) async {
  if (pet.status == PostStatus.approved && pet.editsLeft == 0) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'No edits left',
          style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'You have used all ${AdoptionPet.maxEdits} edits for this post. '
              'If something is wrong, you can remove the post and create a '
              'new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  if (pet.status == PostStatus.approved) {
    final int left = pet.editsLeft;
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Edit approved post?',
          style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Your post stays live in the Adoption Bulletin. You can edit an '
              'approved post up to ${AdoptionPet.maxEdits} times.\n\n'
              'Edits left: $left',
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

/// Asks to confirm, then removes the post. Returns true when it was removed.
Future<bool> removeMyPost(BuildContext context, AdoptionPet pet) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'Remove ${pet.name}?',
        style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
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
  if (ok != true) return false;

  try {
    await AdoptionService.remove(pet.id);
    if (!context.mounted) return true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${pet.name} was removed.')));
    return true;
  } on StateError catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } catch (_) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not remove the post.')),
    );
  }
  return false;
}

/// Explains the review status (Pending / Rejected / Approved) to the owner.
class PostReviewNote extends StatelessWidget {
  final AdoptionPet pet;

  const PostReviewNote({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final Color bg;
    final String text;

    switch (pet.status) {
      case PostStatus.pending:
        icon = Icons.hourglass_top;
        color = const Color(0xFF8A6D00);
        bg = const Color(0xFFFFF8D6);
        text = pet.resubmitted
            ? 'Your changes are waiting for admin review. This post is '
            'hidden from the Adoption Bulletin until it is approved.'
            : 'Waiting for admin review. This post is not in the '
            'Adoption Bulletin yet.';
      case PostStatus.rejected:
        icon = Icons.cancel_outlined;
        color = const Color(0xFF9B1C1C);
        bg = const Color(0xFFFFE3E3);
        text = 'Not approved. Reason: '
            '${pet.rejectionReason ?? 'No reason given.'}\n'
            'Edit the post and resubmit it for review.';
      case PostStatus.approved:
        icon = Icons.check_circle_outline;
        color = const Color(0xFF1F5E10);
        bg = const Color(0xFFE6F6DE);
        text = 'Approved. This post is live in the Adoption Bulletin. '
            'Edits left: ${pet.editsLeft} of ${AdoptionPet.maxEdits}.';
    }

    return Container(
      width: double.infinity,
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
}
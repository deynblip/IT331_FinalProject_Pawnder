// ===================================
// TEMPORARY IN-MEMORY ADOPTION STORE
// ===================================
// Pets posted by users are stored here. Every new post starts as PENDING and
// only shows on the Adopt board after an ADMIN approves it.
// Replace publish() and all with your real backend later.

import 'package:flutter/foundation.dart';

import '../data/mock_adoption_pets.dart';
import '../models/adoption_pet.dart';
import '../models/app_notification.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class AdoptionService {
  static final List<AdoptionPet> _pets = List.of(mockAdoptionPets);

  /// Bumps every time a pet is added, edited, removed or reviewed so
  /// screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void _notify() => changes.value++;

  /// EVERY post, whatever its status (admin side).
  static List<AdoptionPet> get all => List.unmodifiable(_pets);

  /// Only admin-approved posts. The user's Adopt board uses this.
  static List<AdoptionPet> get approved =>
      _pets.where((p) => p.status == PostStatus.approved).toList();

  /// Pets posted by the logged-in user (Profile > My Adoption Posts).
  /// Includes pending / rejected so the owner can see their review status.
  static List<AdoptionPet> get mine =>
      _pets.where((p) => p.isMine).toList();

  /// null = all statuses.
  static List<AdoptionPet> byPostStatus(PostStatus? status) => status == null
      ? List.of(_pets)
      : _pets.where((p) => p.status == status).toList();

  static AdoptionPet? byId(String id) {
    for (final p in _pets) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Submits a pet for review. It starts as PENDING and stays hidden from the
  /// Adopt board until an admin approves it.
  static Future<void> publish({
    required String name,
    required String animalType,
    required String age,
    required String sex,
    required String location,
    required String description,
    required String healthInfo,
    required String reasonForAdoption,
    required String posterName,
    required List<String> photos,
    required String contactPerson,
    required String contactPhone,
    required String contactEmail,
  }) async {
    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 700));

    _pets.insert(
      0,
      AdoptionPet(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        animalType: animalType,
        age: age,
        sex: sex,
        location: location,
        posterName: posterName,
        description: description,
        healthInfo: healthInfo,
        reasonForAdoption: reasonForAdoption,
        photos: photos,
        contactPerson: contactPerson,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        isMine: true, // posted by the logged-in user
        status: PostStatus.pending, // <-- waits for admin
        postedAt: DateTime.now(),
      ),
    );
    _notify();
  }

  /// OWNER ONLY: edit one of your own posts.
  /// An edited post goes back to PENDING so the admin re-checks it.
  /// (Delete the `status:` line below if edits should keep the old status.)
  static Future<void> update(
      String id, {
        required String name,
        required String animalType,
        required String age,
        required String sex,
        required String location,
        required String description,
        required String healthInfo,
        required String reasonForAdoption,
        required List<String> photos,
        required String contactPerson,
        required String contactPhone,
        required String contactEmail,
      }) async {
    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 500));

    final i = _pets.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Pet not found.');
    if (!_pets[i].isMine) {
      throw StateError('You can only edit your own posts.');
    }

    _pets[i] = _pets[i].copyWith(
      name: name,
      animalType: animalType,
      age: age,
      sex: sex,
      location: location,
      description: description,
      healthInfo: healthInfo,
      reasonForAdoption: reasonForAdoption,
      photos: photos,
      contactPerson: contactPerson,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      status: PostStatus.pending, // re-review after an edit
    );
    _notify();
  }

  /// OWNER ONLY: remove one of your own posts from the Adoption Board.
  static Future<void> remove(String id) async {
    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 300));

    final i = _pets.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Pet not found.');
    if (!_pets[i].isMine) {
      throw StateError('You can only remove your own posts.');
    }

    _pets.removeAt(i);
    _notify();
  }

  /// ADMIN ONLY: remove any post (used for reported content).
  /// Tells the poster. Does nothing if the post is already gone.
  static Future<void> removeAsAdmin(String id) async {
    if (!AuthService.isCurrentAdmin) {
      throw StateError('Only an admin can remove posts.');
    }

    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 250));

    final i = _pets.indexWhere((p) => p.id == id);
    if (i == -1) return;

    final pet = _pets.removeAt(i);
    if (pet.isMine) {
      NotificationService.add(
        type: NotificationType.postRemoved,
        title: 'Post removed by admin',
        message: 'Your adoption post for ${pet.name} was removed by an '
            'administrator because it did not follow the community '
            'guidelines.',
      );
    }
    _notify();
  }

  /// ADMIN ONLY: approve or reject a pet post.
  /// Approved = shows on the Adopt board. Rejected = hidden from it.
  static Future<void> setPostStatus(String id, PostStatus status) async {
    if (!AuthService.isCurrentAdmin) {
      throw StateError('Only an admin can approve or reject posts.');
    }

    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 250));

    final i = _pets.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Pet not found.');

    _pets[i] = _pets[i].copyWith(status: status);
    _notifyPoster(_pets[i]);
    _notify();
  }

  /// Tells the poster how the admin decided. Only for the logged-in user's
  /// own posts for now (isMine); the backend will target the right user later.
  static void _notifyPoster(AdoptionPet pet) {
    if (!pet.isMine) return;

    switch (pet.status) {
      case PostStatus.approved:
        NotificationService.add(
          type: NotificationType.postApproved,
          title: 'Post approved',
          message: 'Your adoption post for ${pet.name} was approved and is '
              'now listed on the Adopt board.',
        );
      case PostStatus.rejected:
        NotificationService.add(
          type: NotificationType.postRemoved,
          title: 'Post not approved',
          message: 'Your adoption post for ${pet.name} was not approved by '
              'an administrator, so it is not shown on the Adopt board.',
        );
      case PostStatus.pending:
        break; // nothing to announce
    }
  }
}
// =====================================
// TEMPORARY IN-MEMORY APPLICATION STORE
// =====================================
// Single source of truth for adoption applications. The user's application
// form writes here, and the admin Posts page + dashboard read from here.
// An ADMIN screens applications. The PET OWNER makes the final decision.

import 'package:flutter/foundation.dart';

import '../models/adoption_application.dart';
import '../models/adoption_pet.dart';
import '../models/app_notification.dart';
import 'adoption_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class ApplicationService {
  static final List<AdoptionApplication> _applications = [
    // Sample applicants so the admin Application tab is not empty.
    // Set kShowSampleAdminApplications to false to start with none.
    if (kShowSampleAdminApplications) ..._adminSamples,
  ];

  /// Bumps every time the data changes so screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void _notify() => changes.value++;

  /// Tells the applicant that their application moved forward or was decided.
  /// Only for the logged-in user's own real applications (the sample ones
  /// are skipped). Later, the backend will send this to the right user.
  static void _notifyApplicant(AdoptionApplication a) {
    // Samples have no applicantEmail, so they are skipped. Real applicants
    // are told even though the ADMIN is the one logged in right now (the
    // temporary notification store is shared; the backend will target the
    // right user later).
    if (a.applicantEmail.isEmpty) return;

    final NotificationType type;
    final String title;
    final String message;
    switch (a.status) {
      case ApplicationStatus.forwardedToOwner:
        type = NotificationType.applicationForwarded;
        title = 'Application forwarded';
        message = 'Your application for ${a.petName} passed screening and '
            'was forwarded to ${a.posterName}, who will make the final '
            'decision.';
        break;
      case ApplicationStatus.approved:
        type = NotificationType.applicationApproved;
        title = 'Application approved';
        message = 'Good news! Your application for ${a.petName} was approved.';
        break;
      case ApplicationStatus.rejected:
        type = NotificationType.applicationRejected;
        title = 'Application not approved';
        message = 'Your application for ${a.petName} was not approved.';
        break;
      case ApplicationStatus.pendingScreening:
        return; // nothing to announce yet
    }

    NotificationService.add(
      type: type,
      title: title,
      message: message,
      targetId: a.id,
    );
  }

  // TEMP: sample applications so you can SEE all 4 statuses before the
  // admin and pet-owner screens exist. Set to false to hide them.
  // They are NOT saved, so the admin page and its counts ignore them.
  static const bool kShowDemoApplications = true;

  static AdoptionApplication _demo({
    String fullName = 'Sample Applicant',
    String email = 'applicant@example.com',
    required String id,
    required String petId,
    required String petName,
    required String posterName,
    required ApplicationStatus status,
    required DateTime createdAt,
    String? rejectionReason,
  }) {
    return AdoptionApplication(
      id: id,
      petId: petId,
      petName: petName,
      posterName: posterName,
      fullName: fullName,
      phone: '0993 456 7891',
      email: email,
      province: 'Batangas',
      city: 'Batangas City',
      barangay: 'Alangilan',
      street: 'Sample Street',
      homeEnvironment: 'House with a small fenced yard.',
      householdMembers: '4 (parents and siblings)',
      previousPets: '1 cat',
      careExperience: 'Has cared for pets for 3 years.',
      status: status,
      createdAt: createdAt,
      applicantEmail: '',
      rejectionReason: rejectionReason,
    );
  }

  // Sample applicants shown in the ADMIN Application tab. Tiwi has TWO
  // applicants so you can test picking one (the other gets auto-rejected).
  static const bool kShowSampleAdminApplications = true;

  static final List<AdoptionApplication> _adminSamples = [
    _demo(
      id: 'seed1',
      petId: 'a1',
      petName: 'Tiwi',
      posterName: 'Angela May',
      fullName: 'Dane Angela',
      email: 'dane@example.com',
      status: ApplicationStatus.pendingScreening,
      createdAt: DateTime(2026, 11, 15),
    ),
    _demo(
      id: 'seed2',
      petId: 'a1',
      petName: 'Tiwi',
      posterName: 'Angela May',
      fullName: 'Maria Lopez',
      email: 'maria@example.com',
      status: ApplicationStatus.pendingScreening,
      createdAt: DateTime(2026, 11, 14),
    ),
    _demo(
      id: 'seed3',
      petId: 'a2',
      petName: 'Buddy',
      posterName: 'Shanea Mae',
      fullName: 'Joshua Garcia',
      email: 'joshua@example.com',
      status: ApplicationStatus.pendingScreening,
      createdAt: DateTime(2026, 11, 15),
    ),
    _demo(
      id: 'seed4',
      petId: 'a3',
      petName: 'Mingming',
      posterName: 'Maria Santos',
      fullName: 'Ed Sheeran',
      email: 'ed@example.com',
      status: ApplicationStatus.approved,
      createdAt: DateTime(2026, 11, 13),
    ),
  ];

  // Shown in "My Applications" (the applicant's side).
  static final List<AdoptionApplication> _demoApplications = [
    _demo(
      id: 'demo1',
      petId: 'a2',
      petName: 'Buddy',
      posterName: 'Shanea Mae',
      status: ApplicationStatus.forwardedToOwner,
      createdAt: DateTime(2026, 11, 12),
    ),
    _demo(
      id: 'demo2',
      petId: 'a3',
      petName: 'Mingming',
      posterName: 'Maria Santos',
      status: ApplicationStatus.approved,
      createdAt: DateTime(2026, 11, 10),
    ),
    _demo(
      id: 'demo3',
      petId: 'a5',
      petName: 'Mimi',
      posterName: 'Shanea Mae',
      status: ApplicationStatus.rejected,
      createdAt: DateTime(2026, 11, 8),
      rejectionReason: 'The pet owner chose an applicant who lives closer.',
    ),
  ];

  // TEMP: applications sent TO the logged-in user's own pet (Brownie, a4),
  // so you can test the owner's decision in My Adoption Posts.
  static final List<AdoptionApplication> _ownerDemo = [
    _demo(
      id: 'demo4',
      petId: 'a4',
      petName: 'Brownie',
      posterName: 'Dane Angela',
      status: ApplicationStatus.forwardedToOwner,
      createdAt: DateTime(2026, 11, 14),
    ),
  ];

  /// Applications of the logged-in user only, newest first.
  static List<AdoptionApplication> forCurrentUser() {
    final email = AuthService.currentEmail;
    final mine = _applications
        .where((a) => email != null && a.applicantEmail == email)
        .toList();
    if (kShowDemoApplications) mine.addAll(_demoApplications);
    mine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  /// Applications for the logged-in user's OWN pets that already passed
  /// admin screening (waiting for a decision, or already decided).
  /// Newest first.
  static List<AdoptionApplication> forMyPets() {
    final myPetIds = AdoptionService.mine.map((p) => p.id).toSet();
    final list = <AdoptionApplication>[
      ..._applications,
      if (kShowDemoApplications) ..._ownerDemo,
    ]
        .where((a) =>
    myPetIds.contains(a.petId) &&
        a.status != ApplicationStatus.pendingScreening)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static List<AdoptionApplication> get all =>
      List.unmodifiable(_applications);

  /// null = all statuses.
  static List<AdoptionApplication> byStatus(ApplicationStatus? status) =>
      status == null
          ? List.of(_applications)
          : _applications.where((a) => a.status == status).toList();

  static AdoptionApplication? byId(String id) {
    for (final a in _applications) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Every application for one pet (the admin compares them to pick one).
  static List<AdoptionApplication> forPet(String petId) =>
      _applications.where((a) => a.petId == petId).toList();

  /// True if THE LOGGED-IN USER already applied for this pet.
  /// (Other people may apply for the same pet; the admin picks one.)
  static bool hasApplied(String petId) {
    final email = AuthService.currentEmail;
    if (email == null) return false;
    return _applications
        .any((a) => a.petId == petId && a.applicantEmail == email);
  }

  static Future<void> submit({
    required AdoptionPet pet,
    required String fullName,
    required String phone,
    required String email,
    required String province,
    required String city,
    required String barangay,
    required String street,
    required String homeEnvironment,
    required String householdMembers,
    required String previousPets,
    required String careExperience,
  }) async {
    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 700));

    // Safety net: one application per pet PER USER.
    if (hasApplied(pet.id)) {
      throw StateError('Already applied for this pet.');
    }

    _applications.insert(
      0,
      AdoptionApplication(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        petId: pet.id,
        petName: pet.name,
        posterName: pet.posterName,
        fullName: fullName,
        phone: phone,
        email: email,
        province: province,
        city: city,
        barangay: barangay,
        street: street,
        homeEnvironment: homeEnvironment,
        householdMembers: householdMembers,
        previousPets: previousPets,
        careExperience: careExperience,
        status: ApplicationStatus.pendingScreening, // waits for admin
        createdAt: DateTime.now(),
        applicantEmail: AuthService.currentEmail ?? '',
      ),
    );
    _notify();
  }

  /// ADMIN ONLY: approve or reject an application.
  /// Approving one applicant automatically rejects the other waiting
  /// applicants for the same pet, so only ONE person is picked per pet.
  static Future<void> setStatus(
      String id,
      ApplicationStatus status, {
        String? reason,
      }) async {
    if (!AuthService.isCurrentAdmin) {
      throw StateError('Only an admin can approve or reject applications.');
    }

    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 250));

    final i = _applications.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Application not found.');
    final target = _applications[i];

    if (status == ApplicationStatus.approved) {
      final alreadyPicked = _applications.any((a) =>
      a.petId == target.petId &&
          a.id != id &&
          a.status == ApplicationStatus.approved);
      if (alreadyPicked) {
        throw StateError('Another applicant was already approved for '
            '${target.petName}. Reject that application first.');
      }
    }

    _applications[i] = target.copyWith(
      status: status,
      rejectionReason: status == ApplicationStatus.rejected ? reason : null,
    );
    _notifyApplicant(_applications[i]);

    // The admin picked this applicant -> close the others for this pet.
    if (status == ApplicationStatus.approved) {
      for (var k = 0; k < _applications.length; k++) {
        final a = _applications[k];
        final waiting = a.status == ApplicationStatus.pendingScreening ||
            a.status == ApplicationStatus.forwardedToOwner;
        if (a.petId == target.petId && a.id != id && waiting) {
          _applications[k] = a.copyWith(
            status: ApplicationStatus.rejected,
            rejectionReason: 'Another applicant was selected for this pet.',
          );
          _notifyApplicant(_applications[k]);
        }
      }
    }

    _notify();
  }

  /// PET OWNER ONLY: final decision on an application that the admin
  /// forwarded to you. Only works on the owner's own pets.
  static Future<void> decideAsOwner(
      String id, {
        required bool approve,
        String? reason,
      }) async {
    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 300));

    final newStatus =
    approve ? ApplicationStatus.approved : ApplicationStatus.rejected;

    AdoptionApplication check(AdoptionApplication a) {
      if (AdoptionService.byId(a.petId)?.isMine != true) {
        throw StateError('You can only decide on applications for your pets.');
      }
      if (a.status != ApplicationStatus.forwardedToOwner) {
        throw StateError('This application is not waiting for a decision.');
      }
      return a.copyWith(
        status: newStatus,
        rejectionReason: approve ? null : reason,
      );
    }

    final i = _applications.indexWhere((a) => a.id == id);
    if (i != -1) {
      _applications[i] = check(_applications[i]);
      _notifyApplicant(_applications[i]);
      _notify();
      return;
    }

    final j = _ownerDemo.indexWhere((a) => a.id == id);
    if (j != -1) {
      _ownerDemo[j] = check(_ownerDemo[j]);
      _notify();
      return;
    }

    throw StateError('Application not found.');
  }
}
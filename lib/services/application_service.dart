// ===================================
// ADOPTION APPLICATIONS (Supabase)
// ===================================
// An applicant sends an application. An ADMIN screens it (forward or reject).
// The PET OWNER makes the final decision. The applicant can edit it while it
// is still pending screening, or withdraw it until it is decided.
// The screens read the lists below. The data is loaded from the database;
// listen to [changes] to refresh a screen. The database decides who can see
// what (own applications, forwarded ones for your pets, everything for admins).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/adoption_application.dart';
import '../models/adoption_pet.dart';
import 'adoption_service.dart';
import 'auth_service.dart';
import 'db_errors.dart';

class ApplicationService {
  static SupabaseClient get _db => Supabase.instance.client;

  static List<AdoptionApplication> _applications = [];

  static bool _loaded = false;
  static Future<void>? _loading;
  static String? _loadError;
  static DateTime? _lastTry;
  static int _generation = 0;

  /// Bumps every time the data changes so screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void _notify() => changes.value++;

  static bool get isLoaded => _loaded;
  static String? get loadError => _loadError;

  // ---------------------------------------------------------------- Loading

  static Future<void> load() {
    final Future<void>? running = _loading;
    if (running != null) return running;
    final Future<void> f = _fetch().whenComplete(() => _loading = null);
    _loading = f;
    return f;
  }

  /// Loads again even if a load is already running (used right after the
  /// user changes something, so the screen shows the newest data).
  static Future<void> refresh() async {
    final Future<void>? running = _loading;
    if (running != null) await running;
    await load();
  }

  static void _kick() {
    if (_loaded || _loading != null) return;
    if (AuthService.currentUserId == null) return;
    final DateTime? t = _lastTry;
    if (t != null &&
        DateTime.now().difference(t) < const Duration(seconds: 15)) {
      return;
    }
    unawaited(load());
  }

  static Future<void> _fetch() async {
    final int gen = _generation;
    _lastTry = DateTime.now();
    try {
      final rows = await _db
          .from('adoption_applications')
          .select('*, post:adoption_posts(name, poster:profiles!poster_id(full_name))')
          .order('created_at', ascending: false);
      if (gen != _generation) return; // logged out while loading

      _applications = [
        for (final dynamic r in rows)
          _fromRow(Map<String, dynamic>.from(r as Map)),
      ];
      _loaded = true;
      _loadError = null;
    } catch (e) {
      if (gen != _generation) return;
      _loadError =
          friendlyDbError(e, fallback: 'Could not load the applications.');
    }
    _notify();
  }

  /// Forget everything (log out / switch account).
  static void reset() {
    _generation++;
    _applications = [];
    _loaded = false;
    _loading = null;
    _loadError = null;
    _lastTry = null;
    _notify();
  }

  static AdoptionApplication _fromRow(Map<String, dynamic> row) {
    final String petId = row['post_id'] as String;

    // The pet's name and poster: from the joined post, or from the adoption
    // list if the database did not return the post.
    final dynamic post = row['post'];
    String petName = '';
    String posterName = '';
    if (post is Map) {
      petName = (post['name'] as String?) ?? '';
      final dynamic poster = post['poster'];
      if (poster is Map) posterName = (poster['full_name'] as String?) ?? '';
    }
    if (petName.isEmpty || posterName.isEmpty) {
      final AdoptionPet? pet = AdoptionService.byId(petId);
      if (petName.isEmpty) petName = pet?.name ?? 'this pet';
      if (posterName.isEmpty) posterName = pet?.posterName ?? 'the pet owner';
    }

    return AdoptionApplication(
      id: row['id'] as String,
      petId: petId,
      petName: petName,
      posterName: posterName,
      fullName: (row['full_name'] as String?) ?? '',
      phone: (row['phone'] as String?) ?? '',
      email: (row['email'] as String?) ?? '',
      province: (row['province'] as String?) ?? 'Batangas',
      city: (row['city'] as String?) ?? '',
      barangay: (row['barangay'] as String?) ?? '',
      street: (row['street'] as String?) ?? '',
      homeEnvironment: (row['home_environment'] as String?) ?? '',
      householdMembers: (row['household_members'] as String?) ?? '',
      previousPets: (row['previous_pets'] as String?) ?? '',
      careExperience: (row['care_experience'] as String?) ?? '',
      reasonForAdopting: (row['reason_for_adopting'] as String?) ?? '',
      status: _statusFrom(row['status'] as String?),
      createdAt:
      DateTime.tryParse((row['created_at'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
      applicantId: (row['applicant_id'] as String?) ?? '',
      rejectionReason: row['rejection_reason'] as String?,
    );
  }

  static ApplicationStatus _statusFrom(String? s) => switch (s) {
    'forwarded_to_owner' => ApplicationStatus.forwardedToOwner,
    'approved' => ApplicationStatus.approved,
    'rejected' => ApplicationStatus.rejected,
    'withdrawn' => ApplicationStatus.withdrawn,
    _ => ApplicationStatus.pendingScreening,
  };

  // ---------------------------------------------------------------- Lists

  /// Applications of the logged-in user only, newest first.
  static List<AdoptionApplication> forCurrentUser() {
    _kick();
    final String? uid = AuthService.currentUserId;
    final mine = _applications.where((a) => a.applicantId == uid).toList();
    mine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  /// Applications for the logged-in user's OWN pets that already passed
  /// admin screening (waiting for a decision, or already decided).
  /// Withdrawn ones are left out. Newest first.
  static List<AdoptionApplication> forMyPets() {
    _kick();
    final String? uid = AuthService.currentUserId;
    final myPetIds = AdoptionService.mine.map((p) => p.id).toSet();
    final list = _applications
        .where((a) =>
    a.applicantId != uid &&
        myPetIds.contains(a.petId) &&
        a.status != ApplicationStatus.pendingScreening &&
        a.status != ApplicationStatus.withdrawn)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Everything the database lets this user see (all of them for an admin).
  static List<AdoptionApplication> get all {
    _kick();
    return List.unmodifiable(_applications);
  }

  /// How many applications are waiting for the admin's screening.
  static int get pendingCount {
    _kick();
    return _applications
        .where((a) => a.status == ApplicationStatus.pendingScreening)
        .length;
  }

  /// null = all statuses.
  static List<AdoptionApplication> byStatus(ApplicationStatus? status) {
    _kick();
    return status == null
        ? List.of(_applications)
        : _applications.where((a) => a.status == status).toList();
  }

  static AdoptionApplication? byId(String id) {
    _kick();
    for (final a in _applications) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Every application for one pet (the admin compares them to pick one).
  static List<AdoptionApplication> forPet(String petId) {
    _kick();
    return _applications.where((a) => a.petId == petId).toList();
  }

  /// True if THE LOGGED-IN USER already applied for this pet (a withdrawn
  /// application counts too: there is one application per pet per user).
  static bool hasApplied(String petId) {
    _kick();
    final String? uid = AuthService.currentUserId;
    if (uid == null) return false;
    return _applications.any((a) => a.petId == petId && a.applicantId == uid);
  }

  // ---------------------------------------------------------------- Actions

  /// Runs a database call and turns any failure into a [StateError] with a
  /// message the user can read.
  static Future<void> _run(Future<dynamic> Function() call,
      {required String fallback}) async {
    try {
      await call();
    } catch (e) {
      throw StateError(friendlyDbError(e, fallback: fallback));
    }
    await refresh();
  }

  /// Sends a new application. It starts as PENDING and waits for the admin.
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
    String reasonForAdopting = '',
  }) {
    return _run(
          () => _db.rpc('submit_application', params: {
        'p_post_id': pet.id,
        'p_full_name': fullName.trim(),
        'p_phone': phone.trim(),
        'p_email': email.trim(),
        'p_city': city.trim(),
        'p_barangay': barangay.trim(),
        'p_street': street.trim(),
        'p_home_environment': homeEnvironment.trim(),
        'p_household_members': householdMembers.trim(),
        'p_previous_pets': previousPets.trim(),
        'p_care_experience': careExperience.trim(),
        'p_valid_id_agreed': true,
        'p_reason_for_adopting': reasonForAdopting.trim(),
      }),
      fallback: 'Could not send your application. Please try again.',
    );
  }

  /// APPLICANT: change the answers. Only while pending screening.
  static Future<void> updateMine(
      String id, {
        required String fullName,
        required String phone,
        required String email,
        required String city,
        required String barangay,
        required String street,
        required String homeEnvironment,
        required String householdMembers,
        required String previousPets,
        required String careExperience,
        String reasonForAdopting = '',
      }) {
    return _run(
          () => _db.rpc('update_my_application', params: {
        'p_id': id,
        'p_full_name': fullName.trim(),
        'p_phone': phone.trim(),
        'p_email': email.trim(),
        'p_city': city.trim(),
        'p_barangay': barangay.trim(),
        'p_street': street.trim(),
        'p_home_environment': homeEnvironment.trim(),
        'p_household_members': householdMembers.trim(),
        'p_previous_pets': previousPets.trim(),
        'p_care_experience': careExperience.trim(),
        'p_reason_for_adopting': reasonForAdopting.trim(),
      }),
      fallback: 'Could not save your changes. Please try again.',
    );
  }

  /// APPLICANT: take the application back (pending or forwarded only).
  static Future<void> withdrawMine(String id) {
    return _run(
          () => _db.rpc('withdraw_my_application', params: {'p_id': id}),
      fallback: 'Could not withdraw your application. Please try again.',
    );
  }

  /// ADMIN ONLY: screening step. The admin either forwards a pending
  /// application to the pet owner (who makes the final decision) or rejects
  /// it with an optional reason.
  static Future<void> setStatus(
      String id,
      ApplicationStatus status, {
        String? reason,
      }) {
    if (!AuthService.isCurrentAdmin) {
      throw StateError('Only an admin can screen applications.');
    }
    if (status != ApplicationStatus.forwardedToOwner &&
        status != ApplicationStatus.rejected) {
      throw StateError('Only the pet owner can approve an application.');
    }
    return _run(
          () => _db.rpc('admin_screen_application', params: {
        'p_id': id,
        'p_forward': status == ApplicationStatus.forwardedToOwner,
        'p_reason': reason,
      }),
      fallback: 'Could not update the application. Please try again.',
    );
  }

  /// PET OWNER ONLY: final decision on an application that the admin
  /// forwarded to you. The database checks that it is your pet.
  static Future<void> decideAsOwner(
      String id, {
        required bool approve,
        String? reason,
      }) {
    return _run(
          () => _db.rpc('owner_decide_application', params: {
        'p_id': id,
        'p_approve': approve,
        'p_reason': reason,
      }),
      fallback: 'Could not save your decision. Please try again.',
    );
  }
}
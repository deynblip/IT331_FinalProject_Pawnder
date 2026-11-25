
// ===================================
// ADOPTION POSTS (Supabase)  -  Batch 5A
// ===================================
// Pre-approval: every new post starts as PENDING and only shows on the Adopt
// board after an ADMIN approves it. An edited post goes back to PENDING.
// The screens still read the lists below (approved, mine, all...). The data
// is loaded from the database; listen to [changes] to refresh a screen.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/adoption_pet.dart';
import 'auth_service.dart';
import 'db_errors.dart';

class AdoptionService {
  static SupabaseClient get _db => Supabase.instance.client;

  static const String _bucket = 'pet-photos';
  static const int _maxPhotoBytes = 5 * 1024 * 1024;

  static List<AdoptionPet> _pets = [];

  /// Removed posts. Not listed anywhere, but an applicant's old application
  /// can still look up its pet here.
  static final Map<String, AdoptionPet> _hidden = {};

  static bool _loaded = false;
  static Future<void>? _loading;
  static String? _loadError;
  static DateTime? _lastTry;
  static int _generation = 0;

  /// Bumps every time the posts change so screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void _notify() => changes.value++;

  static bool get isLoaded => _loaded;
  static String? get loadError => _loadError;

  // ---------------------------------------------------------------- Loading

  /// Loads the posts the user is allowed to see (the database decides):
  /// approved posts, own posts, posts applied to, or everything for admins.
  static Future<void> load() {
    final Future<void>? running = _loading;
    if (running != null) return running;
    final Future<void> f = _fetch().whenComplete(() => _loading = null);
    _loading = f;
    return f;
  }

  /// Starts loading once, the first time a screen asks for the data.
  /// After a failure it tries again, but not more than once every 15 seconds.
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
          .from('adoption_posts')
          .select('*, poster:profiles!poster_id(full_name), '
          'contact:adoption_post_contacts(*)')
          .order('created_at', ascending: false);
      if (gen != _generation) return; // logged out while loading

      final List<AdoptionPet> visible = [];
      final Map<String, AdoptionPet> hidden = {};
      for (final dynamic r in rows) {
        final Map<String, dynamic> row = Map<String, dynamic>.from(r as Map);
        final AdoptionPet pet = _fromRow(row);
        if (row['removed_at'] != null) {
          hidden[pet.id] = pet;
        } else {
          visible.add(pet);
        }
      }
      _pets = visible;
      _hidden
        ..clear()
        ..addAll(hidden);
      _loaded = true;
      _loadError = null;
    } catch (e) {
      if (gen != _generation) return;
      _loadError =
          friendlyDbError(e, fallback: 'Could not load the adoption posts.');
    }
    _notify();
  }

  /// Forget everything (log out / switch account).
  static void reset() {
    _generation++;
    _pets = [];
    _hidden.clear();
    _loaded = false;
    _loading = null;
    _loadError = null;
    _lastTry = null;
    _notify();
  }

  static AdoptionPet _fromRow(Map<String, dynamic> row) {
    final dynamic poster = row['poster'];
    final String posterName = poster is Map
        ? ((poster['full_name'] as String?) ?? 'Pawnder user')
        : 'Pawnder user';

    // Contact details: only the poster, admins and forwarded applicants can
    // see them. For everyone else this is empty.
    dynamic c = row['contact'];
    if (c is List) c = c.isEmpty ? null : c.first;
    final Map<String, dynamic> contact =
    c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{};

    final List<dynamic> paths = (row['photo_paths'] as List<dynamic>?) ?? [];
    final bool mine = row['poster_id'] == AuthService.currentUserId;
    final String status = (row['status'] as String?) ?? 'pending';

    return AdoptionPet(
      id: row['id'] as String,
      name: (row['name'] as String?) ?? '',
      animalType: (row['animal_type'] as String?) ?? 'Other',
      age: (row['age_text'] as String?) ?? '',
      sex: (row['sex'] as String?) ?? '',
      location: (row['location'] as String?) ??
          '${row['barangay']}, ${row['city']}, ${row['province']}',
      posterName: posterName,
      description: (row['description'] as String?) ?? '',
      healthInfo: (row['health_info'] as String?) ?? '',
      photos: paths
          .map((p) => _db.storage.from(_bucket).getPublicUrl(p as String))
          .toList(),
      isMine: mine,
      reasonForAdoption: (row['reason'] as String?) ?? '',
      contactPerson: (contact['contact_person'] as String?) ?? '',
      contactPhone: (contact['contact_phone'] as String?) ?? '',
      contactEmail: (contact['contact_email'] as String?) ?? '',
      street: (contact['street'] as String?) ?? '',
      status: PostStatus.values.firstWhere(
            (s) => s.name == status,
        orElse: () => PostStatus.pending,
      ),
      postedAt: DateTime.tryParse((row['created_at'] as String?) ?? '')
          ?.toLocal(),
      rescuedBy: row['rescued_by'] as String?,
      rejectionReason: row['rejection_reason'] as String?,
      resubmitted: row['resubmitted'] == true,
      ownerEmail: mine ? AuthService.currentEmail : null,
      source: row['source'] == 'rehoming'
          ? PetSource.rehoming
          : PetSource.rescuedStray,
    );
  }

  // ---------------------------------------------------------------- Lists

  /// EVERY post, whatever its status (admin side).
  static List<AdoptionPet> get all {
    _kick();
    return List.unmodifiable(_pets);
  }

  /// Only admin-approved posts. The user's Adopt board uses this.
  static List<AdoptionPet> get approved {
    _kick();
    return _pets.where((p) => p.status == PostStatus.approved).toList();
  }

  /// Pets posted by the logged-in user (Profile > My Adoption Posts).
  /// Includes pending / rejected so the owner can see the review status.
  static List<AdoptionPet> get mine {
    _kick();
    return _pets.where((p) => p.isMine).toList();
  }

  /// null = all statuses.
  static List<AdoptionPet> byPostStatus(PostStatus? status) {
    _kick();
    return status == null
        ? List.of(_pets)
        : _pets.where((p) => p.status == status).toList();
  }

  /// How many posts are waiting for the admin.
  static int get pendingCount {
    _kick();
    return _pets.where((p) => p.status == PostStatus.pending).length;
  }

  static AdoptionPet? byId(String id) {
    _kick();
    for (final p in _pets) {
      if (p.id == id) return p;
    }
    return _hidden[id];
  }

  // ---------------------------------------------------------------- Post / edit / remove

  /// Submits a pet for review. It starts as PENDING and stays hidden from the
  /// Adopt board until an admin approves it. A Verified Rescuer's post is
  /// tagged "Rescued by [Organization]" by the database.
  /// [photos] are picked photo paths (uploaded here).
  /// Throws [StateError] with a message for the user.
  static Future<void> publish({
    required String name,
    required String animalType,
    required String age,
    required String sex,
    required String location, // "Barangay, City, Province"
    required String description,
    required String healthInfo,
    required String reasonForAdoption,
    required String posterName, // not needed anymore (the database knows)
    required List<String> photos,
    required String contactPerson,
    required String contactPhone,
    required String contactEmail,
    String street = '',
    PetSource source = PetSource.rescuedStray,
  }) async {
    final String? userId = AuthService.currentUserId;
    if (userId == null) throw StateError('Please log in first.');

    final List<String> uploaded = [];
    final List<String> place = _splitLocation(location);
    try {
      final List<String> paths = await _storePhotos(photos, userId, uploaded);
      if (paths.isEmpty) throw StateError('Please add at least one photo.');

      await _db.rpc('create_adoption_post', params: {
        'p_name': name.trim(),
        'p_animal_type': animalType,
        'p_age_text': age.trim(),
        'p_sex': sex,
        'p_source': _sourceValue(source),
        'p_description': description.trim(),
        'p_health_info': healthInfo.trim(),
        'p_reason': reasonForAdoption.trim(),
        'p_barangay': place[0],
        'p_city': place[1],
        'p_street': street.trim(),
        'p_photo_paths': paths,
        'p_contact_person': contactPerson.trim(),
        'p_contact_phone': contactPhone.trim(),
        'p_contact_email': contactEmail.trim(),
      });
    } on StateError {
      await _removeFiles(uploaded);
      rethrow;
    } catch (e) {
      await _removeFiles(uploaded);
      throw StateError(friendlyDbError(e,
          fallback: 'Could not save the post. Please try again.'));
    }
    await load();
  }

  /// OWNER ONLY: edit one of your own posts. ANY edit sends the post back to
  /// PENDING (hidden from the Adoption Bulletin) so the admin re-checks it.
  /// [photos] can mix existing photo links (kept) and newly picked photos
  /// (uploaded here).
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
        String street = '',
        PetSource? source,
      }) async {
    final String? userId = AuthService.currentUserId;
    if (userId == null) throw StateError('Please log in first.');

    final AdoptionPet? existing = byId(id);
    final List<String> oldPaths = (existing?.photos ?? const <String>[])
        .map(_pathFromUrl)
        .whereType<String>()
        .toList();

    final List<String> uploaded = [];
    final List<String> place = _splitLocation(location);
    late final List<String> paths;
    try {
      paths = await _storePhotos(photos, userId, uploaded);
      if (paths.isEmpty) throw StateError('Please add at least one photo.');

      await _db.rpc('update_adoption_post', params: {
        'p_id': id,
        'p_name': name.trim(),
        'p_animal_type': animalType,
        'p_age_text': age.trim(),
        'p_sex': sex,
        'p_source': _sourceValue(source ?? existing?.source ?? PetSource.rescuedStray),
        'p_description': description.trim(),
        'p_health_info': healthInfo.trim(),
        'p_reason': reasonForAdoption.trim(),
        'p_barangay': place[0],
        'p_city': place[1],
        'p_street': street.trim(),
        'p_photo_paths': paths,
        'p_contact_person': contactPerson.trim(),
        'p_contact_phone': contactPhone.trim(),
        'p_contact_email': contactEmail.trim(),
      });
    } on StateError {
      await _removeFiles(uploaded);
      rethrow;
    } catch (e) {
      await _removeFiles(uploaded);
      throw StateError(friendlyDbError(e,
          fallback: 'Could not save your changes. Please try again.'));
    }

    // Photos that are no longer used can go.
    await _removeFiles(oldPaths.where((p) => !paths.contains(p)).toList());
    await load();
  }

  /// OWNER ONLY: remove one of your own posts from the Adoption Board.
  /// The record is kept (hidden); waiting applicants are told.
  static Future<void> remove(String id) async {
    try {
      await _db.rpc('remove_my_adoption_post', params: {'p_id': id});
    } catch (e) {
      throw StateError(friendlyDbError(e,
          fallback: 'Could not remove the post. Please try again.'));
    }
    await load();
  }

  /// ADMIN ONLY: remove any post (used for reported content).
  /// TEMPORARY: only hides it on this phone. Batch 6 will connect it to
  /// `admin_remove_reported_content` in the database.
  static Future<void> removeAsAdmin(String id) async {
    if (!AuthService.isCurrentAdmin) {
      throw StateError('Only an admin can remove posts.');
    }
    final int before = _pets.length;
    _pets = _pets.where((p) => p.id != id).toList();
    if (_pets.length != before) _notify();
  }

  /// ADMIN ONLY: approve or reject a pet post.
  /// Approved = shows on the Adopt board and the poster is notified.
  /// Rejected = a [reason] is REQUIRED and the poster is notified with it.
  static Future<void> setPostStatus(
      String id,
      PostStatus status, {
        String? reason,
      }) async {
    if (!AuthService.isCurrentAdmin) {
      throw StateError('Only an admin can approve or reject posts.');
    }
    if (status == PostStatus.pending) {
      throw StateError('A post can only be approved or rejected.');
    }
    if (status == PostStatus.rejected && (reason?.trim().isEmpty ?? true)) {
      throw StateError('Please give a reason for rejecting this post.');
    }

    try {
      await _db.rpc('admin_review_post', params: {
        'p_id': id,
        'p_approve': status == PostStatus.approved,
        'p_reason': reason?.trim(),
      });
    } catch (e) {
      throw StateError(friendlyDbError(e,
          fallback: 'Could not update the post. Please try again.'));
    }
    await load();
  }

  // ---------------------------------------------------------------- Helpers

  static String _sourceValue(PetSource s) =>
      s == PetSource.rehoming ? 'rehoming' : 'rescued_stray';

  /// "Barangay, City, Province" -> [barangay, city]
  static List<String> _splitLocation(String location) {
    final List<String> parts = location.split(', ');
    return [
      parts.isNotEmpty ? parts[0].trim() : '',
      parts.length > 1 ? parts[1].trim() : '',
    ];
  }

  /// Existing photo links are kept; picked photos are uploaded to
  /// pet-photos/<user id>/... Returns the storage paths to save.
  static Future<List<String>> _storePhotos(
      List<String> photos,
      String userId,
      List<String> uploaded,
      ) async {
    final List<String> paths = [];
    int n = 0;
    for (final String p in photos) {
      if (p.startsWith('http')) {
        final String? existing = _pathFromUrl(p);
        if (existing != null) paths.add(existing);
        continue;
      }
      final bytes = await XFile(p).readAsBytes();
      if (bytes.length > _maxPhotoBytes) {
        throw StateError(
            'A photo is too large. Please choose photos under 5 MB each.');
      }
      final String ext = _extensionOf(p);
      final String path =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_${n++}.$ext';
      await _db.storage.from(_bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: _mimeOf(ext)),
      );
      uploaded.add(path);
      paths.add(path);
    }
    return paths;
  }

  static Future<void> _removeFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _db.storage.from(_bucket).remove(paths);
    } catch (_) {}
  }

  /// The storage path inside the bucket, taken from a photo web link.
  static String? _pathFromUrl(String url) {
    if (!url.startsWith('http')) return null;
    final String marker = '/$_bucket/';
    final int i = url.indexOf(marker);
    if (i == -1) return null;
    final String rest = url.substring(i + marker.length);
    final int q = rest.indexOf('?');
    return q == -1 ? rest : rest.substring(0, q);
  }

  static String _extensionOf(String path) {
    final int dot = path.lastIndexOf('.');
    final String ext = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
    return const ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext)
        ? ext
        : 'jpg';
  }

  static String _mimeOf(String ext) => switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    _ => 'image/jpeg',
  };
}
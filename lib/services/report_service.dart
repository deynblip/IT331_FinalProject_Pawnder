import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/stray_report.dart';
import 'auth_service.dart';
import 'db_errors.dart';

// Report a Stray still uses `Urgency` through this file.
export '../models/stray_report.dart' show Urgency;

// ===============================
// STRAY REPORTS (Supabase)
// ===============================.

/// An error with a message that can be shown to the user as-is.
class ReportFailure implements Exception {
  final String message;
  const ReportFailure(this.message);

  @override
  String toString() => message;
}

class ReportService {
  static SupabaseClient get _db => Supabase.instance.client;

  static const String _bucket = 'report-photos';

  /// Most photos one report can have (the database allows up to 5).
  static const int maxPhotos = 3;

  static List<StrayReport> _reports = [];
  static bool _loaded = false;
  static Future<void>? _loading;
  static int _generation = 0; // goes up on reset(), so old loads are ignored

  /// Message to show when the last load failed (null = no error).
  static String? loadError;

  /// The phone's last known location (null = unknown or not allowed).
  static double? myLat;
  static double? myLng;

  /// Why the location is not available. Null = it works (or not tried yet).
  /// 'ask' = the app has not asked for permission yet (shows a
  /// "Use location" button first), 'denied' = the user said no,
  /// 'forever' = "Don't ask again", 'off' = the phone's location is off.
  static String? locationProblem;

  /// Goes up by one whenever the list changes.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static void _notify() => changes.value++;

  /// Forgets all cached reports (called on log out / before log in).
  static void reset() {
    _generation++;
    _reports = [];
    _myResponses = {};
    _loaded = false;
    _loading = null;
    loadError = null;
    _notify();
  }

  // ---------------------------------------------------------------- Reading

  /// All reports, newest first.
  static List<StrayReport> get all => List.unmodifiable(_reports);

  /// Reports made by the logged-in user.
  static List<StrayReport> get mine =>
      _reports.where((r) => r.isMine).toList();

  static bool get isLoaded => _loaded;

  // ---------------------------------------------------------------- My responses

  /// Report id -> my latest response there ('active', 'finished' or
  /// 'cancelled'), for every report I responded to ("I'm on my way!").
  /// Newest first.
  static Map<String, String> _myResponses = {};

  /// My response on a report, or null if I never responded there.
  static String? myResponseState(String reportId) => _myResponses[reportId];

  /// Reports I responded to (not my own reports). Active ones first, then
  /// the newest.
  static List<StrayReport> get respondedByMe {
    final List<StrayReport> list = [];
    for (final String id in _myResponses.keys) {
      for (final StrayReport r in _reports) {
        if (r.id == id && !r.isMine) list.add(r);
      }
    }
    final List<StrayReport> active =
    list.where((r) => _myResponses[r.id] == 'active').toList();
    final List<StrayReport> past =
    list.where((r) => _myResponses[r.id] != 'active').toList();
    return [...active, ...past];
  }

  /// Loads the reports I responded to. Safe to call often.
  static Future<void> loadMyResponses() async {
    final String? uid = AuthService.currentUserId;
    if (uid == null) return;
    final int gen = _generation;
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('rescue_responses')
          .select('report_id, state, joined_at')
          .eq('responder_id', uid)
          .order('joined_at', ascending: false);
      if (gen != _generation) return; // account changed while loading

      // Newest response per report; an active one always wins.
      final Map<String, String> map = {};
      for (final row in rows) {
        final String id = row['report_id'] as String;
        final String state = (row['state'] as String?) ?? 'finished';
        if (!map.containsKey(id) || state == 'active') map[id] = state;
      }
      _myResponses = map;
      _notify();
    } catch (e) {
      debugPrint('Load my responses error: $e');
    }
  }
  static bool get isLoading => _loading != null;

  static StrayReport? byId(String id) {
    for (final r in _reports) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Loads the reports once (does nothing if they are already loaded).
  static Future<void> ensureLoaded() =>
      _loaded ? Future.value() : load();

  /// Loads all reports from the database, then the phone's location for
  /// the distances. Safe to call many times at once.
  static Future<void> load() {
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  static Future<void> _load() async {
    final int gen = _generation;
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('stray_reports')
          .select()
          .isFilter('removed_at', null)
          .order('created_at', ascending: false)
          .limit(500);

      final Map<String, int> counts = await _activeResponderCounts();
      if (gen != _generation) return; // account changed while loading

      _reports = rows
          .map((row) => _fromRow(row, counts[row['id']] ?? 0))
          .toList();
      _loaded = true;
      loadError = null;
    } catch (e) {
      loadError = friendlyDbError(e,
          fallback: 'Could not load the reports. Pull down to try again.');
    }
    _notify();

    // Distances: the list is shown first, then updated once GPS answers.
    unawaited(refreshLocation());
  }

  /// Reloads one report (after someone responds, checks in, etc.) and
  /// returns it. Returns null if it was removed.
  static Future<StrayReport?> refreshOne(String id) async {
    final Map<String, dynamic>? row = await _db
        .from('stray_reports')
        .select()
        .eq('id', id)
        .isFilter('removed_at', null)
        .maybeSingle();

    if (row == null) {
      _reports.removeWhere((r) => r.id == id);
      _notify();
      return null;
    }

    final List<Map<String, dynamic>> active = await _db
        .from('rescue_responses')
        .select('id')
        .eq('report_id', id)
        .eq('state', 'active');

    final StrayReport report = _fromRow(row, active.length);
    final int i = _reports.indexWhere((r) => r.id == id);
    if (i == -1) {
      _reports.insert(0, report);
    } else {
      _reports[i] = report;
    }
    _notify();
    return report;
  }

  /// Number of active responders per report id.
  static Future<Map<String, int>> _activeResponderCounts() async {
    final List<Map<String, dynamic>> rows = await _db
        .from('rescue_responses')
        .select('report_id')
        .eq('state', 'active');

    final Map<String, int> counts = {};
    for (final row in rows) {
      final String id = row['report_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  static StrayReport _fromRow(Map<String, dynamic> row, int responders) {
    final List<dynamic> paths = (row['photo_paths'] as List<dynamic>?) ?? [];
    final List<String> photoUrls = paths
        .map((p) => _db.storage.from(_bucket).getPublicUrl(p as String))
        .toList();

    return StrayReport.fromRow(
      row,
      currentUserId: AuthService.currentUserId,
      photoUrls: photoUrls,
      responders: responders,
      distanceKm: _distanceKm(
        (row['latitude'] as num).toDouble(),
        (row['longitude'] as num).toDouble(),
      ),
    );
  }

  // ---------------------------------------------------------------- Location

  static double? _distanceKm(double lat, double lng) {
    if (myLat == null || myLng == null) return null;
    return Geolocator.distanceBetween(myLat!, myLng!, lat, lng) / 1000;
  }

  /// Gets the phone's location and updates every report's distance.
  ///
  /// The permission pop-up is NEVER shown by itself. When the app has not
  /// asked yet, [locationProblem] becomes 'ask' and the screens show a
  /// "Use location" button. The pop-up appears only after the user taps it
  /// ([userTapped] = true).
  static Future<void> refreshLocation({bool userTapped = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        locationProblem = 'off';
        _notify();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!userTapped) {
          locationProblem = 'ask';
          _notify();
          return;
        }
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        locationProblem = 'forever';
        _notify();
        return;
      }
      if (permission == LocationPermission.denied) {
        locationProblem = 'denied';
        _notify();
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      myLat = pos.latitude;
      myLng = pos.longitude;
      locationProblem = null;

      _reports = _reports
          .map((r) => r.copyWith(distanceKm: _distanceKm(r.lat, r.lng)))
          .toList();
      _notify();
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  static Future<void> fixLocation() async {
    if (locationProblem == 'forever') {
      await Geolocator.openAppSettings();
      return;
    }
    if (await Geolocator.checkPermission() == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }
    await refreshLocation(userTapped: true);
  }

  // ---------------------------------------------------------------- Report a Stray

  static Future<void> submit({
    required String animalType,
    required Urgency urgency,
    required String description,
    List<File> photos = const [],
    required double latitude,
    required double longitude,
    required String address,
    bool possiblyLostPet = false,
    required String contactName,
    required String contactPhone,
    required String contactEmail,
  }) async {
    final String? userId = AuthService.currentUserId;
    if (userId == null) throw const ReportFailure('Please log in first.');

    String cleanAddress = address.trim();
    if (cleanAddress.isEmpty || cleanAddress == 'Finding address...') {
      cleanAddress =
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    }

    if (photos.length > maxPhotos) {
      throw const ReportFailure('You can add up to $maxPhotos photos.');
    }

    final List<String> uploaded = [];
    await _uploadPhotos(photos, userId, uploaded);

    try {
      await _db.rpc('create_stray_report', params: {
        'p_animal_type': animalType,
        'p_urgency': urgency.dbValue,
        'p_description': description.trim(),
        'p_photo_paths': uploaded,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_address': cleanAddress.length > 300
            ? cleanAddress.substring(0, 300)
            : cleanAddress,
        'p_possibly_lost_pet': possiblyLostPet,
        'p_contact_name': contactName.trim(),
        'p_contact_phone': contactPhone.trim(),
        'p_contact_email': contactEmail.trim(),
      });
    } catch (e) {
      // Don't leave unused photos in Storage.
      await _removeFromStorage(uploaded);
      throw ReportFailure(friendlyDbError(e,
          fallback: 'Could not submit the report. Please try again.'));
    }

    if (_loading != null) await _loading;
    await load();
  }
// ---------------------------------------------------------------- Edit / Remove my report

  static bool canChange(StrayReport r) =>
      r.isMine &&
          r.status == RescueStatus.needsRescue &&
          r.responders == 0;

  static String? lockedNote(StrayReport r) {
    if (!r.isMine || r.status == RescueStatus.rescued) return null;
    if (canChange(r)) return null;
    return "Someone is responding, so you can't edit or remove this "
        'report right now.';
  }

  static Future<void> updateMine({
    required StrayReport report,
    required String animalType,
    required Urgency urgency,
    required String description,
    required bool possiblyLostPet,
    required List<String> keptPhotos,
    List<File> newPhotos = const [],
    required String contactName,
    required String contactPhone,
    required String contactEmail,
  }) async {
    final String? userId = AuthService.currentUserId;
    if (userId == null) throw const ReportFailure('Please log in first.');

    if (keptPhotos.length + newPhotos.length > maxPhotos) {
      throw const ReportFailure('You can add up to $maxPhotos photos.');
    }

    final List<String> oldPaths = report.allPhotos
        .map(_pathFromUrl)
        .whereType<String>()
        .toList();
    final List<String> keptPaths =
    keptPhotos.map(_pathFromUrl).whereType<String>().toList();

    final List<String> uploaded = [];
    await _uploadPhotos(newPhotos, userId, uploaded);

    try {
      await _db.rpc('update_my_report', params: {
        'p_id': report.id,
        'p_animal_type': animalType,
        'p_urgency': urgency.dbValue,
        'p_description': description.trim(),
        'p_photo_paths': [...keptPaths, ...uploaded],
        'p_possibly_lost_pet': possiblyLostPet,
        'p_contact_name': contactName.trim(),
        'p_contact_phone': contactPhone.trim(),
        'p_contact_email': contactEmail.trim(),
      });
    } catch (e) {
      await _removeFromStorage(uploaded);
      unawaited(refreshOne(report.id).catchError((_) => null));
      throw ReportFailure(friendlyDbError(e,
          fallback: 'Could not save your changes. Please try again.'));
    }

    await _removeFromStorage(
        oldPaths.where((p) => !keptPaths.contains(p)).toList());

    await refreshOne(report.id);
  }

  static Future<void> _uploadPhotos(
      List<File> files, String userId, List<String> uploaded) async {
    final int stamp = DateTime.now().millisecondsSinceEpoch;
    try {
      for (int i = 0; i < files.length; i++) {
        final Uint8List bytes = await files[i].readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          throw const ReportFailure(
              'A photo is too large. Please choose photos under 5 MB each.');
        }
        final String ext = _extensionOf(files[i].path);
        final String path = '$userId/${stamp}_$i.$ext';
        await _db.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mimeOf(ext)),
        );
        uploaded.add(path);
      }
    } on ReportFailure {
      await _removeFromStorage(uploaded);
      uploaded.clear();
      rethrow;
    } catch (e) {
      await _removeFromStorage(uploaded);
      uploaded.clear();
      throw ReportFailure(friendlyDbError(e,
          fallback: 'Could not upload the photos. Please try again.'));
    }
  }

  static Future<void> _removeFromStorage(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _db.storage.from(_bucket).remove(paths);
    } catch (_) {}
  }

  static Future<void> removeMine(String reportId) async {
    try {
      await _db.rpc('remove_my_report', params: {'p_id': reportId});
    } catch (e) {
      unawaited(refreshOne(reportId).catchError((_) => null));
      throw ReportFailure(friendlyDbError(e,
          fallback: 'Could not remove the report. Please try again.'));
    }
    _reports.removeWhere((r) => r.id == reportId);
    _notify();
  }

  static String? _pathFromUrl(String? url) {
    if (url == null || !url.startsWith('http')) return null;
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
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/rescuer_application.dart';
import 'auth_service.dart';
import 'db_errors.dart';
import 'response_service.dart';

// ======================================
// VERIFIED RESCUERS (Supabase)
// ======================================
// Rescuer applications live in the table `rescuer_applications` (also the
// one made at Sign Up). A regular user can only see their own; an ADMIN sees
// all of them. Approve, reject and remove badge are database functions, and
// the DATABASE sends the notifications (including the high cancel rate flag).
// Listen to [changes] to refresh a screen.

/// An error with a message that can be shown to the user as-is.
class RescuerFailure implements Exception {
  final String message;
  const RescuerFailure(this.message);

  @override
  String toString() => message;
}

class RescuerService {
  static SupabaseClient get _db => Supabase.instance.client;

  static List<RescuerApplication> _apps = [];

  // Track records by user id (loaded for admins only).
  static Map<String, ResponderStats> _stats = {};

  static Future<void>? _loading;
  static int _generation = 0;

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static void _notify() => changes.value++;

  static String _k(String email) => email.trim().toLowerCase();

  // ---------------------------------------------------------- Loading

  static Future<void> load() {
    final Future<void>? running = _loading;
    if (running != null) return running;
    final Future<void> f = _fetch().whenComplete(() => _loading = null);
    _loading = f;
    return f;
  }

  /// Loads again even if a load is already running (used right after the
  /// user or admin changes something).
  static Future<void> refresh() async {
    final Future<void>? running = _loading;
    if (running != null) await running;
    await load();
  }

  /// Profile calls this: loads the logged-in user's own application(s).
  static Future<void> loadMine() => load();

  static Future<void> _fetch() async {
    final int gen = _generation;
    if (AuthService.currentUserId == null) return;

    try {
      final rows = await _db
          .from('rescuer_applications')
          .select()
          .order('submitted_at', ascending: false);

      final List<RescuerApplication> apps = [
        for (final dynamic r in rows)
          _fromRow(Map<String, dynamic>.from(r as Map)),
      ];

      // Track records are only needed by the admin Rescuers screen.
      final Map<String, ResponderStats> stats = {};
      if (AuthService.isCurrentAdmin) {
        final List<String> ids = {
          for (final a in apps)
            if (a.userId.isNotEmpty) a.userId,
        }.toList();
        if (ids.isNotEmpty) {
          final dynamic statRows =
          await _db.rpc('responder_stats', params: {'p_user_ids': ids});
          for (final dynamic row in statRows as List<dynamic>) {
            final Map<String, dynamic> map = row as Map<String, dynamic>;
            stats[map['user_id'] as String] = ResponderStats.fromRow(map);
          }
        }
      }

      if (gen != _generation) return; // logged out while loading
      _apps = apps;
      _stats = stats;
      _notify();
    } catch (e) {
      debugPrint('Load rescuer applications error: $e');
    }
  }

  /// Forget everything (log out / switch account).
  static void reset() {
    _generation++;
    _apps = [];
    _stats = {};
    _loading = null;
    _notify();
  }

  static RescuerApplication _fromRow(Map<String, dynamic> r) {
    return RescuerApplication(
      id: r['id'] as String,
      userId: (r['user_id'] as String?) ?? '',
      email: _k((r['applicant_email'] as String?) ?? ''),
      applicantName: (r['applicant_name'] as String?) ?? '',
      organization: (r['organization'] as String?) ?? '',
      roleInOrg: (r['role_in_org'] as String?) ?? '',
      contactPerson: (r['contact_person'] as String?) ?? '',
      contactNumber: (r['contact_number'] as String?) ?? '',
      officialPage: (r['official_page'] as String?) ?? '',
      submittedAt: DateTime.parse(r['submitted_at'] as String).toLocal(),
      status: switch (r['status']) {
        'verified' => RescuerStatus.verified,
        'rejected' => RescuerStatus.rejected,
        _ => RescuerStatus.pending,
      },
      rejectionReason: r['rejection_reason'] as String?,
      reviewedAt: r['reviewed_at'] == null
          ? null
          : DateTime.parse(r['reviewed_at'] as String).toLocal(),
    );
  }

  // ---------------------------------------------------------- Lookups

  /// The newest application of this user (null if never applied).
  static RescuerApplication? latestFor(String? email) {
    if (email == null) return null;
    final key = _k(email);
    RescuerApplication? latest;
    for (final a in _apps) {
      if (a.email != key) continue;
      if (latest == null || a.submittedAt.isAfter(latest.submittedAt)) {
        latest = a;
      }
    }
    return latest;
  }

  static RescuerStatus statusOf(String? email) =>
      latestFor(email)?.status ?? RescuerStatus.none;

  static bool isVerified(String? email) =>
      statusOf(email) == RescuerStatus.verified;

  /// Organization name, only when the user is a Verified Rescuer.
  static String? organizationOf(String? email) =>
      isVerified(email) ? latestFor(email)?.organization : null;

  // Shortcuts for the logged-in user
  static RescuerApplication? get currentApplication =>
      latestFor(AuthService.currentEmail);
  static RescuerStatus get currentStatus =>
      statusOf(AuthService.currentEmail);
  static bool get isCurrentVerified => isVerified(AuthService.currentEmail);
  static String? get currentOrganization =>
      organizationOf(AuthService.currentEmail);

  static bool canApply(String? email) {
    final s = statusOf(email);
    return s == RescuerStatus.none || s == RescuerStatus.rejected;
  }

  // ---------------------------------------------------------- Admin lists

  static List<RescuerApplication> byStatus(RescuerStatus status) {
    final list = _apps.where((a) => a.status == status).toList();
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  static int get pendingCount =>
      _apps.where((a) => a.status == RescuerStatus.pending).length;

  /// Track record of an applicant (from the database; empty until loaded).
  static ResponderStats statsFor(String email) {
    final RescuerApplication? app = latestFor(email);
    if (app == null) return ResponderStats.empty;
    return _stats[app.userId] ?? ResponderStats.empty;
  }

  /// Verified Rescuers whose cancel rate is high (shown to the admin).
  static bool isFlagged(String email) =>
      isVerified(email) && statsFor(email).hasHighCancelRate;

  static int get flaggedCount => _apps
      .where((a) => a.status == RescuerStatus.verified && isFlagged(a.email))
      .length;

  // ---------------------------------------------------------- Apply

  /// Profile > Apply as Verified Rescuer: saves the application in the
  /// database. Returns an error message, or null when it was sent.
  static Future<String?> submitToDatabase({
    required String organization,
    required String roleInOrg,
    required String contactPerson,
    required String contactNumber,
    required String officialPage,
  }) async {
    try {
      await _db.rpc('submit_rescuer_application', params: {
        'p_organization': organization.trim(),
        'p_role_in_org': roleInOrg.trim(),
        'p_contact_person': contactPerson.trim(),
        'p_contact_number': contactNumber.trim(),
        'p_official_page': officialPage.trim(),
      });
    } catch (e) {
      return friendlyDbError(e,
          fallback: 'Could not send your application. Please try again.');
    }
    await refresh();
    return null;
  }

  // ---------------------------------------------------------- Admin review

  static Future<void> _review(
      String function,
      Map<String, dynamic> params,
      String fallback,
      ) async {
    if (!AuthService.isCurrentAdmin) {
      throw const RescuerFailure(
          'Only an admin can review rescuer applications.');
    }
    try {
      await _db.rpc(function, params: params);
    } catch (e) {
      // The list may be out of date (someone else already reviewed it).
      unawaited(refresh());
      throw RescuerFailure(friendlyDbError(e, fallback: fallback));
    }
    await refresh();
  }

  static Future<void> approve(String id) => _review(
    'admin_review_rescuer',
    {'p_id': id, 'p_approve': true},
    'Could not approve this application. Please try again.',
  );

  static Future<void> reject(String id, String reason) => _review(
    'admin_review_rescuer',
    {'p_id': id, 'p_approve': false, 'p_reason': reason.trim()},
    'Could not reject this application. Please try again.',
  );

  /// Removes the Verified Rescuer badge (for example, high cancel rate).
  /// The user goes back to being a regular user and can apply again.
  static Future<void> revoke(String id, String reason) => _review(
    'admin_revoke_rescuer',
    {'p_id': id, 'p_reason': reason.trim()},
    'Could not remove the badge. Please try again.',
  );
}
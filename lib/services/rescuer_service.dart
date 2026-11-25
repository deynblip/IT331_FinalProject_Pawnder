// ===================================
// TEMPORARY IN-MEMORY RESCUER STORE
// ===================================
// Holds Verified Rescuer applications. Resets when the app restarts.
// Replace with your real backend later.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import '../models/rescuer_application.dart';
import 'auth_service.dart';
import 'db_errors.dart';
import 'notification_service.dart';
import 'response_service.dart';

class RescuerService {
  // One sample pending application so the admin screen is not empty.
  static final List<RescuerApplication> _apps = [
    RescuerApplication(
      id: 'seed1',
      email: 'maria.santos@example.com',
      applicantName: 'Maria Santos',
      organization: 'Batangas Animal Rescue Network',
      roleInOrg: 'Volunteer Coordinator',
      contactPerson: 'Ramon Dela Cruz',
      contactNumber: '0917 123 4567',
      officialPage: 'https://facebook.com/BatangasAnimalRescue',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static void _notify() => changes.value++;

  static String _k(String email) => email.trim().toLowerCase();

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

  /// Verified Rescuers whose cancel rate is high (shown to the admin).
  static bool isFlagged(String email) =>
      isVerified(email) && ResponseService.statsFor(email).hasHighCancelRate;

  static int get flaggedCount => _apps
      .where((a) => a.status == RescuerStatus.verified && isFlagged(a.email))
      .length;

  // Emails the admin was already told about (so it is only sent once).
  static final Set<String> _flagNotified = {};

  /// Called after a responder cancels. Notifies the admin once when a
  /// Verified Rescuer's cancel rate becomes high.
  static void checkCancelRate(String email) {
    final key = _k(email);
    if (!isFlagged(key)) {
      _flagNotified.remove(key);
      return;
    }
    if (!_flagNotified.add(key)) return;
    final stats = ResponseService.statsFor(key);
    NotificationService.add(
      type: NotificationType.rescuerFlagged,
      title: 'Verified Rescuer flagged',
      message: '${AuthService.nameOf(key) ?? key} '
          '(${organizationOf(key) ?? '-'}) has cancelled '
          '${stats.cancelled} of ${stats.responses} responses '
          '(${stats.cancelRateText}). Review their badge in Rescuers.',
      userEmail: AuthService.adminEmail,
    );
    _notify();
  }

  // ---------------------------------------------------------- Database

  /// Loads the logged-in user's newest application from the database
  /// (including the one made at Sign Up), so Profile shows the real status
  /// (Pending / Verified / Not approved) even after the app was restarted.
  static Future<void> loadMine() async {
    final String? me = AuthService.currentUserId;
    final String? email = AuthService.currentEmail;
    if (me == null || email == null) return;

    try {
      final List<Map<String, dynamic>> rows = await Supabase.instance.client
          .from('rescuer_applications')
          .select()
          .eq('user_id', me)
          .order('submitted_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return;
      if (me != AuthService.currentUserId) return; // another account logged in

      final Map<String, dynamic> r = rows.first;
      final RescuerApplication app = RescuerApplication(
        id: r['id'] as String,
        email: email,
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

      // The database is the truth: replace this user's older in-memory copy.
      _apps.removeWhere((a) => a.email == email && !a.id.startsWith('seed'));
      _apps.insert(0, app);
      _notify();
    } catch (e) {
      debugPrint('Load my rescuer application error: $e');
    }
  }

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
      await Supabase.instance.client.rpc('submit_rescuer_application', params: {
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
    await loadMine();
    return null;
  }

  // ---------------------------------------------------------- Apply

  /// Used by Sign Up and by Profile > Apply as Verified Rescuer.
  /// Returns an error message, or null when the application was sent.
  /// The status is PENDING. No permissions are given until the admin approves.
  static String? submit({
    required String email,
    required String applicantName,
    required String organization,
    required String roleInOrg,
    required String contactPerson,
    required String contactNumber,
    required String officialPage,
  }) {
    final status = statusOf(email);
    if (status == RescuerStatus.pending) {
      return 'You already have an application waiting for review.';
    }
    if (status == RescuerStatus.verified) {
      return 'You are already a Verified Rescuer.';
    }

    _apps.insert(
      0,
      RescuerApplication(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        email: _k(email),
        applicantName: applicantName.trim(),
        organization: organization.trim(),
        roleInOrg: roleInOrg.trim(),
        contactPerson: contactPerson.trim(),
        contactNumber: contactNumber.trim(),
        officialPage: officialPage.trim(),
        submittedAt: DateTime.now(),
      ),
    );
    _notify();
    return null;
  }

  // ---------------------------------------------------------- Admin review

  static void _requireAdmin() {
    if (!AuthService.isCurrentAdmin) {
      throw StateError('Only an admin can review rescuer applications.');
    }
  }

  static Future<void> approve(String id) async {
    _requireAdmin();
    await Future.delayed(const Duration(milliseconds: 250));

    final i = _apps.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Application not found.');
    if (_apps[i].status != RescuerStatus.pending) {
      throw StateError('This application was already reviewed.');
    }

    _apps[i] = _apps[i].copyWith(
      status: RescuerStatus.verified,
      reviewedAt: DateTime.now(),
    );
    NotificationService.add(
      type: NotificationType.rescuerApproved,
      title: 'You are now a Verified Rescuer',
      message: 'Your application for ${_apps[i].organization} was approved. '
          'Your Verified Rescuer badge and permissions are now active.',
      userEmail: _apps[i].email,
    );
    _notify();
  }

  /// Removes the Verified Rescuer badge (for example, high cancel rate).
  /// The user goes back to being a regular user and can apply again.
  static Future<void> revoke(String id, String reason) async {
    _requireAdmin();
    await Future.delayed(const Duration(milliseconds: 250));

    final i = _apps.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Application not found.');
    if (_apps[i].status != RescuerStatus.verified) {
      throw StateError('This user is not a Verified Rescuer.');
    }

    _apps[i] = _apps[i].copyWith(
      status: RescuerStatus.rejected,
      rejectionReason: 'Badge removed: ${reason.trim()}',
      reviewedAt: DateTime.now(),
    );
    _flagNotified.remove(_apps[i].email);
    NotificationService.add(
      type: NotificationType.rescuerRejected,
      title: 'Verified Rescuer badge removed',
      message: 'An admin removed your Verified Rescuer badge. Reason: '
          '${reason.trim()} You can apply again from your Profile.',
      userEmail: _apps[i].email,
    );
    _notify();
  }

  static Future<void> reject(String id, String reason) async {
    _requireAdmin();
    await Future.delayed(const Duration(milliseconds: 250));

    final i = _apps.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Application not found.');
    if (_apps[i].status != RescuerStatus.pending) {
      throw StateError('This application was already reviewed.');
    }

    _apps[i] = _apps[i].copyWith(
      status: RescuerStatus.rejected,
      rejectionReason: reason.trim(),
      reviewedAt: DateTime.now(),
    );
    NotificationService.add(
      type: NotificationType.rescuerRejected,
      title: 'Rescuer application not approved',
      message: 'Your application was not approved. Reason: '
          '${reason.trim()} You can apply again from your Profile.',
      userEmail: _apps[i].email,
    );
    _notify();
  }
}
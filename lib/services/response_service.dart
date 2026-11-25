import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/stray_report.dart';
import 'auth_service.dart';
import 'db_errors.dart';
import 'report_service.dart';

// ======================================
// RESCUE RESPONSES (Supabase)
// ======================================
// "I'm on my way!", "I've arrived", "Cancel", "Take over" and
// "Mark as Rescued". Each button calls a database function, and the
// DATABASE checks the rules (one report at a time, within 200 m, only
// Verified Rescuers can take over, etc.). The app only shows the result.
//
// The table `rescue_responses` is also everyone's track record
// (completed rescues, cancellations). Trust level is calculated here from
// those numbers; it is not saved anywhere.

enum ResponderRole { lead, assisting }

enum RescueOutcome {
  rescuedOnSite('rescued_on_site'),
  broughtToVetShelter('brought_to_vet_shelter'),
  unableToLocate('unable_to_locate');

  const RescueOutcome(this.dbValue);
  final String dbValue;

  static RescueOutcome? fromDb(String? value) {
    for (final o in RescueOutcome.values) {
      if (o.dbValue == value) return o;
    }
    return null;
  }

  String get label => switch (this) {
    RescueOutcome.rescuedOnSite => 'Rescued on site',
    RescueOutcome.broughtToVetShelter => 'Brought to vet / shelter',
    RescueOutcome.unableToLocate => 'Unable to locate',
  };

  bool get isSuccess => this != RescueOutcome.unableToLocate;
}

/// Someone who is currently responding to a report.
class ReportResponder {
  final String userId;
  final String name;
  final String? organization; // set = Verified Rescuer when they responded
  final ResponderRole role;
  final bool checkedIn;
  final DateTime joinedAt;
  final DateTime lastUpdate;

  const ReportResponder({
    required this.userId,
    required this.name,
    this.organization,
    required this.role,
    this.checkedIn = false,
    required this.joinedAt,
    required this.lastUpdate,
  });

  factory ReportResponder.fromRow(Map<String, dynamic> row) {
    final Map<String, dynamic>? profile =
    row['responder'] as Map<String, dynamic>?;
    return ReportResponder(
      userId: row['responder_id'] as String,
      name: (profile?['full_name'] as String?) ?? 'Pawnder User',
      organization: row['organization'] as String?,
      role: row['role'] == 'lead' ? ResponderRole.lead : ResponderRole.assisting,
      checkedIn: row['checked_in_at'] != null,
      joinedAt: DateTime.parse(row['joined_at'] as String).toLocal(),
      lastUpdate: DateTime.parse(row['last_update_at'] as String).toLocal(),
    );
  }

  bool get isVerified => organization != null;

  bool get isMe => userId == AuthService.currentUserId;
}

/// Trust level for responders, based on their track record.
enum TrustLevel {
  newHelper,
  activeHelper,
  trustedHelper;

  String get label => switch (this) {
    TrustLevel.newHelper => 'New Helper',
    TrustLevel.activeHelper => 'Active Helper',
    TrustLevel.trustedHelper => 'Trusted Helper',
  };
}

class ResponderStats {
  final int responses;
  final int rescues; // completed rescues (checked in + rescued)
  final int cancelled;
  final int unableToLocate;
  final int checkIns;

  const ResponderStats({
    required this.responses,
    required this.rescues,
    required this.cancelled,
    required this.unableToLocate,
    required this.checkIns,
  });

  static const ResponderStats empty = ResponderStats(
    responses: 0,
    rescues: 0,
    cancelled: 0,
    unableToLocate: 0,
    checkIns: 0,
  );

  /// From one row of the database function `responder_stats`.
  factory ResponderStats.fromRow(Map<String, dynamic> row) {
    int n(String key) => (row[key] as num?)?.toInt() ?? 0;
    return ResponderStats(
      responses: n('responses'),
      rescues: n('rescues'),
      cancelled: n('cancelled'),
      unableToLocate: n('unable_to_locate'),
      checkIns: n('check_ins'),
    );
  }

  // Example thresholds (README: to be finalized by the team).
  static const int activeHelperRescues = 3;
  static const int trustedHelperRescues = 10;
  static const double maxTrustedCancelRate = 0.30;

  /// A Verified Rescuer with at least this many responses and a cancel
  /// rate at or above [maxTrustedCancelRate] is flagged for the admin.
  static const int minResponsesForFlag = 3;

  double get cancelRate => responses == 0 ? 0 : cancelled / responses;

  String get checkInRate =>
      responses == 0 ? '-' : '${(checkIns * 100 / responses).round()}%';

  String get completionRate =>
      responses == 0 ? '-' : '${(rescues * 100 / responses).round()}%';

  String get cancelRateText =>
      responses == 0 ? '-' : '${(cancelRate * 100).round()}%';

  TrustLevel get trustLevel {
    if (rescues >= trustedHelperRescues && cancelRate < maxTrustedCancelRate) {
      return TrustLevel.trustedHelper;
    }
    if (rescues >= activeHelperRescues) return TrustLevel.activeHelper;
    return TrustLevel.newHelper;
  }

  bool get hasHighCancelRate =>
      responses >= minResponsesForFlag && cancelRate >= maxTrustedCancelRate;
}

/// How a rescued report ended.
class RescueClosure {
  final RescueOutcome outcome;
  final String? organization; // set when a Verified Rescuer closed it
  const RescueClosure(this.outcome, this.organization);
}

/// Everything the Report Details screen needs about the rescue.
class RescueDetails {
  final StrayReport report;
  final List<ReportResponder> responders; // lead first
  final Map<String, ResponderStats> stats; // by user id
  final RescueClosure? closure; // only when rescued

  const RescueDetails({
    required this.report,
    required this.responders,
    required this.stats,
    this.closure,
  });

  /// The logged-in user's response on this report (null = not responding).
  ReportResponder? get mine {
    for (final r in responders) {
      if (r.isMe) return r;
    }
    return null;
  }

  ResponderStats statsOf(String userId) =>
      stats[userId] ?? ResponderStats.empty;

  /// In progress, but nobody has posted an update for 24 hours.
  bool get isInactive {
    if (report.status != RescueStatus.inProgress) return false;
    if (responders.isEmpty) return true;
    final DateTime latest = responders
        .map((r) => r.lastUpdate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime.now().difference(latest) > ResponseService.inactiveAfter;
  }
}

class ActionResult {
  final String? error;

  const ActionResult.ok() : error = null;
  const ActionResult.fail(this.error);

  bool get ok => error == null;
}

class ResponseService {
  static SupabaseClient get _db => Supabase.instance.client;

  /// A report with no update for this long can be taken over by a rescuer.
  static const Duration inactiveAfter = Duration(hours: 24);

  /// How close (in meters) the phone must be to the report's pin for
  /// "I've arrived" and "Mark as Rescued". (The database checks this too.)
  static const double checkInRadiusMeters = 200;

  /// Goes up by one when the logged-in user's record or status changes.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static void _notify() => changes.value++;

  /// Forgets the logged-in user's cached status and record.
  static void reset() {
    _myOrganization = null;
    _myStats = ResponderStats.empty;
    _notify();
  }

  // ---------------------------------------------------------------- Me

  static String? _myOrganization;
  static ResponderStats _myStats = ResponderStats.empty;

  /// Organization name if the logged-in user is a Verified Rescuer
  /// (from the database), otherwise null.
  static String? get myOrganization => _myOrganization;

  static bool get isCurrentVerified => _myOrganization != null;

  /// The logged-in user's Rescue Record (from the database).
  static ResponderStats get myStats => _myStats;

  static Future<void> loadMe() async {
    final String? me = AuthService.currentUserId;
    if (me == null) return;
    try {
      final List<Map<String, dynamic>> apps = await _db
          .from('rescuer_applications')
          .select('organization')
          .eq('user_id', me)
          .eq('status', 'verified')
          .limit(1);
      final Map<String, ResponderStats> stats = await _statsFor([me]);

      // Another account may have logged in while this was loading.
      if (me != AuthService.currentUserId) return;

      _myOrganization =
      apps.isEmpty ? null : apps.first['organization'] as String?;
      _myStats = stats[me] ?? ResponderStats.empty;
      _notify();
    } catch (e) {
      debugPrint('Load my rescue record error: $e');
    }
  }

  static Future<Map<String, ResponderStats>> _statsFor(
      List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final dynamic rows = await _db.rpc(
      'responder_stats',
      params: {'p_user_ids': userIds},
    );
    final Map<String, ResponderStats> result = {};
    for (final dynamic row in rows as List<dynamic>) {
      final Map<String, dynamic> map = row as Map<String, dynamic>;
      result[map['user_id'] as String] = ResponderStats.fromRow(map);
    }
    return result;
  }

  // ---------------------------------------------------------------- Report details

  /// Loads the latest report, its responders (with their track records)
  /// and, if rescued, how it ended. Throws [ReportFailure] (with a message
  /// for the user) if it fails, or if the report was removed.
  static Future<RescueDetails> loadDetails(String reportId) async {
    try {
      final StrayReport? report = await ReportService.refreshOne(reportId);
      if (report == null) throw const _Gone();

      final List<Map<String, dynamic>> rows = await _db
          .from('rescue_responses')
          .select('responder_id, role, organization, checked_in_at, '
          'joined_at, last_update_at, '
          'responder:profiles(full_name)')
          .eq('report_id', reportId)
          .eq('state', 'active');

      final List<ReportResponder> responders =
      rows.map(ReportResponder.fromRow).toList()
      // Lead first, then Verified Rescuers, then the others.
        ..sort((a, b) {
          if (a.role != b.role) return a.role == ResponderRole.lead ? -1 : 1;
          if (a.isVerified != b.isVerified) return a.isVerified ? -1 : 1;
          return a.joinedAt.compareTo(b.joinedAt);
        });

      final Map<String, ResponderStats> stats =
      await _statsFor(responders.map((r) => r.userId).toList());

      RescueClosure? closure;
      final RescueOutcome? outcome = RescueOutcome.fromDb(report.outcome);
      if (report.status == RescueStatus.rescued && outcome != null) {
        String? org;
        if (report.closedBy != null) {
          final List<Map<String, dynamic>> closer = await _db
              .from('rescue_responses')
              .select('organization')
              .eq('report_id', reportId)
              .eq('responder_id', report.closedBy!)
              .eq('outcome', outcome.dbValue)
              .limit(1);
          if (closer.isNotEmpty) org = closer.first['organization'] as String?;
        }
        closure = RescueClosure(outcome, org);
      }

      return RescueDetails(
        report: report,
        responders: responders,
        stats: stats,
        closure: closure,
      );
    } on _Gone {
      throw const ReportFailure('This report is no longer available.');
    } catch (e) {
      throw ReportFailure(friendlyDbError(e,
          fallback: 'Could not load this report. Please try again.'));
    }
  }

  // ---------------------------------------------------------------- Actions

  /// "I'm on my way!"
  static Future<ActionResult> respond(StrayReport report) => _run(
    report,
        () => _db.rpc('respond_to_report', params: {'p_report_id': report.id}),
  );

  /// "I've arrived": sends the phone's GPS. The database checks the 200 m.
  static Future<ActionResult> checkIn(StrayReport report) async {
    final _Gps gps = await _currentPosition();
    if (gps.error != null) return ActionResult.fail(gps.error);
    return _run(
      report,
          () => _db.rpc('check_in', params: {
        'p_report_id': report.id,
        'p_latitude': gps.lat,
        'p_longitude': gps.lng,
      }),
    );
  }

  /// "Cancel / I can't make it". Counts as a cancelled response.
  static Future<ActionResult> withdraw(StrayReport report) => _run(
    report,
        () => _db.rpc('cancel_response', params: {'p_report_id': report.id}),
  );

  /// Verified Rescuers only: take over a report with no recent updates.
  static Future<ActionResult> takeOver(StrayReport report) => _run(
    report,
        () => _db.rpc('take_over_report', params: {'p_report_id': report.id}),
  );

  /// Mark as rescued / choose an outcome. Rescue outcomes need the phone's
  /// GPS (within 200 m). "Unable to locate" does not.
  static Future<ActionResult> finish(
      StrayReport report,
      RescueOutcome outcome,
      ) async {
    double? lat;
    double? lng;
    if (outcome != RescueOutcome.unableToLocate) {
      final _Gps gps = await _currentPosition();
      if (gps.error != null) return ActionResult.fail(gps.error);
      lat = gps.lat;
      lng = gps.lng;
    }
    return _run(
      report,
          () => _db.rpc('finish_rescue', params: {
        'p_report_id': report.id,
        'p_outcome': outcome.dbValue,
        'p_latitude': lat,
        'p_longitude': lng,
      }),
    );
  }

  /// Calls the database, then reloads the report and my record so every
  /// screen shows the new status.
  static Future<ActionResult> _run(
      StrayReport report,
      Future<dynamic> Function() call,
      ) async {
    if (AuthService.currentUserId == null) {
      return const ActionResult.fail('Please log in first.');
    }
    try {
      await call();
    } catch (e) {
      return ActionResult.fail(friendlyDbError(e));
    }
    try {
      await ReportService.refreshOne(report.id);
    } catch (e) {
      debugPrint('Refresh report error: $e');
    }
    unawaited(loadMe());
    return const ActionResult.ok();
  }

  // ---------------------------------------------------------------- GPS

  static Future<_Gps> _currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const _Gps.fail('Please turn on location services.');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const _Gps.fail(
          "Location permission is needed to check in at the animal's location.",
        );
      }
      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return _Gps(pos.latitude, pos.longitude);
    } on TimeoutException {
      return const _Gps.fail(
        'Could not get a GPS fix. Move to an open area and try again.',
      );
    } catch (_) {
      return const _Gps.fail('Could not get your location.');
    }
  }
}

class _Gps {
  final double? lat;
  final double? lng;
  final String? error;

  const _Gps(double this.lat, double this.lng) : error = null;
  const _Gps.fail(this.error)
      : lat = null,
        lng = null;
}

class _Gone implements Exception {
  const _Gone();
}
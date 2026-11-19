// ======================================
// TEMPORARY IN-MEMORY RESPONDER STORE
// ======================================
// Who is responding to which stray report, and each responder's history
// (used as the "track record" the admin checks). Resets on app restart.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/stray_report.dart';
import 'auth_service.dart';
import 'rescuer_service.dart';

enum ResponderRole { lead, assisting }

enum RescueOutcome {
  rescuedOnSite,
  broughtToVetShelter,
  unableToLocate;

  String get label => switch (this) {
    RescueOutcome.rescuedOnSite => 'Rescued on site',
    RescueOutcome.broughtToVetShelter => 'Brought to vet / shelter',
    RescueOutcome.unableToLocate => 'Unable to locate',
  };

  bool get isSuccess => this != RescueOutcome.unableToLocate;
}

class ReportResponder {
  final String email;
  final String name;
  final String? organization; // set = Verified Rescuer when they responded
  final ResponderRole role;
  final bool checkedIn;
  final DateTime joinedAt;
  final DateTime lastUpdate;

  const ReportResponder({
    required this.email,
    required this.name,
    this.organization,
    required this.role,
    this.checkedIn = false,
    required this.joinedAt,
    required this.lastUpdate,
  });

  bool get isVerified => organization != null;

  ReportResponder copyWith({
    ResponderRole? role,
    bool? checkedIn,
    DateTime? lastUpdate,
  }) {
    return ReportResponder(
      email: email,
      name: name,
      organization: organization,
      role: role ?? this.role,
      checkedIn: checkedIn ?? this.checkedIn,
      joinedAt: joinedAt,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class ResponseRecord {
  final String email;
  final String reportId;
  final RescueOutcome? outcome; // null = assisted only
  final bool checkedIn;
  final DateTime date;

  const ResponseRecord({
    required this.email,
    required this.reportId,
    this.outcome,
    required this.checkedIn,
    required this.date,
  });
}

class ResponderStats {
  final int responses;
  final int rescues;
  final int unableToLocate;
  final int checkIns;

  const ResponderStats({
    required this.responses,
    required this.rescues,
    required this.unableToLocate,
    required this.checkIns,
  });

  String get checkInRate =>
      responses == 0 ? '-' : '${(checkIns * 100 / responses).round()}%';
}

class RescueClosure {
  final ReportResponder by;
  final RescueOutcome outcome;
  const RescueClosure(this.by, this.outcome);
}

class ActionResult {
  final String? error;
  final RescueStatus? status; // the report's new status (if it changed)

  const ActionResult.ok([this.status]) : error = null;
  const ActionResult.fail(this.error) : status = null;

  bool get ok => error == null;
}

class ResponseService {
  /// A report with no update for this long can be taken over by a rescuer.
  static const Duration inactiveAfter = Duration(hours: 24);

  /// How close (in meters) a responder's GPS must be to the report's pin
  /// before they can check in with "I've arrived".
  static const double checkInRadiusMeters = 200;

  static DateTime _ago(Duration d) => DateTime.now().subtract(d);

  // Report '2' (Injured Cat) starts with two quiet responders so you can
  // try "Take over" with a Verified Rescuer account.
  static final Map<String, List<ReportResponder>> _active = {
    '2': [
      ReportResponder(
        email: 'seed.juan@pawnder.test',
        name: 'Juan D.',
        role: ResponderRole.assisting,
        joinedAt: _ago(const Duration(days: 3)),
        lastUpdate: _ago(const Duration(days: 3)),
      ),
      ReportResponder(
        email: 'seed.ana@pawnder.test',
        name: 'Ana R.',
        role: ResponderRole.assisting,
        joinedAt: _ago(const Duration(days: 3)),
        lastUpdate: _ago(const Duration(days: 3)),
      ),
    ],
  };

  static final Map<String, RescueClosure> _closed = {};

  // Sample history for the seeded applicant (Maria Santos).
  static final List<ResponseRecord> _history = [
    for (var i = 0; i < 5; i++)
      ResponseRecord(
        email: 'maria.santos@example.com',
        reportId: 'old$i',
        outcome: i == 3
            ? RescueOutcome.broughtToVetShelter
            : RescueOutcome.rescuedOnSite,
        checkedIn: true,
        date: _ago(Duration(days: 10 + i * 5)),
      ),
    ResponseRecord(
      email: 'maria.santos@example.com',
      reportId: 'old5',
      outcome: RescueOutcome.unableToLocate,
      checkedIn: false,
      date: _ago(const Duration(days: 40)),
    ),
  ];

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static void _notify() => changes.value++;

  static String _nameOf(String email) =>
      AuthService.nameOf(email) ?? 'Pawnder User';

  // ---------------------------------------------------------- Reading

  /// Lead first, then Verified Rescuers, then the others.
  static List<ReportResponder> forReport(String reportId) {
    final list = List.of(_active[reportId] ?? const <ReportResponder>[]);
    list.sort((a, b) {
      if (a.role != b.role) return a.role == ResponderRole.lead ? -1 : 1;
      if (a.isVerified != b.isVerified) return a.isVerified ? -1 : 1;
      return a.joinedAt.compareTo(b.joinedAt);
    });
    return list;
  }

  static ReportResponder? mine(String reportId) {
    final email = AuthService.currentEmail;
    if (email == null) return null;
    for (final r in _active[reportId] ?? const <ReportResponder>[]) {
      if (r.email == email) return r;
    }
    return null;
  }

  static int activeCount(String email) => _active.values
      .expand((l) => l)
      .where((r) => r.email == email)
      .length;

  static RescueClosure? closureOf(String reportId) => _closed[reportId];

  /// In progress, but nobody has posted an update for [inactiveAfter].
  static bool isInactive(StrayReport report) {
    if (report.status != RescueStatus.inProgress) return false;
    final list = _active[report.id] ?? const <ReportResponder>[];
    if (list.isEmpty) return true;
    final latest = list
        .map((r) => r.lastUpdate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime.now().difference(latest) > inactiveAfter;
  }

  /// Track record the admin checks when reviewing a rescuer application.
  static ResponderStats statsFor(String email) {
    final key = email.trim().toLowerCase();
    final mine = _history.where((r) => r.email == key).toList();
    return ResponderStats(
      responses: mine.length,
      rescues: mine.where((r) => r.outcome?.isSuccess ?? false).length,
      unableToLocate: mine
          .where((r) => r.outcome == RescueOutcome.unableToLocate)
          .length,
      checkIns: mine.where((r) => r.checkedIn).length,
    );
  }

  // ---------------------------------------------------------- Actions

  /// "I'm on my way!"
  /// Regular users: one active response at a time, always "assisting".
  /// Verified Rescuers: many at a time, and the first one becomes the lead.
  static ActionResult respond(StrayReport report) {
    final email = AuthService.currentEmail;
    if (email == null) return const ActionResult.fail('Please log in first.');
    if (report.status == RescueStatus.rescued) {
      return const ActionResult.fail('This animal was already rescued.');
    }

    final list = _active[report.id] ?? const <ReportResponder>[];
    if (list.any((r) => r.email == email)) {
      return const ActionResult.fail('You are already responding here.');
    }

    // One active response at a time, for everyone.
    final org = RescuerService.organizationOf(email);
    if (activeCount(email) > 0) {
      return const ActionResult.fail(
        'You can only respond to one report at a time. Finish or withdraw '
            'from your current response first.',
      );
    }

    final hasLead = list.any((r) => r.role == ResponderRole.lead);
    final now = DateTime.now();
    _active[report.id] = [
      ...list,
      ReportResponder(
        email: email,
        name: _nameOf(email),
        organization: org,
        role: (org != null && !hasLead)
            ? ResponderRole.lead
            : ResponderRole.assisting,
        joinedAt: now,
        lastUpdate: now,
      ),
    ];
    _notify();
    return const ActionResult.ok(RescueStatus.inProgress);
  }

  /// Reads the phone's GPS and returns a failure unless it is within
  /// [checkInRadiusMeters] of the report's pin (null = close enough).
  static Future<ActionResult?> _requireNearby(StrayReport report) async {
    final Position pos;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const ActionResult.fail('Please turn on location services.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const ActionResult.fail(
          'Location permission is needed to check in at the animal\'s location.',
        );
      }
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      return const ActionResult.fail(
        'Could not get a GPS fix. Move to an open area and try again.',
      );
    } catch (_) {
      return const ActionResult.fail('Could not get your location.');
    }

    final meters = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      report.lat,
      report.lng,
    );
    if (meters > checkInRadiusMeters) {
      final away = meters >= 1000
          ? '${(meters / 1000).toStringAsFixed(1)} km'
          : '${meters.round()} m';
      return ActionResult.fail(
        'You are about $away away. You must be within '
            '${checkInRadiusMeters.round()} m of the animal.',
      );
    }
    return null;
  }

  /// "I've arrived" - the phone's GPS must be within [checkInRadiusMeters]
  /// of the report's pin. Needed before a responder can mark as rescued.
  static Future<ActionResult> checkIn(StrayReport report) async {
    final email = AuthService.currentEmail;
    if (email == null || mine(report.id) == null) {
      return const ActionResult.fail('You are not responding to this report.');
    }

    final tooFar = await _requireNearby(report);
    if (tooFar != null) return tooFar;

    // Re-read the list: the state may have changed during the GPS wait.
    final list = _active[report.id];
    final i = list?.indexWhere((r) => r.email == email) ?? -1;
    if (list == null || i == -1) {
      return const ActionResult.fail('You are not responding to this report.');
    }
    final updated = List.of(list);
    updated[i] = updated[i].copyWith(
      checkedIn: true,
      lastUpdate: DateTime.now(),
    );
    _active[report.id] = updated;
    _notify();
    return const ActionResult.ok();
  }

  /// Verified Rescuers only: take over a report with no recent updates.
  static ActionResult takeOver(StrayReport report) {
    final email = AuthService.currentEmail;
    final org = RescuerService.currentOrganization;
    if (email == null || org == null) {
      return const ActionResult.fail(
        'Only Verified Rescuers can take over a report.',
      );
    }
    if (!isInactive(report)) {
      return const ActionResult.fail('This report still has recent updates.');
    }
    if (activeCount(email) > 0 && mine(report.id) == null) {
      return const ActionResult.fail(
        'You can only respond to one report at a time. Finish or withdraw '
            'from your current response first.',
      );
    }

    final now = DateTime.now();
    final others = (_active[report.id] ?? const <ReportResponder>[])
        .where((r) => r.email != email)
        .map((r) => r.copyWith(role: ResponderRole.assisting))
        .toList();

    _active[report.id] = [
      ReportResponder(
        email: email,
        name: _nameOf(email),
        organization: org,
        role: ResponderRole.lead,
        joinedAt: now,
        lastUpdate: now,
      ),
      ...others,
    ];
    _notify();
    return const ActionResult.ok(RescueStatus.inProgress);
  }

  /// Leave a report without finishing it.
  static ActionResult withdraw(String reportId) {
    final email = AuthService.currentEmail;
    if (email == null) return const ActionResult.fail('Please log in first.');
    return _remove(reportId, email);
  }

  /// Mark as rescued / choose an outcome.
  /// Only the original reporter, or a responder who has checked in (GPS),
  /// can mark an animal as rescued, and they must be within
  /// [checkInRadiusMeters] of the pin at that moment. Regular users: "Rescued on site" only.
  /// Verified Rescuers: all outcomes. "Unable to locate" needs no check-in.
  static Future<ActionResult> finish(
      StrayReport report,
      RescueOutcome outcome,
      ) async {
    final email = AuthService.currentEmail;
    if (email == null) return const ActionResult.fail('Please log in first.');

    final list = _active[report.id] ?? const <ReportResponder>[];
    final me = list.where((r) => r.email == email).firstOrNull;
    final isReporter = report.isMine;
    final isVerified = RescuerService.organizationOf(email) != null;

    if (outcome == RescueOutcome.unableToLocate) {
      if (me == null) {
        return const ActionResult.fail('You are not responding to this report.');
      }
      if (!me.isVerified) {
        return const ActionResult.fail(
          'Only Verified Rescuers can choose this outcome.',
        );
      }
      _history.add(ResponseRecord(
        email: me.email,
        reportId: report.id,
        outcome: outcome,
        checkedIn: me.checkedIn,
        date: DateTime.now(),
      ));
      return _remove(report.id, me.email);
    }

    // A rescue outcome: reporter, or a responder who has checked in.
    if (me == null && !isReporter) {
      return const ActionResult.fail(
        'Only the person who reported this animal, or a responder who has '
            'checked in, can mark it as rescued.',
      );
    }
    if (!isReporter && !(me?.checkedIn ?? false)) {
      return const ActionResult.fail('Please check in at the location first.');
    }
    if (!isVerified && outcome != RescueOutcome.rescuedOnSite) {
      return const ActionResult.fail(
        'Only Verified Rescuers can choose this outcome.',
      );
    }

    // Must physically be at the animal when marking it as rescued.
    final tooFar = await _requireNearby(report);
    if (tooFar != null) return tooFar;

    final now = DateTime.now();
    final closer = me ??
        ReportResponder(
          email: email,
          name: _nameOf(email),
          organization: RescuerService.organizationOf(email),
          role: ResponderRole.lead,
          joinedAt: now,
          lastUpdate: now,
        );

    for (final r in list) {
      _history.add(ResponseRecord(
        email: r.email,
        reportId: report.id,
        outcome: r.email == closer.email ? outcome : null,
        checkedIn: r.checkedIn,
        date: now,
      ));
    }
    _active.remove(report.id);
    _closed[report.id] = RescueClosure(closer, outcome);
    _notify();
    return const ActionResult.ok(RescueStatus.rescued);
  }

  static ActionResult _remove(String reportId, String email) {
    final rest = (_active[reportId] ?? const <ReportResponder>[])
        .where((r) => r.email != email)
        .toList();

    if (rest.isEmpty) {
      _active.remove(reportId);
    } else {
      // If the lead left, promote a Verified Rescuer (if any).
      if (!rest.any((r) => r.role == ResponderRole.lead)) {
        final i = rest.indexWhere((r) => r.isVerified);
        if (i != -1) rest[i] = rest[i].copyWith(role: ResponderRole.lead);
      }
      _active[reportId] = rest;
    }
    _notify();
    return ActionResult.ok(
      rest.isEmpty ? RescueStatus.needsRescue : RescueStatus.inProgress,
    );
  }
}
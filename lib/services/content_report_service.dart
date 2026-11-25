// ===================================
// REPORTED CONTENT (Supabase)
// ===================================
// "Reported Content" = adoption posts / stray reports that USERS flagged.
// A user sends a report with submit(). An ADMIN reviews it: dismiss it (no
// violation) or remove the content (hidden, not deleted).
// The database decides who can see what: a user sees only their own reports,
// an admin sees all of them. Listen to [changes] to refresh a screen.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/content_report.dart';
import 'adoption_service.dart';
import 'auth_service.dart';
import 'db_errors.dart';
import 'report_service.dart';

class ContentReportService {
  static SupabaseClient get _db => Supabase.instance.client;

  static List<ContentReport> _reports = [];

  static bool _loaded = false;
  static Future<void>? _loading;
  static String? _loadError;
  static DateTime? _lastTry;
  static int _generation = 0;

  /// Bumps every time a report changes so screens can refresh.
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

  /// Loads again even if a load is already running (used right after
  /// something changes, so the screen shows the newest data).
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
          .from('content_reports')
          .select('*, reporter:profiles!reporter_id(full_name)')
          .order('created_at', ascending: false);
      if (gen != _generation) return; // logged out while loading

      _reports = [
        for (final dynamic r in rows)
          _fromRow(Map<String, dynamic>.from(r as Map)),
      ];
      _loaded = true;
      _loadError = null;
    } catch (e) {
      if (gen != _generation) return;
      _loadError =
          friendlyDbError(e, fallback: 'Could not load the reported content.');
    }
    _notify();
  }

  /// Forget everything (log out / switch account).
  static void reset() {
    _generation++;
    _reports = [];
    _loaded = false;
    _loading = null;
    _loadError = null;
    _lastTry = null;
    _notify();
  }

  // ---------------------------------------------------------------- Mapping

  static ContentReport _fromRow(Map<String, dynamic> row) {
    final ReportTarget target = _targetFrom(row['target_type'] as String);
    final String targetId = (target == ReportTarget.adoptionPost
        ? row['adoption_post_id']
        : row['stray_report_id']) as String? ??
        '';

    String name = 'User';
    final dynamic reporter = row['reporter'];
    if (reporter is Map) {
      final String full = (reporter['full_name'] as String? ?? '').trim();
      if (full.isNotEmpty) name = full;
    }

    return ContentReport(
      id: row['id'] as String,
      target: target,
      targetId: targetId,
      targetTitle: row['target_title'] as String? ?? '',
      reason: _reasonFrom(row['reason'] as String? ?? 'other'),
      details: row['details'] as String? ?? '',
      reportedBy: name,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      status: _statusFrom(row['status'] as String? ?? 'pending'),
    );
  }

  static String _targetValue(ReportTarget t) => switch (t) {
    ReportTarget.adoptionPost => 'adoption_post',
    ReportTarget.strayReport => 'stray_report',
  };

  static ReportTarget _targetFrom(String v) =>
      v == 'stray_report' ? ReportTarget.strayReport : ReportTarget.adoptionPost;

  static ReportReason _reasonFrom(String v) => ReportReason.values
      .firstWhere((r) => r.name == v, orElse: () => ReportReason.other);

  static ReportStatus _statusFrom(String v) => ReportStatus.values
      .firstWhere((s) => s.name == v, orElse: () => ReportStatus.pending);

  // ---------------------------------------------------------------- Reading

  /// Newest first.
  static List<ContentReport> get all {
    _kick();
    final list = List.of(_reports);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static int get pendingCount {
    _kick();
    return _reports.where((r) => r.status == ReportStatus.pending).length;
  }

  static ContentReport? byId(String id) {
    _kick();
    for (final r in _reports) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// All reports about the same piece of content.
  static List<ContentReport> forTarget(ReportTarget target, String targetId) {
    _kick();
    return _reports
        .where((r) => r.target == target && r.targetId == targetId)
        .toList();
  }

  // ---------------------------------------------------------------- Actions

  /// Runs a database call and turns any failure into a [StateError] with a
  /// message the user can read. Reloads the list afterwards.
  static Future<void> _run(Future<dynamic> Function() call,
      {required String fallback}) async {
    try {
      await call();
    } catch (e) {
      throw StateError(friendlyDbError(e, fallback: fallback));
    }
    await refresh();
  }

  /// USER: report an adoption post or a stray report to the admin.
  static Future<void> submit({
    required ReportTarget target,
    required String targetId,
    required String targetTitle,
    required ReportReason reason,
    String details = '',
  }) {
    return _run(
          () => _db.rpc('submit_content_report', params: {
        'p_target_type': _targetValue(target),
        'p_target_id': targetId,
        'p_target_title': targetTitle.trim(),
        'p_reason': reason.name,
        'p_details': details.trim(),
      }),
      fallback: 'Could not send your report. Please try again.',
    );
  }

  /// ADMIN ONLY: the content is fine, close the report.
  static Future<void> dismiss(String id) {
    return _run(
          () => _db.rpc('admin_dismiss_content_report', params: {'p_id': id}),
      fallback: 'Could not dismiss the report. Please try again.',
    );
  }

  /// ADMIN ONLY: remove the reported content (it is hidden, not deleted).
  /// Every waiting report about the same content is closed as "removed" too.
  static Future<void> removeContent(String id) async {
    await _run(
          () => _db.rpc('admin_remove_reported_content', params: {'p_id': id}),
      fallback: 'Could not remove the content. Please try again.',
    );
    // The removed post / report must disappear from the other lists too.
    unawaited(AdoptionService.load());
    unawaited(ReportService.load());
  }
}
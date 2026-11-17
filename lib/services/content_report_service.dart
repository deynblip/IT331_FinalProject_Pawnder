// ======================================
// TEMPORARY IN-MEMORY CONTENT REPORT STORE
// ======================================
// "Reported Content" = posts / stray reports that USERS flagged.
// The admin Reported tab reads from here. It works on its own with the
// sample reports below, so it does not need the user-side "Report" button
// yet. Later, that button only has to call ContentReportService.submit().
// Resets every time the app restarts.

import 'package:flutter/foundation.dart';

import '../data/mock_reports.dart';
import '../models/app_notification.dart';
import '../models/content_report.dart';
import 'adoption_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class ContentReportService {
  // Sample reports so the admin tab is not empty. Set to false to start empty.
  static const bool kShowSampleReports = true;

  static final List<ContentReport> _reports = [
    if (kShowSampleReports) ..._samples,
  ];

  static final List<ContentReport> _samples = [
    ContentReport(
      id: 'cr1',
      target: ReportTarget.adoptionPost,
      targetId: 'a3', // Mingming
      targetTitle: 'Mingming',
      reason: ReportReason.misleading,
      details: 'The post says she is spayed but the owner told me otherwise.',
      reportedBy: 'Juan Dela Cruz',
      createdAt: DateTime(2026, 11, 16),
    ),
    ContentReport(
      id: 'cr2',
      target: ReportTarget.strayReport,
      targetId: '2', // Injured Cat
      targetTitle: 'Injured Cat',
      reason: ReportReason.spam,
      reportedBy: 'Sabrina Carpenter',
      createdAt: DateTime(2026, 11, 15),
    ),
    ContentReport(
      id: 'cr3',
      target: ReportTarget.adoptionPost,
      targetId: 'a5', // Mimi
      targetTitle: 'Mimi',
      reason: ReportReason.scam,
      details: 'Asked me to send money before meeting the kitten.',
      reportedBy: 'Ed Sheeran',
      createdAt: DateTime(2026, 11, 14),
    ),
    ContentReport(
      id: 'cr4',
      target: ReportTarget.strayReport,
      targetId: '4', // Sick Dog
      targetTitle: 'Sick Dog',
      reason: ReportReason.inappropriate,
      reportedBy: 'Dane Angela',
      createdAt: DateTime(2026, 11, 12),
      status: ReportStatus.dismissed,
    ),
    ContentReport(
      id: 'cr5',
      target: ReportTarget.adoptionPost,
      targetId: 'gone', // already removed, only the saved title is left
      targetTitle: 'Max',
      reason: ReportReason.spam,
      reportedBy: 'Joshua Garcia',
      createdAt: DateTime(2026, 11, 10),
      status: ReportStatus.removed,
    ),
  ];

  /// Bumps every time a report changes so screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void _notify() => changes.value++;

  /// Newest first.
  static List<ContentReport> get all {
    final list = List.of(_reports);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static int get pendingCount =>
      _reports.where((r) => r.status == ReportStatus.pending).length;

  static ContentReport? byId(String id) {
    for (final r in _reports) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// All reports about the same piece of content.
  static List<ContentReport> forTarget(ReportTarget target, String targetId) =>
      _reports
          .where((r) => r.target == target && r.targetId == targetId)
          .toList();

  /// USER SIDE (use this when you add the "Report" button).
  /// Example:
  ///   await ContentReportService.submit(
  ///     target: ReportTarget.adoptionPost,
  ///     targetId: pet.id,
  ///     targetTitle: pet.name,
  ///     reason: ReportReason.spam,
  ///     details: 'optional text',
  ///   );
  static Future<void> submit({
    required ReportTarget target,
    required String targetId,
    required String targetTitle,
    required ReportReason reason,
    String details = '',
  }) async {
    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 500));

    final email = AuthService.currentEmail;
    final name = (email == null ? null : AuthService.nameOf(email)) ?? 'User';

    _reports.insert(
      0,
      ContentReport(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        target: target,
        targetId: targetId,
        targetTitle: targetTitle,
        reason: reason,
        details: details,
        reportedBy: name,
        createdAt: DateTime.now(),
      ),
    );
    _notify();
  }

  /// ADMIN ONLY: the content is fine, close the report.
  static Future<void> dismiss(String id) async {
    if (!AuthService.isCurrentAdmin) {
      throw StateError('Only an admin can review reports.');
    }

    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 250));

    final i = _reports.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Report not found.');

    _reports[i] = _reports[i].copyWith(status: ReportStatus.dismissed);
    _notify();
  }

  /// ADMIN ONLY: remove the reported content for good. Every waiting report
  /// about the same content is closed as "removed" too.
  static Future<void> removeContent(String id) async {
    if (!AuthService.isCurrentAdmin) {
      throw StateError('Only an admin can remove reported content.');
    }

    final i = _reports.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Report not found.');
    final report = _reports[i];

    switch (report.target) {
      case ReportTarget.adoptionPost:
      // Also tells the poster. Does nothing if it is already gone.
        await AdoptionService.removeAsAdmin(report.targetId);
      case ReportTarget.strayReport:
        await Future.delayed(const Duration(milliseconds: 250));
        final stray =
            mockReports.where((r) => r.id == report.targetId).firstOrNull;
        if (stray != null) {
          mockReports.removeWhere((r) => r.id == report.targetId);
          if (stray.isMine) {
            NotificationService.add(
              type: NotificationType.postRemoved,
              title: 'Report removed by admin',
              message: 'Your report "${stray.title}" was removed by an '
                  'administrator because it did not follow the community '
                  'guidelines.',
            );
          }
        }
    }

    for (var k = 0; k < _reports.length; k++) {
      final r = _reports[k];
      if (r.target == report.target &&
          r.targetId == report.targetId &&
          r.status == ReportStatus.pending) {
        _reports[k] = r.copyWith(status: ReportStatus.removed);
      }
    }
    _notify();
  }
}
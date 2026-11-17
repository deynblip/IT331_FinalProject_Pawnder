/// What kind of content was reported.
enum ReportTarget {
  adoptionPost,
  strayReport;

  String get label => switch (this) {
    ReportTarget.adoptionPost => 'Adoption Post',
    ReportTarget.strayReport => 'Stray Report',
  };
}

/// Why the user reported it (shown to the admin).
enum ReportReason {
  spam,
  inappropriate,
  misleading,
  scam,
  other;

  String get label => switch (this) {
    ReportReason.spam => 'Spam',
    ReportReason.inappropriate => 'Inappropriate content',
    ReportReason.misleading => 'Misleading or false information',
    ReportReason.scam => 'Scam or suspicious',
    ReportReason.other => 'Other',
  };
}

/// Admin decision on a report.
///   pending   = nobody reviewed it yet
///   removed   = admin agreed and removed the reported content
///   dismissed = admin checked it and found no violation
enum ReportStatus {
  pending,
  removed,
  dismissed;

  String get label => switch (this) {
    ReportStatus.pending => 'Pending',
    ReportStatus.removed => 'Removed',
    ReportStatus.dismissed => 'Dismissed',
  };
}

class ContentReport {
  final String id;
  final ReportTarget target;
  final String targetId; // id of the AdoptionPet / StrayReport
  final String targetTitle; // saved copy, still readable if the content is gone
  final ReportReason reason;
  final String details; // optional extra explanation from the reporter
  final String reportedBy; // name of the reporter
  final DateTime createdAt;
  final ReportStatus status;

  const ContentReport({
    required this.id,
    required this.target,
    required this.targetId,
    required this.targetTitle,
    required this.reason,
    required this.reportedBy,
    required this.createdAt,
    this.details = '',
    this.status = ReportStatus.pending,
  });

  ContentReport copyWith({ReportStatus? status}) {
    return ContentReport(
      id: id,
      target: target,
      targetId: targetId,
      targetTitle: targetTitle,
      reason: reason,
      details: details,
      reportedBy: reportedBy,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
import 'package:flutter/material.dart';

import '../../data/mock_reports.dart';
import '../../models/content_report.dart';
import '../../models/stray_report.dart';
import '../../services/adoption_service.dart';
import '../../services/content_report_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/adopt_pet_photo.dart';
import '../../utils/responsive.dart';
import '../../widgets/admin_top_bar.dart';

// ---------------------------------------------------------------- Helpers

Color _statusBg(ReportStatus s) => switch (s) {
  ReportStatus.pending => const Color(0xFFFFF3B0),
  ReportStatus.removed => const Color(0xFFFFB3B3),
  ReportStatus.dismissed => const Color(0xFFF5DEC8),
};

Color _statusFg(ReportStatus s) => switch (s) {
  ReportStatus.pending => const Color(0xFF8A6D00),
  ReportStatus.removed => const Color(0xFF9B1C1C),
  ReportStatus.dismissed => const Color(0xFF8A746C),
};

const Color _kRejectPink = Color(0xFFFF9F9F);
const Color _kRejectText = Color(0xFF7A1F1F);

String _dateText(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

Widget _photo(String? path, {double iconSize = 30}) {
  final fallback = Container(
    color: const Color(0xFFFFE8D6),
    child: Center(
      child: Icon(Icons.pets, size: iconSize, color: const Color(0xFF8A746C)),
    ),
  );
  if (path == null) return fallback;
  return PetPhoto(path: path, fallback: fallback);
}

/// What the report points at, looked up live (the content may be gone).
class _Content {
  final bool exists;
  final String? photo;
  final String subtitle; // one line for the list card
  final List<(String, String)> rows; // label / value for the details page

  const _Content({
    required this.exists,
    this.photo,
    this.subtitle = '',
    this.rows = const [],
  });
}

_Content _contentOf(ContentReport r) {
  switch (r.target) {
    case ReportTarget.adoptionPost:
      final pet = AdoptionService.byId(r.targetId);
      if (pet == null) return const _Content(exists: false);
      return _Content(
        exists: true,
        photo: pet.coverPhoto,
        subtitle: pet.summary,
        rows: [
          ('Animal Type', pet.animalType),
          ('Age / Sex', pet.summary),
          ('Location', pet.location),
          ('Description', pet.descriptionOrDefault),
          ('Posted by', pet.posterName),
        ],
      );
    case ReportTarget.strayReport:
      final stray = mockReports.where((s) => s.id == r.targetId).firstOrNull;
      if (stray == null) return const _Content(exists: false);
      return _Content(
        exists: true,
        photo: stray.imageAsset,
        subtitle: '${stray.urgency.label} · ${stray.status.label}',
        rows: [
          ('Animal Type', stray.animalType),
          ('Urgency', stray.urgency.label),
          ('Rescue Status', stray.status.label),
          ('Location', stray.location),
          ('Description', stray.descriptionOrDefault),
          ('Date Reported', stray.dateText),
        ],
      );
  }
}

Future<void> _dismiss(BuildContext context, ContentReport r) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ContentReportService.dismiss(r.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Report on ${r.targetTitle} was dismissed.')),
      );
  } on StateError catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
  }
}

Future<void> _removeContent(BuildContext context, ContentReport r) async {
  final messenger = ScaffoldMessenger.of(context);

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Remove ${r.targetTitle}?',
        style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800),
      ),
      content: Text(
        'This permanently removes the ${r.target.label.toLowerCase()} '
            'and tells its owner. Every waiting report about it will be '
            'closed. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text(
            'Remove',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
  if (ok != true) return;

  try {
    await ContentReportService.removeContent(r.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${r.targetTitle} was removed.')),
      );
  } on StateError catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
  }
}

class _StatusPill extends StatelessWidget {
  final ReportStatus status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _statusFg(status),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Reported page

class AdminReportedScreen extends StatefulWidget {
  const AdminReportedScreen({super.key});

  @override
  State<AdminReportedScreen> createState() => _AdminReportedScreenState();
}

class _AdminReportedScreenState extends State<AdminReportedScreen> {
  static const List<String> _filters = [
    'All',
    'Pending',
    'Removed',
    'Dismissed',
  ];

  String _selected = 'All';

  bool _matches(ContentReport r) {
    switch (_selected) {
      case 'Pending':
        return r.status == ReportStatus.pending;
      case 'Removed':
        return r.status == ReportStatus.removed;
      case 'Dismissed':
        return r.status == ReportStatus.dismissed;
      default:
        return true;
    }
  }

  void _openDetails(ContentReport r) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminReportDetailsScreen(reportId: r.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: kAdminGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminTopBar(),
                  const SizedBox(height: 14),
                  const Text(
                    'Reported Content',
                    style: TextStyle(
                      color: kNavy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final selected = _selected == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? kBlue : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kNavy),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: selected ? Colors.white : kNavy,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Expanded(
              // Rebuilds when a report or a post changes.
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  ContentReportService.changes,
                  AdoptionService.changes,
                ]),
                builder: (context, _) {
                  final reports =
                  ContentReportService.all.where(_matches).toList();

                  if (reports.isEmpty) {
                    return Center(
                      child: Text(
                        _selected == 'All'
                            ? 'No reported content.'
                            : 'No ${_selected.toLowerCase()} reports.',
                        style: const TextStyle(color: kHintGray),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(context.hPad, 4, context.hPad, 20),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final r = reports[i];
                      return _ReportCard(
                        report: r,
                        content: _contentOf(r),
                        onView: () => _openDetails(r),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ContentReport report;
  final _Content content;
  final VoidCallback onView;

  const _ReportCard({
    required this.report,
    required this.content,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final bool pending = report.status == ReportStatus.pending;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E2D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _photo(content.photo),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.targetTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kNavy,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _StatusPill(report.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${report.target.label} · ${report.reason.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kHintGray, fontSize: 12),
                    ),
                    Text(
                      'Reported by: ${report.reportedBy}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kHintGray, fontSize: 12),
                    ),
                    Text(
                      _dateText(report.createdAt),
                      style: const TextStyle(color: kHintGray, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Same as the Posts tab: pending reports are reviewed in Report
          // Details (Dismiss or Remove Content) before the admin decides.
          SizedBox(
            width: double.infinity,
            height: 38,
            child: pending
                ? ElevatedButton(
              onPressed: onView,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Review Report',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            )
                : OutlinedButton(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                foregroundColor: kNavy,
                side: const BorderSide(color: kNavy),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- Details page

class AdminReportDetailsScreen extends StatelessWidget {
  final String reportId;

  const AdminReportDetailsScreen({super.key, required this.reportId});

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        color: kNavy,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kHintGray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: kNavy, fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ContentReportService.changes,
        AdoptionService.changes,
      ]),
      builder: (context, _) {
        final report = ContentReportService.byId(reportId);

        if (report == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Report Details')),
            body: const Center(child: Text('This report no longer exists.')),
          );
        }

        final content = _contentOf(report);
        final bool pending = report.status == ReportStatus.pending;
        final int totalReports = ContentReportService.forTarget(
          report.target,
          report.targetId,
        ).length;

        return Scaffold(
          backgroundColor: kCream,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: kNavy,
            elevation: 0,
            title: const Text(
              'Report Details',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(context.hPad, 4, context.hPad, 20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: _photo(content.photo, iconSize: 60),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.targetTitle,
                      style: const TextStyle(
                        color: kNavy,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusPill(report.status),
                ],
              ),
              const SizedBox(height: 14),

              _section('Report'),
              _row('Content Type', report.target.label),
              _row('Reason', report.reason.label),
              _row(
                'Details from reporter',
                report.details.trim().isEmpty
                    ? 'No extra details provided.'
                    : report.details,
              ),
              _row('Reported by', report.reportedBy),
              _row('Date Reported', _dateText(report.createdAt)),
              if (totalReports > 1)
                _row('Total reports on this content', '$totalReports'),

              const Divider(height: 28),
              _section('Reported Content'),
              if (!content.exists)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'This content is no longer available (already removed '
                        'or deleted by its owner).',
                    style: TextStyle(color: kHintGray, fontSize: 14),
                  ),
                )
              else
                ...content.rows.map((e) => _row(e.$1, e.$2)),
            ],
          ),
          // Pending: Dismiss (content is fine) + Remove Content.
          bottomNavigationBar: pending
              ? SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => _dismiss(context, report),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kNavy,
                          side: const BorderSide(color: kNavy),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Dismiss',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  if (content.exists) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => _removeContent(context, report),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kRejectPink,
                            foregroundColor: _kRejectText,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Remove Content',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
              : null,
        );
      },
    );
  }
}
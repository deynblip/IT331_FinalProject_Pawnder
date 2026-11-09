import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/stray_report.dart';
import '../utils/report_style.dart';
import '../widgets/report_image.dart';
import '../widgets/status_chip.dart';

class ReportDetailsScreen extends StatefulWidget {
  final StrayReport report;
  final ValueChanged<StrayReport> onChanged;

  const ReportDetailsScreen({super.key, required this.report, required this.onChanged});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  late StrayReport _report = widget.report;

  void _apply(StrayReport updated) {
    setState(() => _report = updated);
    widget.onChanged(updated); // para mag-update din ang list
  }

  void _onMyWay() => _apply(_report.copyWith(
    status: RescueStatus.inProgress,
    responders: _report.responders + 1,
  ));

  void _markRescued() => _apply(_report.copyWith(status: RescueStatus.rescued));

  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_report.lat},${_report.lng}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: ReportColors.navy, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: ReportColors.navy, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ReportColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 17)),
      ),
    );
  }

  Widget _statusCard() {
    final Widget content;
    switch (_report.status) {
      case RescueStatus.needsRescue:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatusChip(label: 'Needs Rescue', color: ReportColors.red, outlined: true, fontSize: 16),
            const SizedBox(height: 8),
            const Text('The animal still needs assistance',
                style: TextStyle(color: ReportColors.navy, fontSize: 15)),
            const SizedBox(height: 12),
            _primaryButton("I'm on my way!", _onMyWay),
          ],
        );
        break;
      case RescueStatus.inProgress:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatusChip(label: 'Rescue in Progress', color: ReportColors.navy, outlined: true, fontSize: 16),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.groups, color: ReportColors.navy),
                const SizedBox(width: 8),
                Text('${_report.responders} community members responding',
                    style: const TextStyle(color: ReportColors.navy, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            _primaryButton('Mark as Rescued', _markRescued),
          ],
        );
        break;
      case RescueStatus.rescued:
        content = const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.check_circle, color: ReportColors.green, size: 28),
                SizedBox(height: 8),
                Text('Animal Successfully Rescued',
                    style: TextStyle(color: ReportColors.navy, fontSize: 18)),
                SizedBox(height: 4),
                Text('Thank you for everyone who helped!',
                    style: TextStyle(color: ReportColors.blue, fontSize: 13)),
              ],
            ),
          ),
        );
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E5EA)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: ReportColors.blue),
                  ),
                  const Text('Reports',
                      style: TextStyle(color: ReportColors.navy, fontSize: 28, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportImage(asset: _report.imageAsset, width: 150, height: 150),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip(
                          label: _report.urgency.label,
                          color: urgencyColor(_report.urgency),
                          fontSize: 18,
                        ),
                        const SizedBox(height: 12),
                        Text(_report.title,
                            style: const TextStyle(
                                color: ReportColors.navy, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(_report.distanceText,
                            style: const TextStyle(color: ReportColors.grey, fontSize: 15)),
                        Text(_report.dateText,
                            style: const TextStyle(color: ReportColors.grey, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _field('Animal Type', _report.animalType),
              _field('Urgency Level', _report.urgency.label),
              _field('Location', _report.location),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _openDirections,
                  icon: const Icon(Icons.navigation, color: ReportColors.navy),
                  label: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Get Directions', style: TextStyle(color: ReportColors.navy, fontSize: 17)),
                      Text('Open in Google Maps', style: TextStyle(color: ReportColors.grey, fontSize: 12)),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: Color(0xFFE3E5EA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _field('Description', _report.descriptionOrDefault),
              const SizedBox(height: 4),
              _statusCard(),
            ],
          ),
        ),
      ),
    );
  }
}
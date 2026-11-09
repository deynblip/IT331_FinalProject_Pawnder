import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_reports.dart';
import '../models/stray_report.dart';
import '../utils/app_colors.dart';
import '../utils/report_style.dart';
import '../widgets/report_card.dart';
import 'report_details_screen.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  // Batangas City (gitna ng mga mock report)
  static const LatLng _center = LatLng(13.7700, 121.0620);

  // TEMP: papalitan ng data galing backend
  final List<StrayReport> _reports = List.of(mockReports);

  // null = All
  static const Map<String, int?> _radii = {
    '5 km': 5,
    '10 km': 10,
    '20 km': 20,
    'All': null,
  };
  String _selectedRadius = 'All';
  String? _selectedId;

  // TEMP: gumagamit ng distanceKm sa mock data.
  // Kapag may backend na, kukwentahin ito mula sa location ng user.
  List<StrayReport> get _visible {
    final radius = _radii[_selectedRadius];
    final list = radius == null
        ? List.of(_reports)
        : _reports.where((r) => r.distanceKm <= radius).toList();
    list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return list;
  }

  StrayReport? _current(List<StrayReport> visible) {
    if (visible.isEmpty) return null;
    for (final r in visible) {
      if (r.id == _selectedId) return r;
    }
    return visible.first; // pinakamalapit ang default
  }

  void _openDetails(StrayReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(
          report: report,
          onChanged: (_) {}, // TEMP: ikakabit sa backend later
        ),
      ),
    );
  }

  Widget _chip(String label) {
    final selected = _selectedRadius == label;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedRadius = label;
            _selectedId = null;
          }),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? kBlue : Colors.white,
              border: Border.all(color: selected ? kBlue : kNavy, width: 1.5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : kNavy,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Marker _marker(StrayReport r, bool isSelected) {
    final size = isSelected ? 54.0 : 40.0;
    final rescued = r.status == RescueStatus.rescued;
    return Marker(
      point: LatLng(r.lat, r.lng),
      width: size,
      height: size,
      // Ang dulo ng pin ang tumatama sa eksaktong lugar
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => setState(() => _selectedId = r.id),
        child: Opacity(
          opacity: rescued ? 0.45 : 1,
          child: Icon(
            Icons.location_on,
            color: urgencyColor(r.urgency),
            size: size,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final current = _current(visible);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Map',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kNavy,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: _radii.keys.map(_chip).toList()),
          const SizedBox(height: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: _center,
                  initialZoom: 13,
                  minZoom: 3,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.paw_kie',
                  ),
                  MarkerLayer(
                    markers: visible
                        .map((r) => _marker(r, r.id == current?.id))
                        .toList(),
                  ),
                  const SimpleAttributionWidget(
                    source: Text('OpenStreetMap contributors'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (current != null)
            ReportCard(
              report: current,
              showStatus: false,
              onTap: () => _openDetails(current),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'No reports in this range.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kHintGray),
              ),
            ),
        ],
      ),
    );
  }
}
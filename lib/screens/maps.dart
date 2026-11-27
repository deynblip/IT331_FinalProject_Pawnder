import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/stray_report.dart';
import '../services/report_service.dart';
import '../utils/app_colors.dart';
import '../utils/report_style.dart';
import '../widgets/location_banner.dart';
import '../widgets/report_card.dart';
import 'report_details_screen.dart';

class MapsPage extends StatefulWidget {
  /// Opens the Reports Bulletin (provided by ReportsSection).
  final VoidCallback? onViewAllReports;

  const MapsPage({super.key, this.onViewAllReports});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  // Batangas City: used until the phone's location is known.
  static const LatLng _defaultCenter = LatLng(13.7700, 121.0620);

  final MapController _map = MapController();
  bool _mapReady = false;
  bool _centeredOnMe = false;

  // null = All
  static const Map<String, int?> _radii = {
    'All': null,
    '5 km': 5,
    '10 km': 10,
    '20 km': 20,
  };
  String _selectedRadius = 'All';
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    ReportService.ensureLoaded();
    ReportService.changes.addListener(_centerOnMe);
  }

  @override
  void dispose() {
    ReportService.changes.removeListener(_centerOnMe);
    super.dispose();
  }

  LatLng? get _me => ReportService.myLat == null
      ? null
      : LatLng(ReportService.myLat!, ReportService.myLng!);

  /// Moves the map to the phone's location once it is known.
  void _centerOnMe() {
    final me = _me;
    if (!_mapReady || _centeredOnMe || me == null) return;
    _centeredOnMe = true;
    _map.move(me, 13);
  }

  /// Round button: moves the map to the phone's location.
  /// If the location is not known yet, asks for it first (like the banner).
  Future<void> _goToMe() async {
    if (_me == null) {
      await ReportService.fixLocation();
    }
    final me = _me;
    if (me != null && _mapReady) {
      _map.move(me, 14);
    }
  }

  /// Distance comes from the phone's GPS. If the location is unknown,
  /// the km filters can't be used, so all reports are shown.
  /// Rescued animals are not on the map (they stay in My Reports and
  /// My Responses).
  List<StrayReport> get _visible {
    final reports = ReportService.all
        .where((r) => r.status != RescueStatus.rescued)
        .toList();
    final radius = _radii[_selectedRadius];
    final list = (radius == null || _me == null)
        ? List.of(reports)
        : reports
        .where((r) => r.distanceKm != null && r.distanceKm! <= radius)
        .toList();
    if (_me != null) {
      list.sort((a, b) =>
          (a.distanceKm ?? double.infinity)
              .compareTo(b.distanceKm ?? double.infinity));
    }
    return list;
  }

  StrayReport? _current(List<StrayReport> visible) {
    if (visible.isEmpty) return null;
    for (final r in visible) {
      if (r.id == _selectedId) return r;
    }
    // Without the phone's location there is no "nearest" report:
    // wait until the user taps a pin.
    if (_me == null) return null;
    return visible.first; // the nearest one by default
  }

  void _openDetails(StrayReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(
          report: report,
          onChanged: (_) {}, // the map updates itself (ReportService)
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
            alignment: Alignment.center,padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: selected ? kBlue : kSurfaceWhite,
              border: Border.all(color: selected ? kBlue : kNavy, width: 1.5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : kNavy,
                fontSize: 13,
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
      // The tip of the pin sits on the exact spot.
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

  /// Blue dot where the phone is.
  Marker _meMarker(LatLng me) {
    return Marker(
      point: me,
      width: 22,
      height: 22,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2F80ED),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReportService.changes,
      builder: (context, _) => _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final visible = _visible;
    final current = _current(visible);
    final me = _me;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Map',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: kNavy,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: _radii.keys.map(_chip).toList()),
          const SizedBox(height: 8),
          const LocationBanner(),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterMap(
                      mapController: _map,
                      options: MapOptions(
                        initialCenter: me ?? _defaultCenter,
                        initialZoom: 13,
                        minZoom: 3,
                        maxZoom: 19,
                        onTap: (_, _) => setState(() => _selectedId = null),
                        onMapReady: () {
                          _mapReady = true;
                          _centerOnMe();
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.paw_kie',
                        ),
                        MarkerLayer(
                          markers: [
                            if (me != null) _meMarker(me),
                            ...visible
                                .map((r) => _marker(r, r.id == current?.id)),
                          ],
                        ),
                        const SimpleAttributionWidget(
                          source: Text('OpenStreetMap contributors'),
                          alignment: Alignment.topLeft,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white,
                      elevation: 3,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _goToMe,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.my_location,
                              color: kBlue, size: 22),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (current != null)
                          ReportCard(
                            report: current,
                            showStatus: false,
                            compact: true,
                            onTap: () => _openDetails(current),
                          )
                        else if (visible.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kCardColor,
                              border: Border.all(color: kCardBorder),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              !ReportService.isLoaded
                                  ? (ReportService.loadError ??
                                  'Loading reports...')
                                  : 'No reports in this range.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: kHintGray),
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: widget.onViewAllReports,
                            icon: const Icon(Icons.format_list_bulleted,
                                size: 20),
                            label: const Text(
                              'View All Reports',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../services/report_service.dart';
import '../utils/app_colors.dart';

const Color _kUrgent = Color(0xFFC0525A);
const Color _kNeedsHelp = Color(0xFFC17F59);

extension _UrgencyX on Urgency {
  String get label => switch (this) {
    Urgency.urgent => 'Urgent',
    Urgency.needsHelp => 'Needs Help',
    Urgency.sighted => 'Sighted',
  };

  String get subtitle => switch (this) {
    Urgency.urgent => 'Serious risk\nor injury',
    Urgency.needsHelp => 'Sick or weak',
    Urgency.sighted => 'No urgent signs',
  };

  Color get color => switch (this) {
    Urgency.urgent => _kUrgent,
    Urgency.needsHelp => _kNeedsHelp,
    Urgency.sighted => kTeal,
  };
}

/// Values the user is filling in while going through the 3 steps.
class _Draft {
  File? photo;
  String animalType = 'Dog';
  Urgency? urgency;
  String description = '';
  bool possiblyLostPet = false; // "Has a collar / looks like someone's pet"
  LatLng? location;
  String address = '';
}

/// "Report a Stray" screen. It is opened with Navigator.push from the Home
/// "Report a Stray" button, so it is NOT one of the bottom navigation tabs.
class ReportStrayPage extends StatefulWidget {
  const ReportStrayPage({super.key});

  @override
  State<ReportStrayPage> createState() => _ReportStrayPageState();
}

class _ReportStrayPageState extends State<ReportStrayPage> {
  final _Draft _draft = _Draft();
  int _step = 0;
  bool _submitting = false;

  void _goTo(int step) => setState(() => _step = step);

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _next() {
    if (_step == 0 && _draft.urgency == null) {
      _snack('Please select an urgency level.');
      return;
    }
    if (_step == 1 && _draft.location == null) {
      _snack("Please pin the animal's location.");
      return;
    }
    _goTo(_step + 1);
  }

  void _back() {
    if (_step == 0) {
      // Leave the screen and go back to Home.
      Navigator.pop(context);
    } else {
      _goTo(_step - 1);
    }
  }

  Future<void> _submit() async {
    final d = _draft;
    if (d.urgency == null || d.location == null) return;

    setState(() => _submitting = true);
    try {
      await ReportService.submit(
        animalType: d.animalType,
        urgency: d.urgency!,
        description: d.description.trim(),
        photoPath: d.photo?.path,
        latitude: d.location!.latitude,
        longitude: d.location!.longitude,
        address: d.address,
        possiblyLostPet: d.possiblyLostPet,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Report submitted',
            style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Thank you! Rescuers can now see your report.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;

      // Done: close this screen and go back to Home.
      Navigator.pop(context);
    } catch (_) {
      _snack('Could not submit the report. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen is pushed on top of MainLayout, so it needs its own Scaffold.
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back_ios_new, color: kBlue),
                  ),
                  const Text(
                    'Report a Stray',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _StepIndicator(current: _step),
              const SizedBox(height: 16),
              Expanded(
                child: switch (_step) {
                  0 => _DetailsStep(
                    key: const ValueKey('details'),
                    draft: _draft,
                    onNext: _next,
                  ),
                  1 => _LocationStep(
                    key: const ValueKey('location'),
                    draft: _draft,
                    onBack: _back,
                    onNext: _next,
                  ),
                  _ => _ReviewStep(
                    key: const ValueKey('review'),
                    draft: _draft,
                    submitting: _submitting,
                    onEdit: _goTo,
                    onSubmit: _submit,
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Stepper

class _StepIndicator extends StatelessWidget {
  final int current;

  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    const labels = ['Details', 'Location', 'Review'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(5, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Divider(color: Colors.grey.shade300, thickness: 1),
            ),
          );
        }

        final idx = i ~/ 2;
        final isCurrent = idx == current;

        return Column(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent ? kBlue : Colors.white,
                border: Border.all(color: kBlue),
              ),
              child: Text(
                '${idx + 1}',
                style: TextStyle(
                  color: isCurrent ? Colors.white : kBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[idx],
              style: TextStyle(
                fontSize: 12,
                color: idx <= current ? kNavy : kHintGray,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------- Step 1

class _DetailsStep extends StatefulWidget {
  final _Draft draft;
  final VoidCallback onNext;

  const _DetailsStep({super.key, required this.draft, required this.onNext});

  @override
  State<_DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<_DetailsStep> {
  final _picker = ImagePicker();
  late final TextEditingController _desc =
  TextEditingController(text: widget.draft.description);

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked != null && mounted) {
        setState(() => widget.draft.photo = File(picked.path));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: kBlue),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: kBlue),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.gallery);
              },
            ),
            if (widget.draft.photo != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => widget.draft.photo = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _showPhotoOptions,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: _cardDecoration(),
              clipBehavior: Clip.antiAlias,
              child: d.photo != null
                  ? Image.file(d.photo!, fit: BoxFit.cover)
                  : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera, size: 44, color: kBlue),
                  SizedBox(height: 6),
                  Text(
                    'Add a photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                  Text(
                    'Take a photo or choose from gallery',
                    style: TextStyle(fontSize: 12, color: kHintGray),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Animal Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: ['Dog', 'Cat', 'Other'].map((type) {
              final selected = d.animalType == type;
              return ChoiceChip(
                label: Text(type),
                selected: selected,
                showCheckmark: false,
                selectedColor: kBlue,
                backgroundColor: Colors.white,
                side: const BorderSide(color: kBlue),
                labelStyle: TextStyle(color: selected ? Colors.white : kBlue),
                onSelected: (_) => setState(() => d.animalType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Urgency Level'),
          const SizedBox(height: 8),
          Row(
            children: Urgency.values.map((u) {
              final selected = d.urgency == u;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => d.urgency = u),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 90,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: u.color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? kNavy : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            u.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            u.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Condition and Behavior (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _desc,
            maxLines: 3,
            onChanged: (v) => d.description = v,
            decoration: InputDecoration(
              hintText: 'e.g. limping, wound on leg, very thin; scared but not aggressive',
              hintStyle: const TextStyle(color: kHintGray),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBlue),
              ),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: d.possiblyLostPet,
            onChanged: (v) => setState(() => d.possiblyLostPet = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: kBlue,
            title: const Text(
              "Has a collar / looks like someone's pet",
              style: TextStyle(color: kNavy, fontSize: 14),
            ),
            subtitle: const Text(
              'Responders will be reminded that it may be a lost pet.',
              style: TextStyle(color: kHintGray, fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: _OutlineBtn('Next', widget.onNext),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Step 2

class _LocationStep extends StatefulWidget {
  final _Draft draft;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _LocationStep({
    super.key,
    required this.draft,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  // Manila, used until the user pins or locates themselves.
  static const LatLng _defaultCenter = LatLng(14.5995, 120.9842);

  final MapController _map = MapController();
  bool _locating = false;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _setPin(LatLng pos, {bool moveCamera = false}) async {
    final d = widget.draft;
    setState(() {
      d.location = pos;
      d.address = 'Finding address...';
    });

    if (moveCamera) {
      _map.move(pos, 17);
    }

    // Fallback if reverse geocoding fails: show the coordinates.
    var address =
        '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';

    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = [p.street, p.subLocality, p.locality, p.administrativeArea]
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) address = parts.join(', ');
      }
    } catch (_) {
      // Keep the coordinates.
    }

    // Ignore the result if the user already moved the pin again.
    if (mounted && d.location == pos) {
      setState(() => d.address = address);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Please turn on location services.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission denied. You can still tap the map to pin a spot.';
      }

      final pos = await Geolocator.getCurrentPosition();
      await _setPin(LatLng(pos.latitude, pos.longitude), moveCamera: true);
    } catch (e) {
      if (mounted) {
        final message = e is String ? e : 'Could not get your location.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Where did you spot the animal?'),
        const SizedBox(height: 2),
        const Text(
          "Pinpoint the animal's location to help rescuers find it.",
          style: TextStyle(fontSize: 12, color: kHintGray),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: d.location ?? _defaultCenter,
                initialZoom: d.location != null ? 17 : 12,
                minZoom: 3,
                maxZoom: 19,
                onTap: (tapPosition, point) => _setPin(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.paw_kie',
                ),
                if (d.location != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: d.location!,
                        width: 44,
                        height: 44,
                        // Pin tip sits exactly on the tapped point.
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          color: _kUrgent,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap contributors'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _locating
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.my_location),
            label: const Text(
              'Use current location',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(radius: 12),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: kBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  d.location == null ? 'Tap the map to drop a pin' : d.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: d.location == null ? kHintGray : kNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap the map to change the location',
          style: TextStyle(fontSize: 10, color: kBlue),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _OutlineBtn('Back', widget.onBack),
            _OutlineBtn('Next', widget.onNext),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Step 3

class _ReviewStep extends StatelessWidget {
  final _Draft draft;
  final bool submitting;
  final void Function(int step) onEdit;
  final VoidCallback onSubmit;

  const _ReviewStep({
    super.key,
    required this.draft,
    required this.submitting,
    required this.onEdit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final description = draft.description.trim().isEmpty
        ? 'No details provided.'
        : draft.description.trim();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Check your report details'),
          const SizedBox(height: 12),
          Container(
            height: 150,
            width: double.infinity,
            decoration: _cardDecoration(),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: draft.photo != null
                ? Image.file(
              draft.photo!,
              fit: BoxFit.cover,
              width: double.infinity,
            )
                : const Text(
              'No photo added',
              style: TextStyle(color: kHintGray, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _ReviewRow('Animal Type', draft.animalType, () => onEdit(0)),
                _ReviewRow(
                  'Urgency Level',
                  draft.urgency?.label ?? '-',
                      () => onEdit(0),
                ),
                _ReviewRow(
                  'Location',
                  draft.address.isEmpty ? '-' : draft.address,
                      () => onEdit(1),
                ),
                _ReviewRow('Condition and Behavior', description, () => onEdit(0)),
                _ReviewRow(
                  'Possibly a lost pet',
                  draft.possiblyLostPet ? 'Yes (has a collar / looks owned)' : 'No',
                      () => onEdit(0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: submitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Submit Report',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onEdit;

  const _ReviewRow(this.title, this.value, this.onEdit);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, color: kNavy)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Text('Edit', style: TextStyle(fontSize: 11, color: kBlue)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Shared

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: kNavy,
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlineBtn(this.label, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: kNavy,
        side: const BorderSide(color: kNavy),
        minimumSize: const Size(76, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 16}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
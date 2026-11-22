import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../services/report_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';

const Color _kUrgent = Color(0xFFE04F4F);
const Color _kNeedsHelp = Color(0xFFE9A23B);
const Color _kError = Color(0xFFE04F4F);

// Manila, used until the user pins or locates themselves.
const LatLng _defaultCenter = LatLng(14.5995, 120.9842);

const String _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String _userAgent = 'com.example.paw_kie';

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

/// Values the user fills in on the form.
class _Draft {
  File? photo;
  String animalType = 'Dog';
  Urgency? urgency;
  String description = '';
  bool possiblyLostPet = false; // "Has a collar / looks like someone's pet"
  LatLng? location;
  String address = '';
}

/// A pinned spot and its readable address.
class _PickedLocation {
  final LatLng point;
  final String address;

  const _PickedLocation(this.point, this.address);
}

// ---------------------------------------------------------------- Location helpers

/// Readable address for [pos]. Falls back to the coordinates if
/// reverse geocoding fails.
Future<String> _addressFor(LatLng pos) async {
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
  return address;
}

/// The phone's current position. Throws a readable message on failure.
Future<LatLng> _currentLatLng() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw 'Please turn on location services.';
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw 'Location permission denied. You can still pin the spot on the map.';
  }

  final pos = await Geolocator.getCurrentPosition();
  return LatLng(pos.latitude, pos.longitude);
}

// ---------------------------------------------------------------- Screen

/// "Report a Stray" screen: one scrolling form with a Submit button at the
/// bottom. It is opened with Navigator.push from Home, so it is NOT one of
/// the bottom navigation tabs.
class ReportStrayPage extends StatefulWidget {
  const ReportStrayPage({super.key});

  @override
  State<ReportStrayPage> createState() => _ReportStrayPageState();
}

class _ReportStrayPageState extends State<ReportStrayPage> {
  final _Draft _draft = _Draft();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _desc = TextEditingController();

  // Used to scroll to a section that still needs an answer.
  final GlobalKey _urgencyKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();

  bool _submitting = false;
  bool _locating = false;
  bool _showErrors = false; // set after the first Submit tap

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------- Photo

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked != null && mounted) {
        setState(() => _draft.photo = File(picked.path));
      }
    } catch (_) {
      _snack('Could not open the camera or gallery.');
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
            if (_draft.photo != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _draft.photo = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Location

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final point = await _currentLatLng();
      setState(() {
        _draft.location = point;
        _draft.address = 'Finding address...';
      });
      final address = await _addressFor(point);
      if (mounted && _draft.location == point) {
        setState(() => _draft.address = address);
      }
    } catch (e) {
      _snack(e is String ? e : 'Could not get your location.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openMapPicker() async {
    final picked = await Navigator.push<_PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => _LocationPickerPage(
          initial: _draft.location,
          initialAddress: _draft.address,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _draft.location = picked.point;
        _draft.address = picked.address;
      });
    }
  }

  // ---------------------------------------------------------------- Submit

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      alignment: 0.1,
    );
  }

  Future<void> _submit() async {
    final d = _draft;

    // Required: urgency and location. Scroll to the first missing one.
    if (d.urgency == null || d.location == null) {
      setState(() => _showErrors = true);
      _scrollTo(d.urgency == null ? _urgencyKey : _locationKey);
      _snack(
        d.urgency == null
            ? 'Please select an urgency level.'
            : "Please set the animal's location.",
      );
      return;
    }

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

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final d = _draft;
    final double pad = context.hPad;

    // This screen is pushed on top of MainLayout, so it needs its own Scaffold.
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(pad - 8, 8, pad, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _photoCard(),
                    const SizedBox(height: 20),
                    const _SectionTitle('Animal Type'),
                    const SizedBox(height: 8),
                    _animalTypeChips(),
                    const SizedBox(height: 20),
                    _SectionTitle('Urgency Level', key: _urgencyKey),
                    const SizedBox(height: 8),
                    _urgencyCards(),
                    if (_showErrors && d.urgency == null)
                      const _ErrorText('Please select an urgency level.'),
                    const SizedBox(height: 20),
                    _SectionTitle('Location', key: _locationKey),
                    const SizedBox(height: 2),
                    const Text(
                      "Pinpoint the animal's location to help rescuers find it.",
                      style: TextStyle(fontSize: 12, color: kHintGray),
                    ),
                    const SizedBox(height: 10),
                    _locationCard(),
                    if (_showErrors && d.location == null)
                      const _ErrorText("Please set the animal's location."),
                    const SizedBox(height: 20),
                    const _SectionTitle('Condition and Behavior (optional)'),
                    const SizedBox(height: 8),
                    _descriptionField(),
                    const SizedBox(height: 8),
                    _lostPetCheckbox(),
                  ],
                ),
              ),
            ),

            // Submit button, always visible at the bottom.
            _BottomBar(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoCard() {
    final photo = _draft.photo;
    return InkWell(
      onTap: _showPhotoOptions,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: _cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: photo != null
            ? Image.file(photo, fit: BoxFit.cover)
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera, size: 44, color: kBlue),
            SizedBox(height: 6),
            Text(
              'Add a photo',
              style: TextStyle(fontWeight: FontWeight.w800, color: kNavy),
            ),
            Text(
              'Take a photo or choose from gallery',
              style: TextStyle(fontSize: 12, color: kHintGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animalTypeChips() {
    return Wrap(
      spacing: 10,
      children: ['Dog', 'Cat', 'Other'].map((type) {
        final selected = _draft.animalType == type;
        return ChoiceChip(
          label: Text(type),
          selected: selected,
          showCheckmark: false,
          selectedColor: kBlue,
          backgroundColor: Colors.white,
          side: const BorderSide(color: kBlue),
          labelStyle: TextStyle(color: selected ? Colors.white : kBlue),
          onSelected: (_) => setState(() => _draft.animalType = type),
        );
      }).toList(),
    );
  }

  Widget _urgencyCards() {
    return Row(
      children: Urgency.values.map((u) {
        final selected = _draft.urgency == u;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _draft.urgency = u),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                // Grows if the text wraps on small phones.
                constraints: const BoxConstraints(minHeight: 90),
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
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Small, non-moving map preview with the address and two ways to set
  /// the location. The full map opens on its own screen, so dragging the
  /// map never fights with scrolling the form.
  Widget _locationCard() {
    final d = _draft;
    final point = d.location;

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview (tap to open the full map)
          GestureDetector(
            onTap: _openMapPicker,
            child: SizedBox(
              height: 150,
              child: point == null
                  ? Container(
                color: kPeach,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 40, color: kBlue),
                    SizedBox(height: 6),
                    Text(
                      'No location set yet',
                      style: TextStyle(color: kNavy),
                    ),
                  ],
                ),
              )
                  : IgnorePointer(
                child: FlutterMap(
                  key: ValueKey(point),
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _tileUrl,
                      userAgentPackageName: _userAgent,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_on,
                            color: _kUrgent,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Address
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: kBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point == null ? 'Set the location below' : d.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: point == null ? kHintGray : kNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _locating ? null : _useCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _locating
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.my_location, size: 18),
                    label: const FittedBox(child: Text('Use my location')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openMapPicker,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kBlue,
                      side: const BorderSide(color: kBlue),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.push_pin_outlined, size: 18),
                    label: FittedBox(
                      child: Text(point == null ? 'Pin on map' : 'Change pin'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionField() {
    return TextField(
      controller: _desc,
      maxLines: 3,
      onChanged: (v) => _draft.description = v,
      decoration: InputDecoration(
        hintText:
        'e.g. limping, wound on leg, very thin; scared but not aggressive',
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
    );
  }

  Widget _lostPetCheckbox() {
    return CheckboxListTile(
      value: _draft.possiblyLostPet,
      onChanged: (v) => setState(() => _draft.possiblyLostPet = v ?? false),
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
    );
  }
}

// ---------------------------------------------------------------- Map picker

/// Full-screen map for pinning the animal's location.
/// Returns a [_PickedLocation] when the user taps "Confirm location".
class _LocationPickerPage extends StatefulWidget {
  final LatLng? initial;
  final String initialAddress;

  const _LocationPickerPage({this.initial, this.initialAddress = ''});

  @override
  State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  final MapController _map = MapController();

  LatLng? _point;
  String _address = '';
  bool _locating = false;
  bool _finding = false; // looking up the address

  @override
  void initState() {
    super.initState();
    _point = widget.initial;
    _address = widget.initialAddress;
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _setPin(LatLng pos, {bool moveCamera = false}) async {
    setState(() {
      _point = pos;
      _finding = true;
    });
    if (moveCamera) _map.move(pos, 17);

    final address = await _addressFor(pos);

    // Ignore the result if the user already moved the pin again.
    if (mounted && _point == pos) {
      setState(() {
        _address = address;
        _finding = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      await _setPin(await _currentLatLng(), moveCamera: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is String ? e : 'Could not get your location.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = _point;
    final double pad = context.hPad;

    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(pad - 8, 8, pad, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: kBlue),
                  ),
                  const Expanded(
                    child: Text(
                      'Pin the location',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 10),
              child: const Text(
                'Tap the map where you saw the animal.',
                style: TextStyle(fontSize: 12, color: kHintGray),
              ),
            ),

            // Map
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: point ?? _defaultCenter,
                      initialZoom: point != null ? 17 : 12,
                      minZoom: 3,
                      maxZoom: 19,
                      onTap: (tapPosition, latLng) => _setPin(latLng),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _tileUrl,
                        userAgentPackageName: _userAgent,
                      ),
                      if (point != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
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
            ),

            // Address and buttons
            _BottomBar(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: kBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point == null
                              ? 'Tap the map to drop a pin'
                              : (_finding ? 'Finding address...' : _address),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: point == null ? kHintGray : kNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _locating ? null : _useCurrentLocation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kBlue,
                            side: const BorderSide(color: kBlue),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _locating
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.my_location, size: 18),
                          label: const FittedBox(
                            child: Text('Use my location'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: point == null || _finding
                              ? null
                              : () => Navigator.pop(
                            context,
                            _PickedLocation(point, _address),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBlue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const FittedBox(
                            child: Text(
                              'Confirm location',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Shared

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text, {super.key});

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

/// Red message shown under a required section that is still empty.
class _ErrorText extends StatelessWidget {
  final String text;

  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(text, style: const TextStyle(color: _kError, fontSize: 12)),
    );
  }
}

/// Bar pinned to the bottom of the screen (for the main button).
class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final double pad = context.hPad;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(pad, 12, pad, 12),
      decoration: const BoxDecoration(
        color: kCream,
        border: Border(top: BorderSide(color: kCardBorder)),
      ),
      child: child,
    );
  }
}

BoxDecoration _cardDecoration({double radius = 16}) {
  return BoxDecoration(
    color: kCardColor,
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
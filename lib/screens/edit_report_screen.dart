import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/stray_report.dart';
import '../services/report_service.dart';
import '../utils/app_colors.dart';
import '../utils/report_style.dart';
import '../utils/responsive.dart';
import '../utils/validators.dart';
import '../widgets/field_label.dart';
import '../widgets/report_image.dart';

// ===============================
// EDIT REPORT (Profile > My Reports > Edit)
// ===============================
// The reporter can change the animal type, urgency, description, photo and
// the "possibly a lost pet" tag. The location pin can't be changed.
// Not allowed once someone is responding or the animal is rescued (the
// database checks this too).

class EditReportScreen extends StatefulWidget {
  final StrayReport report;

  const EditReportScreen({super.key, required this.report});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  static const List<String> _animals = ['Dog', 'Cat', 'Other'];

  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _description;
  late String _animal;
  late Urgency _urgency;
  late bool _lostPet;

  File? _newPhoto;
  bool _removePhoto = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final r = widget.report;
    _description = TextEditingController(text: r.description);
    _animal = _animals.contains(r.animalType) ? r.animalType : 'Other';
    _urgency = r.urgency;
    _lostPet = r.possiblyLostPet;
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
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
        setState(() {
          _newPhoto = File(picked.path);
          _removePhoto = false;
        });
      }
    } catch (_) {
      if (mounted) showMessage(context, 'Could not open the camera or gallery.');
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
          ],
        ),
      ),
    );
  }

  bool get _hasPhoto =>
      _newPhoto != null ||
          (!_removePhoto && (widget.report.imageAsset ?? '').isNotEmpty);

  Widget _photoPreview() {
    const double size = 140;
    if (_newPhoto != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_newPhoto!,
            width: size, height: size, fit: BoxFit.cover),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ReportImage(
        asset: _removePhoto ? null : widget.report.imageAsset,
        width: size,
        height: size,
      ),
    );
  }

  // ---------------------------------------------------------------- Save

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ReportService.updateMine(
        report: widget.report,
        animalType: _animal,
        urgency: _urgency,
        description: _description.text,
        possiblyLostPet: _lostPet,
        newPhoto: _newPhoto,
        removePhoto: _removePhoto,
      );
    } on ReportFailure catch (e) {
      if (mounted) showMessage(context, e.message);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    showMessage(context, 'Report updated.');
    Navigator.pop(context, true);
  }

  Widget _chips<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required Color Function(T) color,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final bool on = v == selected;
        return ChoiceChip(
          label: Text(
            label(v),
            style: TextStyle(
              color: on ? Colors.white : kNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
          selected: on,
          selectedColor: color(v),
          backgroundColor: kCardColor,
          side: BorderSide(color: on ? color(v) : kCardBorder),
          showCheckmark: false,
          onSelected: (_) => onSelected(v),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: context.hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: kBlue),
                  ),
                  const Text(
                    'Edit Report',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Photo
              const FieldLabel('Photo'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _photoPreview(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showPhotoOptions,
                          icon: const Icon(Icons.photo_camera_outlined,
                              size: 18),
                          label: Text(_hasPhoto ? 'Change photo' : 'Add photo'),
                        ),
                        if (_hasPhoto)
                          TextButton(
                            onPressed: () => setState(() {
                              _newPhoto = null;
                              _removePhoto = true;
                            }),
                            child: const Text(
                              'Remove photo',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Animal type
              const FieldLabel('Animal Type', required: true),
              const SizedBox(height: 8),
              _chips<String>(
                values: _animals,
                selected: _animal,
                label: (a) => a,
                color: (_) => kBlue,
                onSelected: (a) => setState(() => _animal = a),
              ),
              const SizedBox(height: 20),

              // Urgency
              const FieldLabel('Urgency Level', required: true),
              const SizedBox(height: 8),
              _chips<Urgency>(
                values: Urgency.values,
                selected: _urgency,
                label: (u) => u.label,
                color: urgencyColor,
                onSelected: (u) => setState(() => _urgency = u),
              ),
              const SizedBox(height: 20),

              // Description
              const FieldLabel('Condition and Behavior'),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'Describe the animal and what you saw.',
                  filled: true,
                  fillColor: kCardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kCardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kCardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Possibly a lost pet
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _lostPet,
                activeColor: kBlue,
                title: const Text(
                  'This may be a lost pet',
                  style: TextStyle(
                    color: kNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onChanged: (v) => setState(() => _lostPet = v),
              ),
              const SizedBox(height: 12),

              // Location (read-only)
              const FieldLabel('Location'),
              const SizedBox(height: 6),
              Text(
                widget.report.location,
                style: const TextStyle(color: kNavy, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.lock_outline, size: 16, color: kHintGray),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "The location can't be changed. If it is wrong, remove "
                          'this report and submit a new one.',
                      style: TextStyle(color: kHintGray, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _busy ? 'Saving...' : 'Save Changes',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/adoption_pet.dart';
import '../services/adoption_service.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/adopt_pet_photo.dart';
import '../widgets/field_label.dart';
import '../utils/responsive.dart';

const int _kMaxPhotos = 5;
const String _kProvince = 'Batangas';

/// "Post a Pet for Adoption": one scrolling form with a Publish button at the
/// bottom and a short confirmation before it is sent. Opened with
/// Navigator.push from the + button in the Adoption Bulletin. Pops with `true`
/// when a pet is published. If [pet] is given, the same form EDITS that post.
class PostPetScreen extends StatefulWidget {
  final String posterName;

  final AdoptionPet? pet;

  const PostPetScreen({super.key, required this.posterName, this.pet});

  bool get isEditing => pet != null;

  @override
  State<PostPetScreen> createState() => _PostPetScreenState();
}

class _PostPetScreenState extends State<PostPetScreen> {
  // One Form per section, so the first section with an error can be found.
  final List<GlobalKey<FormState>> _formKeys =
  List.generate(3, (_) => GlobalKey<FormState>());

  // Section headings, used to scroll to a section that has an error.
  final List<GlobalKey> _sectionKeys = List.generate(3, (_) => GlobalKey());
  final ImagePicker _picker = ImagePicker();

  bool _publishing = false;

  // Pet Information
  final List<String> _photos = [];
  String _animalType = 'Dog';

  /// Rescued Stray (priority) or Owned Pet (Rehoming).
  PetSource _source = PetSource.rescuedStray;
  String? _sex;
  final _name = TextEditingController();
  final _age = TextEditingController();

  // About the Pet
  final _description = TextEditingController();
  final _health = TextEditingController();
  final _reason = TextEditingController();

  // Location & Contact
  final _city = TextEditingController();
  final _barangay = TextEditingController();
  final _street = TextEditingController();
  final _contactPerson = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    if (pet == null) {
      _contactPerson.text = widget.posterName; // user can still edit it
      return;
    }
    // Edit mode: fill in the current values.
    _photos.addAll(pet.photos);
    _animalType = pet.animalType;
    _source = pet.source;
    _sex = pet.sex;
    _name.text = pet.name;
    _age.text = pet.age;
    _description.text = pet.description;
    _health.text = pet.healthInfo;
    _reason.text = pet.reasonForAdoption;
    // location is "Barangay, City, Province"
    final parts = pet.location.split(', ');
    _barangay.text = parts.isNotEmpty ? parts[0] : '';
    _city.text = parts.length > 1 ? parts[1] : '';
    _street.text = pet.street;
    _contactPerson.text = pet.contactPerson;
    _phone.text = pet.contactPhone;
    _email.text = pet.contactEmail;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _age,
      _description,
      _health,
      _reason,
      _city,
      _barangay,
      _street,
      _contactPerson,
      _phone,
      _email,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------ Validation

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollToSection(int index) {
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      alignment: 0.05,
    );
  }

  /// Validates every section. Shows the red error text under each invalid
  /// field and scrolls to the first section that needs fixing.
  bool _validateAll() {
    final results = _formKeys.map((k) => k.currentState!.validate()).toList();

    if (_photos.isEmpty) {
      _scrollToSection(0);
      _snack('Please add at least one photo.');
      return false;
    }
    final firstInvalid = results.indexOf(false);
    if (firstInvalid != -1) {
      _scrollToSection(firstInvalid);
      _snack('Please complete the highlighted fields.');
      return false;
    }
    return true;
  }

  /// Short confirmation instead of a full review step.
  Future<void> _confirmAndPublish() async {
    if (!_validateAll()) return;

    final editing = widget.isEditing;
    final reviewNote = editing
        ? 'Your post will be reviewed by the admin again.'
        : 'Your post will be sent to the admin for approval.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          editing ? 'Save changes?' : 'Publish this post?',
          style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '${_name.text.trim()} · $_animalType · ${_source.label}\n'
              '$_location\n\n'
              'Contact: ${_phone.text.trim()} · ${_email.text.trim()}\n\n'
              '$reviewNote Please check that your contact details are correct.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              editing ? 'Save' : 'Publish',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _publish();
  }

  // ---------------------------------------------------------------- Photos

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked != null && mounted) {
        setState(() => _photos.add(picked.path));
      }
    } catch (_) {
      _snack('Could not open the camera or gallery.');
    }
  }

  void _showPhotoOptions() {
    if (_photos.length >= _kMaxPhotos) {
      _snack('You can add up to $_kMaxPhotos photos.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            if (!kIsWeb) // Chrome has no camera option, gallery only
              ListTile(
                leading: const Icon(Icons.photo_camera, color: kBlue),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhoto(ImageSource.camera);
                },
              ),

            ListTile(
              leading: const Icon(Icons.photo_library, color: kBlue),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- Publish

  String get _location =>
      '${_barangay.text.trim()}, ${_city.text.trim()}, $_kProvince';

  Future<void> _publish() async {
    final sex = _sex;
    if (sex == null) return;

    final editing = widget.pet;
    setState(() => _publishing = true);
    try {
      if (editing == null) {
        await AdoptionService.publish(
          name: _name.text.trim(),
          animalType: _animalType,
          age: _age.text.trim(),
          sex: sex,
          location: _location, // street is NOT shown publicly
          description: _description.text.trim(),
          healthInfo: _health.text.trim(),
          reasonForAdoption: _reason.text.trim(),
          posterName: widget.posterName,
          street: _street.text.trim(),
          photos: List.of(_photos),
          contactPerson: _contactPerson.text.trim(),
          contactPhone: _phone.text.trim(),
          contactEmail: _email.text.trim(),
          source: _source,
        );
      } else {
        await AdoptionService.update(
          editing.id,
          name: _name.text.trim(),
          animalType: _animalType,
          age: _age.text.trim(),
          sex: sex,
          location: _location,
          description: _description.text.trim(),
          healthInfo: _health.text.trim(),
          reasonForAdoption: _reason.text.trim(),
          street: _street.text.trim(),
          photos: List.of(_photos),
          contactPerson: _contactPerson.text.trim(),
          contactPhone: _phone.text.trim(),
          contactEmail: _email.text.trim(),
          source: _source,
        );
      }
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            editing == null ? 'Post submitted!' : 'Changes saved!',
            style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800),
          ),
          content: Text(
            editing == null
                ? '${_name.text.trim()} was sent to the admin for approval. '
                'It will appear on the Adopt board once approved.'
                : 'Your post for ${_name.text.trim()} was updated and will '
                'be reviewed by the admin again.',
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

      Navigator.pop(context, true); // tells the Bulletin to reload
    } on StateError catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not save the post. Please try again.');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  // ------------------------------------------------------------ Validators

  String? _required(String? v, String message) =>
      (v ?? '').trim().isEmpty ? message : null;

  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'[\s\-]'), '');
    if (digits.isEmpty) return 'Please enter a phone number';
    if (!RegExp(r'^(09|\+639)\d{9}$').hasMatch(digits)) {
      return 'Enter a valid mobile number, e.g. 0993 456 7891';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Please enter an email address';
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email address';
    return null;
  }

  // ----------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
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
                  Expanded(
                    child: Text(
                      widget.isEditing
                          ? 'Edit Pet Post'
                          : 'Post a Pet for Adoption',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
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
                    const RequiredNote(),
                    const SizedBox(height: 12),
                    _sectionHeading('Pet Information', key: _sectionKeys[0]),
                    const SizedBox(height: 12),
                    _buildPetInfoSection(),
                    const SizedBox(height: 28),
                    _sectionHeading('About the Pet', key: _sectionKeys[1]),
                    const SizedBox(height: 12),
                    _buildAboutSection(),
                    const SizedBox(height: 28),
                    SizedBox(key: _sectionKeys[2]),
                    _buildLocationSection(),
                    const SizedBox(height: 16),
                    const Text(
                      'Your contact details stay hidden until an applicant '
                          'passes admin screening.',
                      style: TextStyle(fontSize: 12, color: kHintGray),
                    ),
                  ],
                ),
              ),
            ),

            // Publish button, always visible at the bottom.
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 12),
              decoration: const BoxDecoration(
                color: kCream,
                border: Border(top: BorderSide(color: kCardBorder)),
              ),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _publishing ? null : _confirmAndPublish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _publishing
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    widget.isEditing ? 'Save Changes' : 'Publish',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------ Pet Information

  Widget _buildPetInfoSection() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Pet Photos', required: true),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showPhotoOptions,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: _cardDecoration(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_camera, size: 40, color: kBlue),
                  const SizedBox(height: 6),
                  const Text(
                    'Add a photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                  Text(
                    'Take a photo or choose from gallery '
                        '(${_photos.length}/$_kMaxPhotos)',
                    style: const TextStyle(fontSize: 12, color: kHintGray),
                  ),
                ],
              ),
            ),
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _photoThumb(i),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _title('Pet Name', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _name,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: _dec("Enter pet's name"),
            validator: (v) => _required(v, "Please enter the pet's name"),
          ),
          const SizedBox(height: 14),
          _title('Animal Type', required: true),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: ['Dog', 'Cat', 'Other'].map((type) {
              final selected = _animalType == type;
              return ChoiceChip(
                label: Text(type),
                selected: selected,
                showCheckmark: false,
                selectedColor: kBlue,
                backgroundColor: Colors.white,
                side: const BorderSide(color: kBlue),
                labelStyle: TextStyle(color: selected ? Colors.white : kBlue),
                onSelected: (_) => setState(() => _animalType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _title('Pet Source', required: true),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: PetSource.values.map((src) {
              final selected = _source == src;
              return ChoiceChip(
                label: Text(
                  src == PetSource.rescuedStray
                      ? 'Rescued Stray'
                      : 'Owned Pet (Rehoming)',
                ),
                selected: selected,
                showCheckmark: false,
                selectedColor: kBlue,
                backgroundColor: Colors.white,
                side: const BorderSide(color: kBlue),
                labelStyle: TextStyle(color: selected ? Colors.white : kBlue),
                onSelected: (_) => setState(() => _source = src),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text(
            _source == PetSource.rescuedStray
                ? 'An animal rescued from the street. Rescued strays are shown '
                'first in the Adoption Bulletin.'
                : 'A pet you can no longer care for. You will be asked for '
                'your reason for rehoming.',
            style: const TextStyle(color: kHintGray, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('Age', required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _age,
                      maxLength: 20,
                      decoration: _dec('e.g. 1 year'),
                      validator: (v) => _required(v, 'Enter the age'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('Sex', required: true),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _sex,
                      decoration: _dec('Select sex'),
                      items: const ['Male', 'Female']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _sex = v),
                      validator: (v) => v == null ? 'Select sex' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoThumb(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 84,
            height: 84,
            child: PetPhoto(
              path: _photos[index],
              fallback: Container(
                color: const Color(0xFFFFE8D6),
                child: const Icon(Icons.pets, color: kHintGray),
              ),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => setState(() => _photos.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------- About the Pet

  Widget _buildAboutSection() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Description', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _description,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration:
            _dec("Describe the pet's personality, behavior, and other details..."),
            validator: (v) {
              final text = (v ?? '').trim();
              if (text.isEmpty) return 'Please describe the pet';
              if (text.length < 10) return 'Please add a little more detail';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _title('Health Information (optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _health,
            maxLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration:
            _dec('Vaccination, deworming, medical history, or unknown details...'),
          ),
          const SizedBox(height: 14),
          _title(_source.reasonLabel, required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _reason,
            maxLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              _source == PetSource.rehoming
                  ? 'Why can you no longer keep this pet? (e.g. moving, allergies)'
                  : 'Why does this pet need a new home?',
            ),
            validator: (v) => _required(
              v,
              _source == PetSource.rehoming
                  ? 'Please give your reason for rehoming'
                  : 'Please tell us why',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selling, asking for fees, and breeding or "for stud" posts are '
                'not allowed and will be rejected.',
            style: TextStyle(color: kHintGray, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------- Location & Contact

  Widget _buildLocationSection() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Current Address'),
          const SizedBox(height: 8),
          _title('Province'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _kProvince,
            enabled: false, // fixed to Batangas for now
            decoration: _dec(''),
          ),
          const SizedBox(height: 14),
          _title('City / Municipality', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('e.g. Batangas City'),
            validator: (v) => _required(v, 'Please enter the city or municipality'),
          ),
          const SizedBox(height: 14),
          _title('Barangay', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _barangay,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('e.g. Alangilan'),
            validator: (v) => _required(v, 'Please enter the barangay'),
          ),
          const SizedBox(height: 14),
          _title('Street / Landmark (optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _street,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Enter street or nearby landmark'),
          ),
          const SizedBox(height: 24),
          _sectionHeading('Contact Information'),
          const SizedBox(height: 8),
          _title('Contact Person', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contactPerson,
            textCapitalization: TextCapitalization.words,
            decoration: _dec("Enter contact person's full name"),
            validator: (v) => _required(v, 'Please enter the contact person'),
          ),
          const SizedBox(height: 14),
          _title('Phone Number', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _dec("Enter contact person's phone number"),
            validator: _validatePhone,
          ),
          const SizedBox(height: 14),
          _title('Email Address', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: _dec("Enter contact person's email address"),
            validator: _validateEmail,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Shared

  /// Field label. Required fields get a red *.
  Widget _title(String text, {bool required = false}) =>
      FieldLabel(text, required: required);

  Widget _sectionHeading(String text, {Key? key}) => Text(
    text,
    key: key,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 18,
      color: kNavy,
    ),
  );
}

// ------------------------------------------------------- Top-level helpers

OutlineInputBorder _border(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: color),
);

InputDecoration _dec(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: kHintGray),
  filled: true,
  fillColor: Colors.white,
  counterText: '', // hide the "0/30" counter
  border: _border(Colors.grey.shade300),
  enabledBorder: _border(Colors.grey.shade300),
  disabledBorder: _border(Colors.grey.shade300),
  focusedBorder: _border(kBlue),
  errorBorder: _border(Colors.red),
  focusedErrorBorder: _border(Colors.red),
);

BoxDecoration _cardDecoration() => BoxDecoration(
  color: kCardColor,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
);
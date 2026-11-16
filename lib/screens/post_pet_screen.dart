import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/adoption_pet.dart';
import '../services/adoption_service.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/adopt_pet_photo.dart';

const int _kMaxPhotos = 5;
const String _kProvince = 'Batangas';

/// "Post a Pet for Adoption" (4 steps). Opened with Navigator.push from the
/// + button in the Adoption Bulletin. Pops with `true` when a pet is published.
/// If [pet] is given, the same form is used to EDIT that post.
class PostPetScreen extends StatefulWidget {
  final String posterName;

  /// Kapag may laman, Edit mode ito (ine-edit ang existing post).
  final AdoptionPet? pet;

  const PostPetScreen({super.key, required this.posterName, this.pet});

  bool get isEditing => pet != null;

  @override
  State<PostPetScreen> createState() => _PostPetScreenState();
}

class _PostPetScreenState extends State<PostPetScreen> {
  static const List<String> _stepLabels = [
    'Pet\nInformation',
    'About\nthe Pet',
    'Location &\nContact',
    'Review',
  ];

  // One Form per input step (steps 1-3). Step 4 is only the review.
  final List<GlobalKey<FormState>> _formKeys =
  List.generate(3, (_) => GlobalKey<FormState>());
  final ImagePicker _picker = ImagePicker();

  int _step = 0;
  bool _publishing = false;

  // Step 1
  final List<String> _photos = [];
  String _animalType = 'Dog';
  String? _sex;
  final _name = TextEditingController();
  final _age = TextEditingController();

  // Step 2
  final _description = TextEditingController();
  final _health = TextEditingController();
  final _reason = TextEditingController();

  // Step 3
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
    // Edit mode: ilagay ang dating laman
    _photos.addAll(pet.photos);
    _animalType = pet.animalType;
    _sex = pet.sex;
    _name.text = pet.name;
    _age.text = pet.age;
    _description.text = pet.description;
    _health.text = pet.healthInfo;
    _reason.text = pet.reasonForAdoption;
    // location ay "Barangay, City, Province"
    final parts = pet.location.split(', ');
    _barangay.text = parts.isNotEmpty ? parts[0] : '';
    _city.text = parts.length > 1 ? parts[1] : '';
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

  // ------------------------------------------------------------ Navigation

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goTo(int step) => setState(() => _step = step);

  void _next() {
    // validate() shows the red error text under every invalid field.
    final valid = _formKeys[_step].currentState!.validate();

    if (_step == 0 && _photos.isEmpty) {
      _snack('Please add at least one photo.');
      return;
    }
    if (!valid) return;

    _goTo(_step + 1);
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context); // leave the form, back to the Bulletin
    } else {
      _goTo(_step - 1);
    }
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
          photos: List.of(_photos),
          contactPerson: _contactPerson.text.trim(),
          contactPhone: _phone.text.trim(),
          contactEmail: _email.text.trim(),
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
          photos: List.of(_photos),
          contactPerson: _contactPerson.text.trim(),
          contactPhone: _phone.text.trim(),
          contactEmail: _email.text.trim(),
        );
      }
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            editing == null ? 'Pet published!' : 'Changes saved!',
            style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800),
          ),
          content: Text(
            editing == null
                ? '${_name.text.trim()} is now listed in the Adoption Bulletin.'
                : 'Your post for ${_name.text.trim()} was updated.',
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
    // Android Back button goes to the previous step instead of closing the form.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
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
                    Text(
                      widget.isEditing
                          ? 'Edit Pet Post'
                          : 'Post a Pet for Adoption',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildStepIndicator(),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: switch (_step) {
                      0 => _buildPetInfoStep(),
                      1 => _buildAboutStep(),
                      2 => _buildLocationStep(),
                      _ => _buildReviewStep(),
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Divider(color: Colors.grey.shade300, thickness: 1),
            ),
          );
        }

        final idx = i ~/ 2;
        final isCurrent = idx == _step;

        return SizedBox(
          width: 62,
          child: Column(
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
                _stepLabels[idx],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: idx <= _step ? kNavy : kHintGray,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildButtons() {
    if (_step == 0) {
      return Align(
        alignment: Alignment.centerRight,
        child: _outlineBtn('Next', _next),
      );
    }

    if (_step == 3) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _publishing ? null : _back,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kNavy,
                  side: const BorderSide(color: kNavy),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back to Edit'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _publishing ? null : _publish,
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
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _outlineBtn('Back', _back),
        _outlineBtn('Next', _next),
      ],
    );
  }

  // ---------------------------------------------------------------- Step 1

  Widget _buildPetInfoStep() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Pet Photos'),
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
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _photoThumb(i),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _title('Pet Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _name,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: _dec("Enter pet's name"),
            validator: (v) => _required(v, "Please enter the pet's name"),
          ),
          const SizedBox(height: 14),
          _title('Animal Type'),
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
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('Age'),
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
                    _title('Sex'),
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
                color: const Color(0xFFE6E9EF),
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

  // ---------------------------------------------------------------- Step 2

  Widget _buildAboutStep() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Description'),
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
          _title('Reason for Adoption'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _reason,
            maxLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Why does this pet need a new home?'),
            validator: (v) => _required(v, 'Please tell us why'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Step 3

  Widget _buildLocationStep() {
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
          _title('City / Municipality'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('e.g. Batangas City'),
            validator: (v) => _required(v, 'Please enter the city or municipality'),
          ),
          const SizedBox(height: 14),
          _title('Barangay'),
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
          _title('Contact Person'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contactPerson,
            textCapitalization: TextCapitalization.words,
            decoration: _dec("Enter contact person's full name"),
            validator: (v) => _required(v, 'Please enter the contact person'),
          ),
          const SizedBox(height: 14),
          _title('Phone Number'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _dec("Enter contact person's phone number"),
            validator: _validatePhone,
          ),
          const SizedBox(height: 14),
          _title('Email Address'),
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

  // ---------------------------------------------------------------- Step 4

  Widget _buildReviewStep() {
    final street = _street.text.trim();
    final health = _health.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Review Your Listing'),
        const SizedBox(height: 12),
        Container(
          height: 170,
          width: double.infinity,
          decoration: _cardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PetPhoto(
                path: _photos.first,
                fallback: const Center(
                  child: Icon(Icons.pets, size: 40, color: kHintGray),
                ),
              ),
              if (_photos.length > 1)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${_photos.length - 1} more',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _reviewRow(
                'Pet',
                '${_name.text.trim()}\n$_animalType · ${_age.text.trim()} · ${_sex ?? '-'}',
                0,
              ),
              _reviewRow('Description', _description.text.trim(), 1),
              _reviewRow(
                'Health Information',
                health.isEmpty ? 'No health information provided.' : health,
                1,
              ),
              _reviewRow('Reason for Adoption', _reason.text.trim(), 1),
              _reviewRow('Location', _location, 2),
              if (street.isNotEmpty) _reviewRow('Street / Landmark', street, 2),
              _reviewRow(
                'Contact Information',
                'Contact Person: ${_contactPerson.text.trim()}\n'
                    'Contact Number: ${_phone.text.trim()}\n'
                    'Email: ${_email.text.trim()}',
                2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your contact details stay hidden until an applicant passes '
              'admin screening.',
          style: TextStyle(fontSize: 12, color: kHintGray),
        ),
      ],
    );
  }

  Widget _reviewRow(String title, String value, int editStep) {
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
            onTap: () => _goTo(editStep),
            child: const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Text('Edit', style: TextStyle(fontSize: 11, color: kBlue)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Shared

  Widget _title(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 15,
      color: kNavy,
    ),
  );

  Widget _sectionHeading(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 18,
      color: kNavy,
    ),
  );

  Widget _outlineBtn(String label, VoidCallback onPressed) {
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
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
);
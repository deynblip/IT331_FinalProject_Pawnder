import 'package:flutter/material.dart';

import '../models/adoption_pet.dart';
import '../services/application_service.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import '../utils/responsive.dart';
import '../widgets/field_label.dart';

const String _kProvince = 'Batangas';

/// "Adoption Application": one scrolling form with a Submit button at the
/// bottom and a short confirmation before it is sent. Opened from the Apply
/// for Adoption button on the Adoption Details screen. Pops with `true` when
/// submitted.
class AdoptionApplicationScreen extends StatefulWidget {
  final AdoptionPet pet;

  const AdoptionApplicationScreen({super.key, required this.pet});

  @override
  State<AdoptionApplicationScreen> createState() =>
      _AdoptionApplicationScreenState();
}

class _AdoptionApplicationScreenState extends State<AdoptionApplicationScreen> {
  // One Form per section, so the first section with an error can be found.
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    3,
        (_) => GlobalKey<FormState>(),
  );

  // Used to scroll to a section (or the ID agreement) that needs fixing.
  final List<GlobalKey> _sectionKeys = List.generate(3, (_) => GlobalKey());
  final GlobalKey _idAgreementKey = GlobalKey();

  bool _submitting = false;
  bool _showIdError = false; // set after Submit is tapped without agreeing

  /// Required: the adopter agrees to show a valid ID in person.
  /// No ID is uploaded or stored in the app (Data Privacy Act, RA 10173).
  bool _agreesToShowId = false;

  // Personal Information
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  // Current Address
  final _city = TextEditingController();
  final _barangay = TextEditingController();
  final _street = TextEditingController();

  // Living Environment and Pet Ownership Experience
  final _home = TextEditingController();
  final _household = TextEditingController();
  final _previousPets = TextEditingController();
  final _care = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _phone,
      _email,
      _city,
      _barangay,
      _street,
      _home,
      _household,
      _previousPets,
      _care,
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

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      alignment: 0.05,
    );
  }

  /// Validates every section and the ID agreement. Shows the red error text
  /// under each invalid field and scrolls to the first thing to fix.
  bool _validateAll() {
    final results = _formKeys.map((k) => k.currentState!.validate()).toList();
    final firstInvalid = results.indexOf(false);
    if (firstInvalid != -1) {
      _scrollTo(_sectionKeys[firstInvalid]);
      _snack('Please complete the highlighted fields.');
      return false;
    }
    if (!_agreesToShowId) {
      setState(() => _showIdError = true);
      _scrollTo(_idAgreementKey);
      _snack('Please agree to present a valid ID during the meet-up or turnover.');
      return false;
    }
    return true;
  }

  /// Short confirmation instead of a full review step.
  Future<void> _confirmAndSubmit() async {
    if (!_validateAll()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Submit your application for ${widget.pet.name}?',
          style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '${_fullName.text.trim()}\n'
              '${_phone.text.trim()} · ${_email.text.trim()}\n'
              '$_location\n\n'
              'The admin and the pet owner will use these details to contact '
              'you. Please check that they are correct.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Submit',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _submit();
  }

  // ---------------------------------------------------------------- Submit

  String get _location =>
      '${_barangay.text.trim()}, ${_city.text.trim()}, $_kProvince';

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ApplicationService.submit(
        pet: widget.pet,
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        province: _kProvince,
        city: _city.text.trim(),
        barangay: _barangay.text.trim(),
        street: _street.text.trim(),
        homeEnvironment: _home.text.trim(),
        householdMembers: _household.text.trim(),
        previousPets: _previousPets.text.trim(),
        careExperience: _care.text.trim(),
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Application sent!',
            style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Your application for ${widget.pet.name} will be screened by an '
                'admin first. You can contact the pet owner once it passes '
                'screening.',
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

      Navigator.pop(context, true); // back to the Details screen
    } catch (_) {
      _snack('Could not send your application. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ------------------------------------------------------------ Validators

  String? _required(String? v, String message) =>
      (v ?? '').trim().isEmpty ? message : null;

  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'[\s\-]'), '');
    if (digits.isEmpty) return 'Please enter your phone number';
    if (!RegExp(r'^(09|\+639)\d{9}$').hasMatch(digits)) {
      return 'Enter a valid mobile number, e.g. 0993 456 7891';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Please enter your email address';
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
              padding: EdgeInsets.fromLTRB(pad - 8, 8, pad, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: kBlue),
                  ),
                  const Expanded(
                    child: Text(
                      'Adoption Application',
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
              padding: EdgeInsets.fromLTRB(pad + 40, 0, pad, 4),
              child: Text(
                'Applying for ${widget.pet.name}',
                style: const TextStyle(fontSize: 13, color: kHintGray),
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RequiredNote(),
                    const SizedBox(height: 12),
                    KeyedSubtree(
                      key: _sectionKeys[0],
                      child: _buildApplicantSection(),
                    ),
                    const SizedBox(height: 28),
                    KeyedSubtree(
                      key: _sectionKeys[1],
                      child: _buildAddressSection(),
                    ),
                    const SizedBox(height: 28),
                    KeyedSubtree(
                      key: _sectionKeys[2],
                      child: _buildExperienceSection(),
                    ),
                    const SizedBox(height: 16),
                    _buildIdAgreement(),
                    const SizedBox(height: 6),
                    const Text(
                      'Your application will be screened by an admin before '
                          'it is forwarded to the pet owner.',
                      style: TextStyle(fontSize: 12, color: kHintGray),
                    ),
                  ],
                ),
              ),
            ),

            // Submit button, always visible at the bottom.
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
                  onPressed: _submitting ? null : _confirmAndSubmit,
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
                    'Submit Application',
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

  /// Required agreement, shown at the end of the form.
  Widget _buildIdAgreement() {
    return Container(
      key: _idAgreementKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: _agreesToShowId,
            onChanged: (v) => setState(() {
              _agreesToShowId = v ?? false;
              if (_agreesToShowId) _showIdError = false;
            }),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: kBlue,
            title: const Text(
              'I agree to present a valid ID during the in-person meet-up or '
                  'turnover.',
              style: TextStyle(color: kNavy, fontSize: 14),
            ),
            subtitle: const Text(
              'Required. Your ID is checked in person and is not uploaded or '
                  'stored in the app.',
              style: TextStyle(color: kHintGray, fontSize: 12),
            ),
          ),
          if (_showIdError)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Please agree before submitting.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------- Personal Information

  Widget _buildApplicantSection() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Personal Information'),
          const SizedBox(height: 12),
          _title('Full Name (LN, FN, MI)', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fullName,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('e.g. Dela Cruz, Juan, J.'),
            validator: (v) => _required(v, 'Please enter your full name'),
          ),
          const SizedBox(height: 14),
          _title('Phone Number', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _dec('Enter your phone number'),
            validator: _validatePhone,
          ),
          const SizedBox(height: 14),
          _title('Email Address', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Enter your email address'),
            validator: _validateEmail,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- Current Address

  Widget _buildAddressSection() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Current Address'),
          const SizedBox(height: 12),
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
            validator: (v) =>
                _required(v, 'Please enter your city or municipality'),
          ),
          const SizedBox(height: 14),
          _title('Barangay', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _barangay,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('e.g. Alangilan'),
            validator: (v) => _required(v, 'Please enter your barangay'),
          ),
          const SizedBox(height: 14),
          _title('Street / Landmark (optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _street,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Enter street or nearby landmark'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------- Living Environment and Experience

  Widget _buildExperienceSection() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Living Environment'),
          const SizedBox(height: 12),
          _title('Home Environment', required: true),
          const Text(
            'Describe the space where the pet will stay.',
            style: TextStyle(fontSize: 12, color: kHintGray),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _home,
            maxLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Describe your home environment...'),
            validator: (v) => _required(v, 'Please describe your home'),
          ),
          const SizedBox(height: 14),
          _title('Household Members', required: true),
          const Text(
            'Who will be living with the adopted pet?',
            style: TextStyle(fontSize: 12, color: kHintGray),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _household,
            maxLines: 2,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Enter your answer'),
            validator: (v) => _required(v, 'Please answer this question'),
          ),
          const SizedBox(height: 14),
          _sectionHeading('Pet Ownership Experience'),
          const SizedBox(height: 12),
          _title('Previous or Current Pets', required: true),
          const Text(
            'List the pets you currently own or have cared for.',
            style: TextStyle(fontSize: 12, color: kHintGray),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _previousPets,
            maxLines: 2,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Enter your answer'),
            validator: (v) => _required(v, 'Please answer this question'),
          ),
          const SizedBox(height: 14),
          _title('Pet Care Experience', required: true),
          const Text(
            'Briefly describe your experience in caring for animals.',
            style: TextStyle(fontSize: 12, color: kHintGray),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _care,
            maxLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Enter your answer'),
            validator: (v) => _required(v, 'Please answer this question'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Shared

  /// Field label. Required fields get a red *.
  Widget _title(String text, {bool required = false}) =>
      FieldLabel(text, required: required);

  Widget _sectionHeading(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 18,
      color: kNavy,
    ),
  );
}

// ------------------------------------------------------- Top-level helpers
// (Same look as the Post a Pet form. They are private to each file in Dart,
// so they are repeated here.)

OutlineInputBorder _border(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: color),
);

InputDecoration _dec(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: kHintGray),
  filled: true,
  fillColor: Colors.white,
  counterText: '',
  // hide the "0/30" counter
  border: _border(Colors.grey.shade300),
  enabledBorder: _border(Colors.grey.shade300),
  disabledBorder: _border(Colors.grey.shade300),
  focusedBorder: _border(kBlue),
  errorBorder: _border(Colors.red),
  focusedErrorBorder: _border(Colors.red),
);
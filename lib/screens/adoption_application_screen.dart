import 'package:flutter/material.dart';

import '../models/adoption_pet.dart';
import '../services/application_service.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import '../utils/responsive.dart';

const String _kProvince = 'Batangas';

/// "Adoption Application" form (4 steps). Opened from the Apply for Adoption
/// button on the Adoption Details screen. Pops with `true` when submitted.
class AdoptionApplicationScreen extends StatefulWidget {
  final AdoptionPet pet;

  const AdoptionApplicationScreen({super.key, required this.pet});

  @override
  State<AdoptionApplicationScreen> createState() =>
      _AdoptionApplicationScreenState();
}

class _AdoptionApplicationScreenState extends State<AdoptionApplicationScreen> {
  static const List<String> _stepLabels = [
    'Applicant\nInformation',
    'Address',
    'Experience/\nEnvironment',
    'Review',
  ];

  // One Form per input step (steps 1-3). Step 4 is only the review.
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    3,
        (_) => GlobalKey<FormState>(),
  );

  int _step = 0;
  bool _submitting = false;

  /// Required: the adopter agrees to show a valid ID in person.
  /// No ID is uploaded or stored in the app (Data Privacy Act, RA 10173).
  bool _agreesToShowId = false;

  // Step 1
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  // Step 2
  final _city = TextEditingController();
  final _barangay = TextEditingController();
  final _street = TextEditingController();

  // Step 3
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

  // ------------------------------------------------------------ Navigation

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goTo(int step) => setState(() => _step = step);

  void _next() {
    // validate() shows the red error text under every invalid field.
    if (!_formKeys[_step].currentState!.validate()) return;
    _goTo(_step + 1);
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context); // leave the form, back to Details
    } else {
      _goTo(_step - 1);
    }
  }

  // ---------------------------------------------------------------- Submit

  String get _location =>
      '${_barangay.text.trim()}, ${_city.text.trim()}, $_kProvince';

  Future<void> _submit() async {
    if (!_agreesToShowId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to present a valid ID during the meet-up or turnover.',
          ),
        ),
      );
      return;
    }
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
    // Android Back button goes to the previous step instead of closing the form.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: kCream,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _back,
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
                Padding(
                  padding: const EdgeInsets.only(left: 48, bottom: 8),
                  child: Text(
                    'Applying for ${widget.pet.name}',
                    style: const TextStyle(fontSize: 13, color: kHintGray),
                  ),
                ),
                _buildStepIndicator(),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: switch (_step) {
                      0 => _buildApplicantStep(),
                      1 => _buildAddressStep(),
                      2 => _buildExperienceStep(),
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
                onPressed: _submitting ? null : _back,
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
                  'Submit',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_outlineBtn('Back', _back), _outlineBtn('Next', _next)],
    );
  }

  // ---------------------------------------------------------------- Step 1

  Widget _buildApplicantStep() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Personal Information'),
          const SizedBox(height: 12),
          _title('Full Name (LN, FN, MI)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fullName,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('e.g. Dela Cruz, Juan, J.'),
            validator: (v) => _required(v, 'Please enter your full name'),
          ),
          const SizedBox(height: 14),
          _title('Phone Number'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _dec('Enter your phone number'),
            validator: _validatePhone,
          ),
          const SizedBox(height: 14),
          _title('Email Address'),
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

  // ---------------------------------------------------------------- Step 2

  Widget _buildAddressStep() {
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
          _title('City / Municipality'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('e.g. Batangas City'),
            validator: (v) =>
                _required(v, 'Please enter your city or municipality'),
          ),
          const SizedBox(height: 14),
          _title('Barangay'),
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

  // ---------------------------------------------------------------- Step 3

  Widget _buildExperienceStep() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Living Environment'),
          const SizedBox(height: 12),
          _title('Home Environment'),
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
          _title('Household Members'),
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
          _title('Previous or Current Pets'),
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
          _title('Pet Care Experience'),
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

  // ---------------------------------------------------------------- Step 4

  Widget _buildReviewStep() {
    final street = _street.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Review Your Application'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _reviewRow('Applying for', widget.pet.name, null),
              _reviewRow(
                'Applicant',
                '${_fullName.text.trim()}\n'
                    '${_phone.text.trim()}\n'
                    '${_email.text.trim()}',
                0,
              ),
              _reviewRow('Location', _location, 1),
              if (street.isNotEmpty) _reviewRow('Street / Landmark', street, 1),
              _reviewRow('Home Environment', _home.text.trim(), 2),
              _reviewRow('Household Members', _household.text.trim(), 2),
              _reviewRow(
                'Previous or Current Pets',
                _previousPets.text.trim(),
                2,
              ),
              _reviewRow('Pet Care Experience', _care.text.trim(), 2),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _agreesToShowId,
          onChanged: (v) => setState(() => _agreesToShowId = v ?? false),
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
        const SizedBox(height: 6),
        const Text(
          'Your application will be screened by an admin before it is '
              'forwarded to the pet owner.',
          style: TextStyle(fontSize: 12, color: kHintGray),
        ),
      ],
    );
  }

  // editStep == null means the row has no Edit link.
  Widget _reviewRow(String title, String value, int? editStep) {
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
          if (editStep != null)
            GestureDetector(
              onTap: () => _goTo(editStep),
              child: const Padding(
                padding: EdgeInsets.only(left: 12, bottom: 8),
                child: Text(
                  'Edit',
                  style: TextStyle(fontSize: 11, color: kBlue),
                ),
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
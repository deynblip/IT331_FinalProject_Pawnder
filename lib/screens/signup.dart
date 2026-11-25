import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../utils/app_colors.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/rescuer_form.dart';

import 'login.dart';
import 'verify_email.dart';

// ===============================
// SIGN UP PAGE
// ===============================

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _agreedToTerms = false;

  AccountType _accountType = AccountType.community;
  final RescuerFormControllers _rescuer = RescuerFormControllers();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    _rescuer.dispose();
    super.dispose();
  }

  // SHOW TERMS AND CONDITIONS POPUP
  Future<void> _showTermsDialog() async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Terms & Conditions',
            style: TextStyle(
              color: kNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Updated: November 2026',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Welcome to Pawnder! By accessing or using the application, you agree to follow these Terms & Conditions. Please read them carefully before using the application.',
                    style: TextStyle(fontSize: 13),
                  ),

                  _termsSection(
                    '1. Acceptance of Terms',
                    'By creating an account or using Pawnder, users acknowledge that they have read and agreed to these Terms & Conditions.',
                  ),

                  _termsSection(
                    '2. User Responsibilities',
                    'Users agree to:',
                    bullets: [
                      'Provide accurate and truthful information.',
                      'Use the application responsibly and respectfully.',
                      'Avoid submitting false, misleading, or duplicate reports.',
                      'Respect the privacy and safety of other users.',
                    ],
                  ),

                  _termsSection(
                    '3. Stray Animal Reporting',
                    'Users should:',
                    bullets: [
                      'Provide accurate animal descriptions and locations.',
                      'Submit photos that correspond to the reported animal.',
                      'Avoid approaching or disturbing unfamiliar animals just to take photos.',
                      'Understand that submitting a report does not guarantee immediate rescue or assistance.',
                    ],
                  ),

                  _termsSection(
                    '4. Location and Map Information',
                    'Users should provide accurate location information and avoid reporting animals in private or unauthorized locations. Map information may not always reflect the animal’s current location.',
                  ),

                  _termsSection(
                    '5. Pet Adoption',
                    'Users must provide honest information when completing adoption questionnaires. Submitting an application does not guarantee approval. Adoption decisions are subject to review and confirmation by the responsible adoption partner or authorized personnel. Adopters are expected to provide proper care, protection, and a safe environment for their pets.',
                  ),

                  _termsSection(
                    '6. Prohibited Activities',
                    'Users must not:',
                    bullets: [
                      'Submit false or misleading information.',
                      'Upload inappropriate or unrelated images.',
                      'Harass, threaten, or harm other users or animals.',
                      'Misuse location information.',
                      'Use the application for unrelated or unauthorized purposes.',
                    ],
                  ),

                  _termsSection(
                    '7. Accuracy and Availability',
                    'Pawnder does not guarantee that reports, animal locations, or adoption listings will always be accurate, complete, or updated.',
                  ),

                  _termsSection(
                    '8. Changes to Terms',
                    'Pawnder may update these Terms & Conditions when necessary. Users are encouraged to review them regularly.',
                  ),

                  _termsSection(
                    '9. Contact Us',
                    'For questions or concerns, users may contact the Pawnder development team through the Contact Us section of the application.',
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'By continuing to use Pawnder, you acknowledge and agree to these Terms & Conditions.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kNavy,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Center(
                    child: Text(
                      'Pawnder – Every Paw Deserves Help.',
                      style: TextStyle(
                        color: kBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Decline',
                style: TextStyle(color: Colors.grey),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('I Agree'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (accepted == true) {
      setState(() {
        _agreedToTerms = true;
      });
    }
  }

  // TERMS SECTION HELPER
  Widget _termsSection(
      String title,
      String description, {
        List<String> bullets = const [],
      }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kNavy,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            description,
            style: const TextStyle(fontSize: 13),
          ),

          ...bullets.map(
                (item) => Padding(
              padding: const EdgeInsets.only(top: 5, left: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13),
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

  // SIGN UP FUNCTION
  bool _busy = false;

  Future<void> _signUp() async {
    if (_busy) return;

    if (!_agreedToTerms) {
      showMessage(
        context,
        'Please read and agree to the Terms & Conditions.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();

    final bool applying = _accountType == AccountType.professional;

    bool needsCode = false; // true = the user must enter the emailed code
    setState(() => _busy = true);
    try {
      needsCode = await AuthService.signUp(
        name: nameController.text,
        email: email,
        password: passwordController.text,
        rescuerApplication: applying
            ? {
          'organization': _rescuer.organization.text.trim(),
          'role_in_org': _rescuer.roleInOrg.text.trim(),
          'contact_person': _rescuer.contactPerson.text.trim(),
          'contact_number': _rescuer.contactNumber.text.trim(),
          'official_page': _rescuer.officialPage.text.trim(),
        }
            : null,
      );
    } on AuthFailure catch (e) {
      if (mounted) showMessage(context, e.message);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!mounted) return;

    // Confirm email is ON: go to the Enter code screen.
    if (needsCode) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyEmailPage(
            email: email,
            applying: applying,
          ),
        ),
      );
      return;
    }

    showMessage(
      context,
      applying
          ? 'Account created! Your rescuer application is pending '
          'verification. Please log in.'
          : 'Account created! Please log in.',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      panelTopFraction: 0.37,
      curveOnRight: false,
      title: 'Create An Account',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthField(
                label: 'Name',
                controller: nameController,
                validator: validateName,
              ),

              const SizedBox(height: 14),

              AuthField(
                label: 'Email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
              ),

              const SizedBox(height: 14),

              AuthField(
                label: 'Password',
                controller: passwordController,
                obscure: true,
                validator: validatePassword,
              ),

              const SizedBox(height: 14),

              // ACCOUNT TYPE: Community Member / Professional Rescuer
              AccountTypeSelector(
                value: _accountType,
                onChanged: (v) => setState(() => _accountType = v),
              ),

              if (_accountType == AccountType.professional) ...[
                const SizedBox(height: 14),
                const RescuerPendingNote(),
                const SizedBox(height: 14),
                RescuerFormFields(controllers: _rescuer),
              ],

              const SizedBox(height: 14),

              // TERMS AND CONDITIONS CHECKBOX
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: kBlue,
                    onChanged: (value) {
                      if (value == false) {
                        setState(() {
                          _agreedToTerms = false;
                        });
                      } else {
                        _showTermsDialog();
                      }
                    },
                  ),

                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'I agree to the ',
                          style: TextStyle(fontSize: 12),
                        ),

                        GestureDetector(
                          onTap: _showTermsDialog,
                          child: const Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              color: kBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              AuthButton(
                text: _busy ? 'Creating account...' : 'Sign Up',
                onPressed: _signUp,
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        AuthLink(
          text: 'Already have an account? Log in here.',
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}
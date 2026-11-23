import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kNavy,
        elevation: 0,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: kNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF0E2D6),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Updated: November 2026',
              style: TextStyle(
                color: kHintGray,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Welcome to Pawnder!',
              style: TextStyle(
                color: kNavy,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            _bodyText(
              'By accessing or using the application, you agree to follow '
                  'these Terms & Conditions. Please read them carefully before '
                  'using the application.',
            ),

            const SizedBox(height: 24),

            _section(
              '1. Acceptance of Terms',
              'By creating an account or using Pawnder, users acknowledge '
                  'that they have read and agreed to these Terms & Conditions.',
            ),

            _section(
              '2. User Responsibilities',
              'Users are expected to:',
              bullets: [
                'Provide accurate and truthful information.',
                'Use the application responsibly and respectfully.',
                'Avoid submitting false, misleading, or duplicate reports.',
                'Respect the privacy and safety of other users.',
              ],
            ),

            _section(
              '3. Stray Animal Reporting',
              '',
              bullets: [
                'Users should provide accurate descriptions and location details when submitting reports.',
                'Photos uploaded should correspond to the reported animal.',
                'Users should avoid approaching or disturbing unfamiliar animals when taking photographs.',
                'Submitting a report does not guarantee immediate rescue or assistance.',
              ],
            ),

            _section(
              '4. Location and Map Information',
              '',
              bullets: [
                'Location information should be accurate to help identify reported animals.',
                'Users should avoid sharing private or unauthorized locations.',
                "Map information is provided as a reference and may not always reflect the animal's current location.",
              ],
            ),

            _section(
              '5. Pet Adoption',
              '',
              bullets: [
                'Users interested in adoption should provide honest information when completing the adoption questionnaire.',
                'Submitting an application does not guarantee adoption approval.',
                'Adoption decisions are subject to review and confirmation by the responsible adoption partner or authorized personnel.',
                'Adopters are expected to provide proper care, protection, and a safe environment for their adopted animals.',
              ],
            ),

            _section(
              '6. Prohibited Activities',
              'Users must not:',
              bullets: [
                'Submit false or misleading information.',
                'Upload inappropriate or unrelated images.',
                'Use the application to harass, threaten, or harm others.',
                'Misuse location information.',
                'Use Pawnder for activities unrelated to its intended purpose.',
              ],
            ),

            _section(
              '7. Accuracy and Availability',
              'Pawnder aims to provide useful and accessible information. '
                  'However, the application does not guarantee that all submitted '
                  'reports, animal locations, or adoption listings will always '
                  'be accurate, complete, or updated.',
            ),

            _section(
              '8. Changes to the Terms',
              'Pawnder reserves the right to update these Terms & Conditions '
                  'when necessary. Users are encouraged to review this page '
                  'regularly for any changes.',
            ),

            _section(
              '9. Contact Us',
              'For questions, concerns, or clarifications regarding these '
                  'Terms & Conditions, users may contact the Pawnder '
                  'development team through the Contact Us section.',
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'By continuing to use Pawnder, you acknowledge and agree '
                    'to these Terms & Conditions.',
                style: TextStyle(
                  color: kNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Center(
              child: Text(
                'Pawnder – Every Paw Deserves Help.',
                style: TextStyle(
                  color: kBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // SECTION
  Widget _section(
      String title,
      String description, {
        List<String> bullets = const [],
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kNavy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            _bodyText(description),
          ],

          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...bullets.map((item) => _bulletItem(item)),
          ],
        ],
      ),
    );
  }

  // BODY TEXT
  Widget _bodyText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 13,
        height: 1.6,
      ),
    );
  }

  // BULLET ITEM
  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              color: kBlue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _bodyText(text),
          ),
        ],
      ),
    );
  }
}
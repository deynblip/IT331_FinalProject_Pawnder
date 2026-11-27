import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kSurfaceWhite,
        foregroundColor: kNavy,
        elevation: 0,
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: kNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: kCardBorder,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: November 2026',
              style: TextStyle(
                color: kHintGray,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Your Privacy Matters',
              style: TextStyle(
                color: kNavy,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            _bodyText(
              'Pawnder helps the community report stray animals and find '
                  'homes for pets. This Privacy Policy explains what information '
                  'we collect, how we use it, and the choices you have. By using '
                  'Pawnder, you agree to the practices described here.',
            ),

            const SizedBox(height: 24),

            _section(
              '1. Information We Collect',
              'Depending on how you use the application, we may collect:',
              bullets: [
                'Account information: your name, email address, and password.',
                'Profile photo: if you choose to add one.',
                'Stray reports: photos of the animal, animal type, urgency '
                    'level, description, and the pinned location or address.',
                'Adoption posts: the pet\'s details and photos, your address '
                    '(barangay and city), and your contact person, phone '
                    'number, and email address.',
                'Adoption applications: your full name, contact details, '
                    'address, home environment, household members, and '
                    'experience in caring for pets.',
              ],
            ),

            _section(
              '2. How We Use Your Information',
              'We use your information to:',
              bullets: [
                'Create and manage your account.',
                'Show stray reports on the Reports list and the map so '
                    'rescuers and the community can respond.',
                'Publish pets in the Adoption Board.',
                'Review adoption applications and help pet owners make a '
                    'final decision.',
                'Send updates about your reports, posts, and applications.',
                'Keep Pawnder safe by removing false, harmful, or '
                    'inappropriate content.',
              ],
            ),

            _section(
              '3. Camera, Photos, and Location',
              'Pawnder may ask for permission to use your camera, photo '
                  'gallery, and device location.',
              bullets: [
                'Camera and gallery are used only when you add a photo to a '
                    'report, a pet post, or your profile.',
                'Location is used only when you tap "Use current location" '
                    'or pin a spot on the map to show where an animal was '
                    'seen.',
                'You can refuse or turn off these permissions in your device '
                    'settings. Some features may not work without them, but '
                    'you can still tap the map to pin a location.',
              ],
            ),

            _section(
              '4. Who Can See Your Information',
              '',
              bullets: [
                'Stray reports, including the photo, description, and '
                    'location, are visible to other Pawnder users so that '
                    'rescuers can find the animal.',
                'Adoption posts are visible in the Adoption Board. Your '
                    'contact person, phone number, and email address stay '
                    'hidden until an applicant passes admin screening.',
                'Adoption applications are first reviewed by the Pawnder '
                    'administrators. If an application passes screening, it '
                    'is forwarded to the pet\'s owner, who can then see the '
                    'applicant\'s details to make the final decision.',
                'Your password is never shown to other users.',
              ],
            ),

            _section(
              '5. Sharing of Information',
              'We do not sell your personal information. We share it only as '
                  'described in this policy, or when it is required by law or '
                  'needed to protect the safety of people and animals.',
            ),

            _section(
              '6. Data Storage and Security',
              'We take reasonable steps to protect your information from '
                  'loss, misuse, and unauthorized access. However, no '
                  'application or online service can be completely secure, so '
                  'we cannot guarantee absolute security. Please keep your '
                  'password private and log out when using a shared device.',
            ),

            _section(
              '7. Data Retention',
              'We keep your information for as long as your account is '
                  'active or as needed to run Pawnder. You can remove your '
                  'own adoption posts at any time from My Adoption Posts. You '
                  'may also ask us to delete your account and related data.',
            ),

            _section(
              '8. Your Rights',
              'Under the Data Privacy Act of 2012 (Republic Act No. 10173), '
                  'you have the right to:',
              bullets: [
                'Be informed about how your personal data is collected and '
                    'used.',
                'Access the personal data we hold about you.',
                'Correct inaccurate or outdated information.',
                'Object to the processing of your data, or ask us to '
                    'suspend, block, or delete it.',
                'File a complaint with the National Privacy Commission if '
                    'you believe your data was mishandled.',
              ],
            ),

            _section(
              '9. Children\'s Privacy',
              'Pawnder is open to everyone who wants to help animals. '
                  'Younger users are encouraged to use the application with '
                  'the guidance of a parent or guardian, especially when '
                  'sharing contact details or an address. If you believe a '
                  'child has given us personal information without '
                  'permission, please contact us so we can remove it.',
            ),

            _section(
              '10. Changes to This Policy',
              'We may update this Privacy Policy when needed. The "Last '
                  'Updated" date at the top shows when it was last changed. '
                  'We encourage you to review this page regularly.',
            ),

            _section(
              '11. Contact Us',
              'For questions or requests about your personal information, '
                  'you may contact the Pawnder development team at '
                  'pawnder.appv1@gmail.com.',
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'By continuing to use Pawnder, you acknowledge that you have '
                    'read and understood this Privacy Policy.',
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
            style: TextStyle(
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
        color: kHintGray,
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
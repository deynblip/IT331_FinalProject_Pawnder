import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/theme_controller.dart';
import '../../utils/responsive.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kSurfaceWhite,
        foregroundColor: kNavy,
        elevation: 0,
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: kNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: kCardBorder,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INTRODUCTION
            Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: kNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find answers to common questions and learn how to use Pawnder.',
              style: TextStyle(
                fontSize: 14,
                color: kHintGray,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            // 1. FREQUENTLY ASKED QUESTIONS
            _sectionTitle('1. Frequently Asked Questions (FAQs)'),

            _subsectionTitle('General Questions'),
            _faqItem(
              'What is Pawnder?',
              'Pawnder is an application designed to help users report stray '
                  'animals, locate nearby reports, and support animal adoption.',
            ),
            _faqItem(
              'Who can use Pawnder?',
              'Anyone with a registered Pawnder account can use the '
                  "application's available features.",
            ),

            _subsectionTitle('Reporting Questions'),
            _faqItem(
              'How do I report a stray animal?',
              'Navigate to the Report a Stray section, provide the required '
                  'information, upload a photo if available, and submit your report.',
            ),
            _faqItem(
              'Do I need to upload a photo?',
              'Uploading a photo is encouraged because it helps other users '
                  'identify the reported animal.',
            ),
            _faqItem(
              'Can I report an injured stray animal?',
              'Yes. Include the animal’s condition and location in your report '
                  'so that appropriate assistance can be considered.',
            ),

            _subsectionTitle('Map Questions'),
            _faqItem(
              'How can I view nearby stray animal reports?',
              'Open the Map section to view reported stray animals and their '
                  'indicated locations.',
            ),

            const SizedBox(height: 28),

            // 2. REPORTING GUIDELINES
            _sectionTitle('2. Reporting Guidelines'),
            Text(
              'Before submitting a report, please follow these guidelines:',
              style: TextStyle(
                fontSize: 14,
                color: kNavy,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            _guidelineItem(
              '1',
              'Provide Accurate Information',
              'Enter the correct location and relevant details about the stray animal.',
            ),
            _guidelineItem(
              '2',
              'Upload Clear Photos',
              'Submit a clear photo of the animal whenever possible.',
            ),
            _guidelineItem(
              '3',
              'Describe the Animal',
              'Include details such as the animal type, color, approximate size, '
                  'and noticeable characteristics.',
            ),
            _guidelineItem(
              '4',
              'Indicate Its Condition',
              'Mention whether the animal appears healthy, injured, sick, or '
                  'in need of immediate assistance.',
            ),
            _guidelineItem(
              '5',
              'Verify Your Report',
              'Review the information before submitting to avoid incorrect '
                  'or duplicate reports.',
            ),

            const SizedBox(height: 16),

            _reminderCard(
              'Important Reminder',
              'Always prioritize your safety. Do not approach or handle '
                  'unfamiliar or aggressive animals. Observe from a safe distance.',
            ),

            const SizedBox(height: 28),

            // 3. ADOPTION ASSISTANCE
            _sectionTitle('3. Adoption Assistance'),
            Text(
              'Interested in adopting a pet? Here are some things to know.',
              style: TextStyle(
                fontSize: 14,
                color: kNavy,
                height: 1.5,
              ),
            ),

            _subsectionTitle('Before Adopting'),
            _bulletItem(
              'Make sure you are ready for the responsibility of caring for an animal.',
            ),
            _bulletItem(
              'Consider your time, living arrangements, and ability to provide proper care.',
            ),
            _bulletItem(
              'Prepare the necessary supplies, food, and a safe environment.',
            ),

            _subsectionTitle('Adoption Process'),
            _numberedItem(
              '1',
              'Browse the available animals in the Adoption section.',
            ),
            _numberedItem(
              '2',
              'Select an animal you are interested in adopting.',
            ),
            _numberedItem(
              '3',
              'Review its available information and details.',
            ),
            _numberedItem(
              '4',
              'Follow the provided adoption application or contact procedure.',
            ),
            _numberedItem(
              '5',
              'Coordinate with the responsible rescuer or adoption partner.',
            ),
            _numberedItem(
              '6',
              'Wait for confirmation and further adoption instructions.',
            ),

            _subsectionTitle('Responsible Pet Ownership'),
            _bulletItem('Provide sufficient food and clean water.'),
            _bulletItem(
              'Schedule regular veterinary checkups and vaccinations.',
            ),
            _bulletItem('Maintain proper hygiene and grooming.'),
            _bulletItem(
              'Give your pet a safe and comfortable environment.',
            ),
            _bulletItem('Provide attention, care, and affection.'),

            const SizedBox(height: 16),

            _reminderCard(
              'Remember',
              'Adoption is a long-term commitment. Every animal deserves '
                  'a safe, caring, and responsible home.',
            ),

            const SizedBox(height: 28),

            // 4. CONTACT US
            _sectionTitle('4. Contact Us'),
            Text(
              "We're here to help!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If you have questions, concerns, or suggestions regarding '
                  'Pawnder, you can reach our team through the following channels.',
              style: TextStyle(
                fontSize: 14,
                color: kHintGray,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            _contactItem(
              Icons.email_outlined,
              'Email Support',
              'For inquiries and assistance',
              'pawnder.appv1@gmail.com',
            ),
            _contactItem(
              Icons.feedback_outlined,
              'Send Feedback',
              'Share suggestions to improve Pawnder',
              null,
            ),
            _contactItem(
              Icons.bug_report_outlined,
              'Report an Issue',
              'Let us know about technical problems',
              null,
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                'Pawnder • Every Paw Deserves Help',
                style: TextStyle(
                  fontSize: 12,
                  color: kHintGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // SECTION TITLE
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: kNavy,
        ),
      ),
    );
  }

  // SUBSECTION TITLE
  Widget _subsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: kBlue,
        ),
      ),
    );
  }

  // FAQ ITEM
  Widget _faqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCardBorder),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: kBlue,
        collapsedIconColor: kNavy,
        title: Text(
          question,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kNavy,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: kHintGray,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // REPORTING GUIDELINE ITEM
  Widget _guidelineItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: kBlue.withValues(alpha: 0.12),
            child: Text(
              number,
              style: TextStyle(
                color: kNavy,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: kHintGray,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // BULLET ITEM
  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              color: kBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: kHintGray,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NUMBERED ITEM
  Widget _numberedItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number.',
            style: const TextStyle(
              color: kBlue,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: kHintGray,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // REMINDER CARD
  // Soft yellow in light mode; warm dark card in dark mode.
  Widget _reminderCard(String title, String message) {
    final Color bg = isDarkMode ? kPeach : const Color(0xFFFFF8E7);
    final Color border = isDarkMode ? kCardBorder : const Color(0xFFF3E2B7);
    final Color iconColor = isDarkMode ? kOrangeSoft : const Color(0xFF9A6B16);
    final Color titleColor = isDarkMode ? kNavy : const Color(0xFF805A13);
    final Color textColor = isDarkMode ? kHintGray : const Color(0xFF765D32);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: iconColor,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // CONTACT ITEM
  Widget _contactItem(
      IconData icon,
      String title,
      String description,
      String? detail,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: kBlue.withValues(alpha: 0.12),
            child: Icon(icon, color: kNavy, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: kHintGray,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
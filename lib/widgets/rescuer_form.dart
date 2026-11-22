import 'package:flutter/material.dart';

import '../models/rescuer_application.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import 'auth_widgets.dart';

enum AccountType { community, professional }

/// "Community Member" / "Professional Rescuer" choice for Sign Up.
class AccountTypeSelector extends StatelessWidget {
  final AccountType value;
  final ValueChanged<AccountType> onChanged;

  const AccountTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Widget _option(AccountType type, IconData icon, String label) {
    final selected = value == type;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFE8D6) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? kBlue : const Color(0xFFF5DEC8),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? kBlue : kHintGray, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? kNavy : kHintGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Account Type',
            style: TextStyle(color: kHintGray, fontSize: 12),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _option(AccountType.community, Icons.people_outline,
                'Community Member'),
            const SizedBox(width: 10),
            _option(AccountType.professional, Icons.verified_user_outlined,
                'Professional Rescuer'),
          ],
        ),
      ],
    );
  }
}

/// Small info box: choosing "Professional Rescuer" gives no permissions yet.
class RescuerPendingNote extends StatelessWidget {
  const RescuerPendingNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: kBlue, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your account starts as a regular account. Rescuer permissions '
                  'unlock only after an admin verifies your organization. '
                  'No ID or document is needed.',
              style: TextStyle(color: kNavy, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Holds the text of the rescuer form (used by Sign Up and by Profile).
class RescuerFormControllers {
  final TextEditingController organization = TextEditingController();
  final TextEditingController roleInOrg = TextEditingController();
  final TextEditingController contactPerson = TextEditingController();
  final TextEditingController contactNumber = TextEditingController();
  final TextEditingController officialPage = TextEditingController();

  void prefill(RescuerApplication a) {
    organization.text = a.organization;
    roleInOrg.text = a.roleInOrg;
    contactPerson.text = a.contactPerson;
    contactNumber.text = a.contactNumber;
    officialPage.text = a.officialPage;
  }

  void dispose() {
    organization.dispose();
    roleInOrg.dispose();
    contactPerson.dispose();
    contactNumber.dispose();
    officialPage.dispose();
  }
}

/// The five rescuer fields. Must be placed inside a Form.
class RescuerFormFields extends StatelessWidget {
  final RescuerFormControllers controllers;

  const RescuerFormFields({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthField(
          label: 'Organization Name',
          controller: controllers.organization,
          validator: requiredField('Please enter your organization'),
        ),
        const SizedBox(height: 14),
        AuthField(
          label: 'Your Role in the Organization',
          controller: controllers.roleInOrg,
          validator: requiredField('Please enter your role'),
        ),
        const SizedBox(height: 14),
        AuthField(
          label: 'Contact Person',
          controller: controllers.contactPerson,
          validator: requiredField('Please enter a contact person'),
        ),
        const SizedBox(height: 14),
        AuthField(
          label: 'Contact Number',
          controller: controllers.contactNumber,
          keyboardType: TextInputType.phone,
          validator: validateContactNumber,
        ),
        const SizedBox(height: 14),
        AuthField(
          label: "Organization's Official Facebook Page or Website",
          controller: controllers.officialPage,
          keyboardType: TextInputType.url,
          validator: validateOfficialPage,
        ),
      ],
    );
  }
}
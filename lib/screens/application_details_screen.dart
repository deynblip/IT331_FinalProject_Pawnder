import 'package:flutter/material.dart';

import '../models/adoption_application.dart';
import '../services/adoption_service.dart';
import '../utils/app_colors.dart';
import '../utils/application_style.dart';
import '../widgets/adopt_pet_photo.dart';
import '../widgets/status_chip.dart';

class ApplicationDetailsScreen extends StatelessWidget {
  final AdoptionApplication application;

  const ApplicationDetailsScreen({super.key, required this.application});

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        color: kNavy,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kNavy,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.trim().isEmpty ? '—' : value,
          style: const TextStyle(color: kNavy, fontSize: 15),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final a = application;
    final pet = AdoptionService.byId(a.petId);
    final photo = pet?.coverPhoto;
    final color = applicationStatusColor(a.status);

    final placeholder = Container(
      color: const Color(0xFFE6E9EF),
      child: const Center(
        child: Icon(Icons.pets, size: 36, color: Color(0xFF8A8F98)),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: kBlue),
                  ),
                  const Expanded(
                    child: Text(
                      'Application Details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Pet summary
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: photo == null
                                ? placeholder
                                : PetPhoto(path: photo, fallback: placeholder),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.petName,
                                style: const TextStyle(
                                  color: kNavy,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (pet != null)
                                Text(
                                  '${pet.animalType}  ·  ${pet.summary}',
                                  style: const TextStyle(color: kHintGray),
                                ),
                              const SizedBox(height: 8),
                              StatusChip(
                                label: a.status.label,
                                color: color,
                                outlined: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ---- Status banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.status.label,
                            style: TextStyle(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            applicationStatusMessage(a),
                            style: const TextStyle(color: kNavy, fontSize: 14),
                          ),
                          if (a.status == ApplicationStatus.rejected) ...[
                            const SizedBox(height: 10),
                            Text(
                              (a.rejectionReason ?? '').trim().isEmpty
                                  ? 'No reason was provided.'
                                  : 'Reason: ${a.rejectionReason}',
                              style: const TextStyle(
                                color: kNavy,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ---- Application info
                    _section('Application'),
                    _field('Date submitted', a.dateText),
                    _field('Pet owner', a.posterName),

                    // ---- What the user submitted
                    _section('Your Information'),
                    _field('Full name', a.fullName),
                    _field('Phone number', a.phone),
                    _field('Email address', a.email),
                    _field(
                      'Address',
                      a.street.trim().isEmpty
                          ? a.location
                          : '${a.street}, ${a.location}',
                    ),

                    _section('Living Environment'),
                    _field('Home environment', a.homeEnvironment),
                    _field('Household members', a.householdMembers),

                    _section('Pet Ownership Experience'),
                    _field('Previous or current pets', a.previousPets),
                    _field('Pet care experience', a.careExperience),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}